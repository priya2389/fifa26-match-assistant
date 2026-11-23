"""
Computes group standings (points / goal difference / goals for, with head-to-head
tiebreaks) from finished matches in FIFA_POSTGRES, then:
  - resolves GROUP_X_1 / GROUP_X_2 slots once a group's 6 matches are all finished
  - ranks the 12 third-place teams and reports the top 8 qualifiers

Does NOT assign the top-8 third-place teams to specific BEST_3RD_... slots.
That needs FIFA's official assignment procedure for which qualifying-group
combination maps to which bracket slot - the slot_codes already encode the
5-group candidate sets (e.g. BEST_3RD_A_B_C_D_F), but picking the actual
winner among those candidates isn't points/GD/GF math, it's a lookup table
this script doesn't have. Left as a manual/follow-up step.

Run manually:
    .venv/bin/python data_sync/resolve_group_stage.py
    .venv/bin/python data_sync/resolve_group_stage.py --dry-run
"""
import argparse
import os

import psycopg
from dotenv import load_dotenv

load_dotenv()

TOURNAMENT_NAME = "FIFA World Cup 2026"

DB = dict(
    host=os.getenv("FIFA_POSTGRES_HOST"),
    port=os.getenv("FIFA_POSTGRES_PORT"),
    dbname=os.getenv("FIFA_POSTGRES_DATABASE"),
    user=os.getenv("FIFA_POSTGRES_USER"),
    password=os.getenv("FIFA_POSTGRES_PASSWORD"),
)

MATCHES_PER_GROUP = 6


def get_tournament_id(cur):
    cur.execute("SELECT tournament_id FROM tournaments WHERE name = %s", (TOURNAMENT_NAME,))
    row = cur.fetchone()
    if not row:
        raise RuntimeError(f"tournament {TOURNAMENT_NAME!r} not found")
    return row[0]


def get_groups(cur, tournament_id):
    cur.execute(
        "SELECT group_id, group_code FROM tournament_groups WHERE tournament_id = %s ORDER BY sort_order",
        (tournament_id,),
    )
    return cur.fetchall()


def team_stats_for_group(cur, tournament_id, group_id):
    """One row per team in the group: slot_id, team_id, name, played/won/drawn/lost/gf/ga/pts."""
    cur.execute(
        """SELECT ge.slot_id, t.team_id, t.display_name
           FROM group_entries ge
           JOIN tournament_slots ts ON ts.slot_id = ge.slot_id
           JOIN teams t ON t.team_id = ts.team_id
           WHERE ge.group_id = %s
           ORDER BY ge.position_in_group""",
        (group_id,),
    )
    teams = {
        slot_id: {
            "slot_id": slot_id, "team_id": team_id, "name": name,
            "played": 0, "won": 0, "drawn": 0, "lost": 0, "gf": 0, "ga": 0, "pts": 0,
        }
        for slot_id, team_id, name in cur.fetchall()
    }

    cur.execute(
        """SELECT home_slot_id, away_slot_id, home_score, away_score
           FROM matches
           WHERE tournament_id = %s AND group_id = %s AND status = 'finished'""",
        (tournament_id, group_id),
    )
    finished = cur.fetchall()
    for home_slot, away_slot, hs, aws in finished:
        h, a = teams[home_slot], teams[away_slot]
        h["played"] += 1
        a["played"] += 1
        h["gf"] += hs
        h["ga"] += aws
        a["gf"] += aws
        a["ga"] += hs
        if hs > aws:
            h["won"] += 1
            h["pts"] += 3
            a["lost"] += 1
        elif hs < aws:
            a["won"] += 1
            a["pts"] += 3
            h["lost"] += 1
        else:
            h["drawn"] += 1
            a["drawn"] += 1
            h["pts"] += 1
            a["pts"] += 1
    for t in teams.values():
        t["gd"] = t["gf"] - t["ga"]
    return list(teams.values()), len(finished)


def head_to_head(cur, tournament_id, group_id, team_ids):
    """Mini points/gd/gf table using only matches among the given (tied) teams."""
    cur.execute(
        """SELECT hs.team_id, aws.team_id, m.home_score, m.away_score
           FROM matches m
           JOIN tournament_slots hs ON hs.slot_id = m.home_slot_id
           JOIN tournament_slots aws ON aws.slot_id = m.away_slot_id
           WHERE m.tournament_id = %s AND m.group_id = %s AND m.status = 'finished'
             AND hs.team_id = ANY(%s) AND aws.team_id = ANY(%s)""",
        (tournament_id, group_id, team_ids, team_ids),
    )
    h2h = {tid: {"pts": 0, "gd": 0, "gf": 0} for tid in team_ids}
    for home_id, away_id, hs, aws in cur.fetchall():
        h2h[home_id]["gf"] += hs
        h2h[home_id]["gd"] += hs - aws
        h2h[away_id]["gf"] += aws
        h2h[away_id]["gd"] += aws - hs
        if hs > aws:
            h2h[home_id]["pts"] += 3
        elif hs < aws:
            h2h[away_id]["pts"] += 3
        else:
            h2h[home_id]["pts"] += 1
            h2h[away_id]["pts"] += 1
    return h2h


def rank_group(cur, tournament_id, group_id, teams):
    """Points -> GD -> GF, with head-to-head used to break exact 3-way ties. Returns
    (ranked_list, unresolved) where unresolved lists team names still tied after h2h
    (would need disciplinary points / drawing of lots - no data for that here)."""
    teams = sorted(teams, key=lambda t: (t["pts"], t["gd"], t["gf"]), reverse=True)

    unresolved = []
    i = 0
    while i < len(teams):
        j = i
        while j + 1 < len(teams) and (teams[j + 1]["pts"], teams[j + 1]["gd"], teams[j + 1]["gf"]) == (
            teams[i]["pts"], teams[i]["gd"], teams[i]["gf"]
        ):
            j += 1
        if j > i:  # teams[i..j] are tied on points/gd/gf
            tied_ids = [t["team_id"] for t in teams[i : j + 1]]
            h2h = head_to_head(cur, tournament_id, group_id, tied_ids)
            block = sorted(teams[i : j + 1], key=lambda t: (h2h[t["team_id"]]["pts"], h2h[t["team_id"]]["gd"], h2h[t["team_id"]]["gf"]), reverse=True)
            # if h2h still leaves a tie, we can't resolve it (no disciplinary data)
            keys = [(h2h[t["team_id"]]["pts"], h2h[t["team_id"]]["gd"], h2h[t["team_id"]]["gf"]) for t in block]
            if len(set(keys)) < len(keys):
                unresolved.append([t["name"] for t in block])
            teams[i : j + 1] = block
        i = j + 1
    return teams, unresolved


def resolve():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    tag = "[DRY RUN] " if args.dry_run else ""

    with psycopg.connect(**DB) as conn:
        with conn.cursor() as cur:
            tournament_id = get_tournament_id(cur)
            groups = get_groups(cur, tournament_id)

            third_place_pool = []  # (group_code, team dict) for groups fully finished

            for group_id, group_code in groups:
                teams, played = team_stats_for_group(cur, tournament_id, group_id)
                ranked, unresolved = rank_group(cur, tournament_id, group_id, teams)

                print(f"{tag}Group {group_code} ({played}/{MATCHES_PER_GROUP} played):")
                for pos, t in enumerate(ranked, start=1):
                    print(f"  {pos}. {t['name']:<20} pts={t['pts']} gd={t['gd']:+d} gf={t['gf']}")
                for block in unresolved:
                    print(f"  WARNING: unresolved tie (no disciplinary data) among {block}")

                if played < MATCHES_PER_GROUP:
                    continue  # group not finished - don't lock in 1st/2nd yet

                for pos, slot_code in ((1, f"GROUP_{group_code}_1"), (2, f"GROUP_{group_code}_2")):
                    team = ranked[pos - 1]
                    cur.execute(
                        """UPDATE tournament_slots SET team_id = %s, updated_at = now()
                           WHERE tournament_id = %s AND slot_code = %s""",
                        (team["team_id"], tournament_id, slot_code),
                    )
                    print(f"{tag}  -> {slot_code} = {team['name']}")

                third_place_pool.append((group_code, ranked[2]))

            if len(third_place_pool) == len(groups):
                print(f"\n{tag}All groups finished - ranking third-place teams:")
                ranked_thirds = sorted(third_place_pool, key=lambda gt: (gt[1]["pts"], gt[1]["gd"], gt[1]["gf"]), reverse=True)
                for pos, (gcode, t) in enumerate(ranked_thirds, start=1):
                    qualifies = " (QUALIFIES)" if pos <= 8 else ""
                    print(f"  {pos}. Group {gcode}: {t['name']:<20} pts={t['pts']} gd={t['gd']:+d} gf={t['gf']}{qualifies}")
                print(
                    f"{tag}NOT resolving BEST_3RD_* slots automatically - needs FIFA's official "
                    f"group-combination -> slot lookup table, not implemented here."
                )
            else:
                print(f"\n{tag}{len(third_place_pool)}/{len(groups)} groups finished - too early to rank third-place teams.")

            if args.dry_run:
                conn.rollback()
            else:
                conn.commit()


if __name__ == "__main__":
    resolve()
