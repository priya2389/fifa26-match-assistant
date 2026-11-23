"""
Pulls the daily World Cup 2026 results file from openfootball/worldcup.json and
upserts scores/status into FIFA_POSTGRES, then propagates knockout-stage winners
into tournament_slots so the next round's matchups resolve.

Matches are identified by team identity (normalized through TEAM_ALIASES), not by
array position - a positional assumption was tried first and turned out wrong for
most matches (verified: 68/72 group-stage matches misaligned when checked against
the DB's own slot->team assignment, which is seeded independently of this script).

A match only gets picked up here once both its teams are resolved in our DB
(group-stage teams always are; knockout teams resolve as earlier rounds/standings
are computed) - so this needs re-running after resolve_group_stage.py to pick up
newly-resolved rounds.

Does NOT resolve group-stage-derived slots (GROUP_A_2, BEST_3RD_..., etc) -
that needs group-standings + tiebreaker logic, which is separate.

Run manually for now:
    .venv/bin/python data_sync/update_scores.py
    .venv/bin/python data_sync/update_scores.py --dry-run   # runs the same queries, rolls back instead of committing
"""
import argparse
import json
import os

import psycopg
import requests
from dotenv import load_dotenv

load_dotenv()

#getting source URL that contains the match data in json (outsourced, updated by openfootball)
SOURCE_URL = "https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json"
SOURCE_NAME = "openfootball-worldcup-json"
TOURNAMENT_NAME = "FIFA World Cup 2026"

#openfootball's team names that don't exactly match our teams.display_name -
#confirmed by diffing the full name sets; anything not listed here matched exactly.
#(the JSON's W89/L101/etc placeholders for unresolved future rounds are expected
#to never match here - that's correct, not a gap.)
TEAM_ALIASES = {
    "Bosnia & Herzegovina": "Bosnia-Herzegovina",
    "Curaçao": "Curacao",
    "Czech Republic": "Czechia",
    "DR Congo": "Congo DR",
    "Turkey": "Turkiye",
    "USA": "United States",
}


def normalize_team(name):
    return TEAM_ALIASES.get(name, name)


#finds the db match whose two resolved teams equal {team1, team2} (order-independent),
#returning which side team1 landed on so scores get assigned to the right column
def find_match(cur, tournament_id, team1, team2):
    t1, t2 = normalize_team(team1), normalize_team(team2)
    cur.execute(
        """SELECT m.match_id, m.match_number, m.home_slot_id, m.away_slot_id, m.status,
                  ht.display_name = %s AS team1_is_home
           FROM matches m
           JOIN tournament_slots hs ON hs.slot_id = m.home_slot_id
           JOIN teams ht ON ht.team_id = hs.team_id
           JOIN tournament_slots aws ON aws.slot_id = m.away_slot_id
           JOIN teams at ON at.team_id = aws.team_id
           WHERE m.tournament_id = %s
             AND ((ht.display_name = %s AND at.display_name = %s)
               OR (ht.display_name = %s AND at.display_name = %s))""",
        (t1, tournament_id, t1, t2, t2, t1),
    )
    rows = cur.fetchall()
    if len(rows) != 1:
        return None, len(rows)
    return rows[0], 1


#fallback for a match that's ALREADY BEEN PLAYED where one side is a slot we haven't
#resolved yet (e.g. a BEST_3RD_* slot) - since the match already happened, the real
#opponent is an observed fact, not something we need FIFA's selection algorithm to
#predict. Finds the db match by (one known team + kickoff date) and retroactively
#resolves the other slot's team_id from the JSON's other team name.
#Only ever call this for matches with a real score - never for future fixtures.
def find_and_resolve_partial_match(cur, tournament_id, team1, team2, match_date):
    t1, t2 = normalize_team(team1), normalize_team(team2)
    cur.execute("SELECT team_id FROM teams WHERE display_name = %s", (t1,))
    t1_row = cur.fetchone()
    cur.execute("SELECT team_id FROM teams WHERE display_name = %s", (t2,))
    t2_row = cur.fetchone()
    if not t1_row or not t2_row:
        return None, 0  # not both real recognized team names - nothing we can do
    t1_id, t2_id = t1_row[0], t2_row[0]

    cur.execute(
        """SELECT m.match_id, m.match_number, m.home_slot_id, m.away_slot_id, m.status,
                  hs.team_id AS home_team_id, aws.team_id AS away_team_id
           FROM matches m
           JOIN tournament_slots hs ON hs.slot_id = m.home_slot_id
           JOIN tournament_slots aws ON aws.slot_id = m.away_slot_id
           WHERE m.tournament_id = %s AND m.kickoff_at::date = %s
             AND ((hs.team_id IN (%s, %s) AND aws.team_id IS NULL)
               OR (aws.team_id IN (%s, %s) AND hs.team_id IS NULL))""",
        (tournament_id, match_date, t1_id, t2_id, t1_id, t2_id),
    )
    rows = cur.fetchall()
    if len(rows) != 1:
        return None, len(rows)
    match_id, match_number, home_slot_id, away_slot_id, status, home_team_id, away_team_id = rows[0]

    if home_team_id is None:
        unresolved_slot_id = home_slot_id
        resolved_team_id = away_team_id
        team1_is_home = t1_id != resolved_team_id
    else:
        unresolved_slot_id = away_slot_id
        resolved_team_id = home_team_id
        team1_is_home = t1_id == resolved_team_id

    missing_team_id = t2_id if resolved_team_id == t1_id else t1_id
    cur.execute(
        """UPDATE tournament_slots SET team_id = %s, updated_at = now()
           WHERE slot_id = %s RETURNING slot_code""",
        (missing_team_id, unresolved_slot_id),
    )
    resolved_slot_code = cur.fetchone()[0]
    print(f"  -> observed result resolves slot {resolved_slot_code} = {t1 if missing_team_id == t1_id else t2}")

    return (match_id, match_number, home_slot_id, away_slot_id, status, team1_is_home), 1


#connecting to database
DB = dict(
    host=os.getenv("FIFA_POSTGRES_HOST"),
    port=os.getenv("FIFA_POSTGRES_PORT"),
    dbname=os.getenv("FIFA_POSTGRES_DATABASE"),
    user=os.getenv("FIFA_POSTGRES_USER"),
    password=os.getenv("FIFA_POSTGRES_PASSWORD"),
)

#getting all matches 
def fetch_matches():
    resp = requests.get(SOURCE_URL, timeout=20)
    resp.raise_for_status()
    return resp.json()["matches"]

#getting the final results includes goals, pentalies and method of decision
def final_result(score):
    """openfootball scores carry ft (full time) and, for knockouts, et/p on top.
    The most advanced key present is the one that actually decided the match."""
    if not score:
        return None
    goals = score.get("et") or score.get("ft")
    if not goals:
        return None
    penalties = score.get("p")
    method = "penalties" if penalties else ("extra_time" if "et" in score else "regulation")
    return {"goals": goals, "penalties": penalties, "method": method}

#getting tournament id's from the databse
def get_tournament_id(cur):
    cur.execute("SELECT tournament_id FROM tournaments WHERE name = %s", (TOURNAMENT_NAME,))
    row = cur.fetchone()
    if not row:
        raise RuntimeError(f"tournament {TOURNAMENT_NAME!r} not found")
    return row[0]

#helper method to get or create the source in the database, returning its source_id
def get_or_create_source(cur):
    cur.execute("SELECT source_id FROM external_sources WHERE source_name = %s", (SOURCE_NAME,))
    row = cur.fetchone()
    if row:
        return row[0]
    cur.execute(
        """INSERT INTO external_sources (source_name, base_url, priority, is_canonical)
           VALUES (%s, %s, %s, %s) RETURNING source_id""",
        (SOURCE_NAME, SOURCE_URL, 10, False),
    )
    return cur.fetchone()[0]

#actually updates and syncs data, recieves, computes and propgates out as needed
def sync(dry_run=False):
    matches = fetch_matches()
    tag = "[DRY RUN] " if dry_run else ""

    with psycopg.connect(**DB) as conn:
        with conn.cursor() as cur:
            tournament_id = get_tournament_id(cur)
            source_id = get_or_create_source(cur)
            updated, skipped_unplayed, unresolved, ambiguous = 0, 0, 0, 0

            for m in matches:
                team1, team2 = m.get("team1"), m.get("team2")
                match_row, n_found = find_match(cur, tournament_id, team1, team2)
                if n_found == 0 and final_result(m.get("score")) is not None:
                    # already played - the real opponent is an observed fact, not a
                    # prediction, so resolve the still-open slot from this result
                    match_row, n_found = find_and_resolve_partial_match(
                        cur, tournament_id, team1, team2, m.get("date")
                    )
                if n_found == 0:
                    unresolved += 1  # one or both teams not resolved in our db yet - not an error
                    continue
                if n_found > 1:
                    ambiguous += 1
                    print(f"WARNING: {team1} vs {team2} matched {n_found} db rows, skipping (needs manual look)")
                    continue
                match_id, match_number, home_slot_id, away_slot_id, current_status, team1_is_home = match_row

                cur.execute(
                    """INSERT INTO source_records
                         (source_id, entity_type, entity_id, external_id, source_url, raw_payload, first_seen_at, last_seen_at)
                       VALUES (%s, 'match', %s, %s, %s, %s, now(), now())
                       ON CONFLICT (source_id, entity_type, external_id)
                       DO UPDATE SET raw_payload = EXCLUDED.raw_payload, last_seen_at = now()""",
                    (source_id, match_id, f"wc2026-match-{match_number}", SOURCE_URL, json.dumps(m)),
                )

                result = final_result(m.get("score"))
                if result is None:
                    skipped_unplayed += 1
                    continue

                team1_goals, team2_goals = result["goals"]
                team1_pens, team2_pens = result["penalties"] if result["penalties"] else (None, None)
                if team1_is_home:
                    home_goals, away_goals, home_pens, away_pens = team1_goals, team2_goals, team1_pens, team2_pens
                else:
                    home_goals, away_goals, home_pens, away_pens = team2_goals, team1_goals, team2_pens, team1_pens

                cur.execute(
                    """UPDATE matches
                       SET home_score = %s, away_score = %s,
                           home_penalties = %s, away_penalties = %s,
                           status = 'finished', decision_method = %s, updated_at = now()
                       WHERE match_id = %s""",
                    (home_goals, away_goals, home_pens, away_pens, result["method"], match_id),
                )
                updated += 1
                if current_status != "finished":
                    print(
                        f"{tag}match {match_number}: {team1} {team1_goals}-{team2_goals} "
                        f"{team2} ({result['method']}) -> status was {current_status!r}"
                    )

                # propagate the winner to whatever slot names this match as its source
                # (Round of 16 onward - e.g. slot 'W74' waits on match_number 74)
                if home_goals == away_goals and not result["penalties"]:
                    continue  # group-stage draw, nothing to propagate

                home_wins = (
                    (home_pens or 0) > (away_pens or 0) if result["penalties"] else home_goals > away_goals
                )
                winner_slot_id = home_slot_id if home_wins else away_slot_id

                cur.execute(
                    "SELECT team_id FROM tournament_slots WHERE slot_id = %s", (winner_slot_id,)
                )
                winner_team_row = cur.fetchone()
                if not winner_team_row or not winner_team_row[0]:
                    continue  # winner's own slot isn't resolved to a team yet either
                winner_team_id = winner_team_row[0]

                cur.execute("UPDATE matches SET winner_slot_id = %s WHERE match_id = %s", (winner_slot_id, match_id))
                cur.execute(
                    """UPDATE tournament_slots SET team_id = %s, updated_at = now()
                       WHERE tournament_id = %s AND source_match_number = %s
                       RETURNING slot_code""",
                    (winner_team_id, tournament_id, match_number),
                )
                resolved = cur.fetchone()
                if resolved:
                    print(f"{tag}  -> resolves slot {resolved[0]} (fed by match {match_number})")

            if dry_run:
                conn.rollback()
            else:
                conn.commit()

    print(
        f"{tag}Synced {len(matches)} matches: {updated} updated, {skipped_unplayed} not yet played, "
        f"{unresolved} not yet resolvable in our db, {ambiguous} ambiguous"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="run all queries but roll back instead of committing")
    args = parser.parse_args()
    sync(dry_run=args.dry_run)
