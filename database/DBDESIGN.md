# FIFA 2026 PostgreSQL Database Design

This document reviews and expands the starter schema for a FIFA World Cup 2026 schedule database. The goal is to support:

- Reliable scraping/API ingestion from FIFA and other sources.
- Q/A features around teams, players, squads, groups, venues, matches, standings, and knockout paths.
- Incremental updates as match times, teams, scores, and sources change.

## Design Summary

The Google AI schema is a useful starting point, but it is too flat for a World Cup application. A production-friendly schema should separate:

- The tournament itself from reusable country/team/venue data.
- Group-stage positions and knockout placeholders from actual teams.
- Match schedule data from ingestion/audit metadata.
- Canonical app data from source-specific external IDs.

Recommended MVP scope:

- `tournaments`
- `confederations`
- `countries`
- `teams`
- `venues`
- `stages`
- `tournament_groups`
- `tournament_slots`
- `group_entries`
- `matches`
- `match_broadcasts`
- `external_sources`
- `source_records`
- `players`
- `squad_memberships`
- Q/A-friendly views for schedule, team schedule, and group standings.

Optional later scope:

- Referees.
- Match events.
- Team news/injuries.
- Odds.
- Tickets.
- Articles/transcripts/embeddings for richer natural-language Q/A.

## Current Tournament Assumptions

As of June 11, 2026, this design assumes FIFA World Cup 2026 uses:

- 48 teams.
- 12 groups of 4 teams, Groups A through L.
- 104 total matches.
- Top 2 teams from each group plus the 8 best third-place teams advance.
- Knockout rounds: Round of 32, Round of 16, Quarterfinals, Semifinals, Third-place match, Final.
- Hosted across Canada, Mexico, and the United States.

Primary data should eventually come from official FIFA schedule/team/venue endpoints or pages. Third-party sources can be used for validation, but should not be treated as canonical unless FIFA data is unavailable.

Reference links for validating these assumptions:

- FIFA tournament page: https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026
- FIFA World Cup 2026 public summary: https://en.wikipedia.org/wiki/2026_FIFA_World_Cup
- Format confirmation summary: https://www.theguardian.com/football/2023/mar/14/world-cup-2026-four-team-groups-104-game-tournament-approval-fifa
- ESPN World Cup page: https://www.espn.com/soccer/worldcup/
- ESPN schedule page: https://www.espn.com/soccer/schedule/_/league/fifa.world
- ESPN teams page: https://www.espn.com/soccer/teams/_/league/fifa.world

## Key Modeling Choices

### 1. Use `tournament_slots` Instead of Direct Team IDs on Matches

World Cup schedules often contain placeholders:

- `A1`
- `A2`
- `Winner Group A`
- `Runner-up Group B`
- `Winner Match 97`
- `Best third-place team from Groups C/D/E/F`

If `matches` only has `home_team_id` and `away_team_id`, the schema breaks down before all teams are known or before knockout participants are resolved.

Instead, each match points to `home_slot_id` and `away_slot_id`. A slot can later resolve to an actual `team_id`.

### 2. Store Match Times as `timestamptz`

The 2026 tournament spans several time zones. Store kickoff times as `TIMESTAMPTZ`, and keep each venue's IANA timezone, such as `America/New_York`, `America/Los_Angeles`, or `America/Mexico_City`, for local display.

### 3. Keep External Source IDs

Scrapers and APIs will need stable upserts. Each major entity should be linkable to the source record that created or updated it.

Use `source_records` to map local rows to source identifiers without polluting every table with several source-specific columns.

### 4. Keep Results on `matches` for MVP

For the app's first version, match-level scores are enough for schedule Q/A and standings. Detailed goals/cards/substitutions can be added later through `match_events`.

### 5. Store Broadcasts Separately

ESPN's schedule page includes TV/streaming carriers such as FOX, FS1, Peacock, and Spanish-language coverage. Keep this data in `match_broadcasts` instead of denormalizing a comma-separated `tv` field onto `matches`.

This makes questions like "What channel is Mexico vs South Africa on?" easy without making the core match table source-specific.

## Recommended DDL

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE match_status AS ENUM (
    'scheduled',
    'postponed',
    'cancelled',
    'in_play',
    'halftime',
    'extra_time',
    'penalties',
    'finished',
    'abandoned'
);

CREATE TYPE stage_type AS ENUM (
    'group',
    'knockout'
);

CREATE TYPE slot_type AS ENUM (
    'group_position',
    'team',
    'draw_placeholder',
    'group_rank',
    'best_third',
    'match_winner',
    'match_loser'
);

CREATE TYPE match_decision_method AS ENUM (
    'regulation',
    'extra_time',
    'penalties',
    'forfeit',
    'walkover'
);

CREATE TABLE tournaments (
    tournament_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    season_year INTEGER NOT NULL,
    fifa_competition_id TEXT,
    start_date DATE,
    end_date DATE,
    host_countries TEXT[] NOT NULL DEFAULT '{}',
    format_summary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT tournaments_name_year_unique UNIQUE (name, season_year),
    CONSTRAINT tournaments_dates_valid CHECK (
        start_date IS NULL OR end_date IS NULL OR start_date <= end_date
    )
);

CREATE TABLE confederations (
    confederation_code TEXT PRIMARY KEY,
    confederation_name TEXT NOT NULL
);

CREATE TABLE countries (
    country_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fifa_code CHAR(3) NOT NULL UNIQUE,
    iso2_code CHAR(2),
    iso3_code CHAR(3),
    country_name TEXT NOT NULL,
    confederation_code TEXT REFERENCES confederations(confederation_code),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teams (
    team_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_id BIGINT NOT NULL REFERENCES countries(country_id) ON DELETE RESTRICT,
    display_name TEXT NOT NULL,
    short_name TEXT,
    fifa_team_id TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT teams_country_unique UNIQUE (country_id)
);

CREATE TABLE venues (
    venue_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venue_name TEXT NOT NULL,
    city TEXT NOT NULL,
    region TEXT,
    country_code CHAR(3) NOT NULL REFERENCES countries(fifa_code) ON DELETE RESTRICT,
    timezone TEXT NOT NULL,
    capacity INTEGER,
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),
    fifa_venue_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT venues_capacity_positive CHECK (capacity IS NULL OR capacity > 0),
    CONSTRAINT venues_latitude_valid CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT venues_longitude_valid CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);

CREATE TABLE stages (
    stage_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    stage_code TEXT NOT NULL,
    stage_name TEXT NOT NULL,
    stage_type stage_type NOT NULL,
    sort_order INTEGER NOT NULL,

    CONSTRAINT stages_tournament_code_unique UNIQUE (tournament_id, stage_code),
    CONSTRAINT stages_sort_unique UNIQUE (tournament_id, sort_order)
);

CREATE TABLE tournament_groups (
    group_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    group_code CHAR(1) NOT NULL,
    group_name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,

    CONSTRAINT tournament_groups_code_valid CHECK (group_code BETWEEN 'A' AND 'L'),
    CONSTRAINT tournament_groups_tournament_code_unique UNIQUE (tournament_id, group_code),
    CONSTRAINT tournament_groups_tournament_sort_unique UNIQUE (tournament_id, sort_order)
);

CREATE TABLE tournament_slots (
    slot_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    slot_code TEXT NOT NULL,
    slot_name TEXT NOT NULL,
    slot_type slot_type NOT NULL,
    team_id BIGINT REFERENCES teams(team_id) ON DELETE RESTRICT,
    group_id BIGINT REFERENCES tournament_groups(group_id) ON DELETE SET NULL,
    group_rank INTEGER,
    source_match_number INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT tournament_slots_code_unique UNIQUE (tournament_id, slot_code),
    CONSTRAINT tournament_slots_group_rank_valid CHECK (
        group_rank IS NULL OR group_rank BETWEEN 1 AND 4
    )
);

CREATE TABLE group_entries (
    group_entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    group_id BIGINT NOT NULL REFERENCES tournament_groups(group_id) ON DELETE CASCADE,
    slot_id BIGINT NOT NULL REFERENCES tournament_slots(slot_id) ON DELETE CASCADE,
    position_in_group INTEGER NOT NULL,
    draw_pot INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT group_entries_position_valid CHECK (position_in_group BETWEEN 1 AND 4),
    CONSTRAINT group_entries_draw_pot_valid CHECK (draw_pot IS NULL OR draw_pot BETWEEN 1 AND 4),
    CONSTRAINT group_entries_group_position_unique UNIQUE (group_id, position_in_group),
    CONSTRAINT group_entries_slot_unique UNIQUE (slot_id)
);

CREATE TABLE matches (
    match_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    match_number INTEGER NOT NULL,
    stage_id BIGINT NOT NULL REFERENCES stages(stage_id) ON DELETE RESTRICT,
    group_id BIGINT REFERENCES tournament_groups(group_id) ON DELETE SET NULL,
    venue_id BIGINT REFERENCES venues(venue_id) ON DELETE RESTRICT,
    kickoff_at TIMESTAMPTZ,
    status match_status NOT NULL DEFAULT 'scheduled',
    home_slot_id BIGINT NOT NULL REFERENCES tournament_slots(slot_id) ON DELETE RESTRICT,
    away_slot_id BIGINT NOT NULL REFERENCES tournament_slots(slot_id) ON DELETE RESTRICT,
    home_score INTEGER,
    away_score INTEGER,
    home_penalties INTEGER,
    away_penalties INTEGER,
    winner_slot_id BIGINT REFERENCES tournament_slots(slot_id) ON DELETE RESTRICT,
    decision_method match_decision_method,
    attendance INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT matches_number_unique UNIQUE (tournament_id, match_number),
    CONSTRAINT matches_teams_different CHECK (home_slot_id <> away_slot_id),
    CONSTRAINT matches_scores_nonnegative CHECK (
        (home_score IS NULL OR home_score >= 0) AND
        (away_score IS NULL OR away_score >= 0) AND
        (home_penalties IS NULL OR home_penalties >= 0) AND
        (away_penalties IS NULL OR away_penalties >= 0)
    ),
    CONSTRAINT matches_attendance_nonnegative CHECK (attendance IS NULL OR attendance >= 0)
);

CREATE TABLE external_sources (
    source_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_name TEXT NOT NULL UNIQUE,
    base_url TEXT,
    priority INTEGER NOT NULL DEFAULT 100,
    is_canonical BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE match_broadcasts (
    match_broadcast_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id BIGINT NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    market_country_code CHAR(3) REFERENCES countries(fifa_code) ON DELETE RESTRICT,
    language_code TEXT,
    broadcaster_name TEXT NOT NULL,
    broadcast_type TEXT,
    source_id BIGINT REFERENCES external_sources(source_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT match_broadcasts_unique UNIQUE (
        match_id,
        market_country_code,
        language_code,
        broadcaster_name,
        broadcast_type
    )
);

CREATE TABLE source_records (
    source_record_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_id BIGINT NOT NULL REFERENCES external_sources(source_id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL,
    entity_id BIGINT NOT NULL,
    external_id TEXT NOT NULL,
    source_url TEXT,
    raw_payload JSONB,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT source_records_unique UNIQUE (source_id, entity_type, external_id)
);
```

## Recommended Indexes

```sql
CREATE INDEX idx_countries_confederation ON countries(confederation_code);
CREATE INDEX idx_teams_fifa_team_id ON teams(fifa_team_id);
CREATE INDEX idx_venues_country_city ON venues(country_code, city);
CREATE INDEX idx_matches_kickoff_at ON matches(kickoff_at);
CREATE INDEX idx_matches_stage ON matches(stage_id);
CREATE INDEX idx_matches_group ON matches(group_id);
CREATE INDEX idx_matches_venue ON matches(venue_id);
CREATE INDEX idx_matches_home_slot ON matches(home_slot_id);
CREATE INDEX idx_matches_away_slot ON matches(away_slot_id);
CREATE INDEX idx_match_broadcasts_match ON match_broadcasts(match_id);
CREATE INDEX idx_match_broadcasts_broadcaster ON match_broadcasts(broadcaster_name);
CREATE INDEX idx_tournament_slots_team ON tournament_slots(team_id);
CREATE INDEX idx_source_records_entity ON source_records(entity_type, entity_id);
CREATE INDEX idx_source_records_raw_payload_gin ON source_records USING GIN (raw_payload);
```

## Seed Data Skeleton

```sql
INSERT INTO confederations (confederation_code, confederation_name) VALUES
('AFC', 'Asian Football Confederation'),
('CAF', 'Confederation of African Football'),
('CONCACAF', 'Confederation of North, Central America and Caribbean Association Football'),
('CONMEBOL', 'South American Football Confederation'),
('OFC', 'Oceania Football Confederation'),
('UEFA', 'Union of European Football Associations')
ON CONFLICT (confederation_code) DO NOTHING;

INSERT INTO external_sources (source_name, base_url, priority, is_canonical) VALUES
('FIFA', 'https://www.fifa.com', 10, true),
('ESPN', 'https://www.espn.com', 30, false)
ON CONFLICT (source_name) DO NOTHING;

INSERT INTO tournaments (
    name,
    season_year,
    fifa_competition_id,
    start_date,
    end_date,
    host_countries,
    format_summary
) VALUES (
    'FIFA World Cup 2026',
    2026,
    NULL,
    '2026-06-11',
    '2026-07-19',
    ARRAY['Canada', 'Mexico', 'United States'],
    '48 teams, 12 groups of 4, top 2 plus 8 best third-place teams advance, 104 matches.'
)
ON CONFLICT (name, season_year) DO NOTHING;

-- Stages should be inserted after the tournament row exists.
-- Group rows A-L and group-position slots A1-L4 should be generated by a migration/seed script.
```

## Q/A-Friendly Views

### Schedule View

This view resolves the label for each match participant. If a slot has an actual team, it shows the team; otherwise it shows the slot placeholder.

```sql
CREATE OR REPLACE VIEW v_match_schedule AS
SELECT
    m.match_id,
    m.match_number,
    t.name AS tournament_name,
    s.stage_code,
    s.stage_name,
    g.group_code,
    m.kickoff_at,
    m.kickoff_at AT TIME ZONE v.timezone AS venue_local_kickoff,
    v.timezone AS venue_timezone,
    v.venue_name,
    v.city,
    v.region,
    v.country_code AS venue_country_code,
    COALESCE(home_team.display_name, home_slot.slot_name) AS home_name,
    COALESCE(away_team.display_name, away_slot.slot_name) AS away_name,
    home_country.fifa_code AS home_fifa_code,
    away_country.fifa_code AS away_fifa_code,
    m.status,
    m.home_score,
    m.away_score,
    m.home_penalties,
    m.away_penalties,
    m.decision_method
FROM matches m
JOIN tournaments t ON t.tournament_id = m.tournament_id
JOIN stages s ON s.stage_id = m.stage_id
LEFT JOIN tournament_groups g ON g.group_id = m.group_id
LEFT JOIN venues v ON v.venue_id = m.venue_id
JOIN tournament_slots home_slot ON home_slot.slot_id = m.home_slot_id
JOIN tournament_slots away_slot ON away_slot.slot_id = m.away_slot_id
LEFT JOIN teams home_team ON home_team.team_id = home_slot.team_id
LEFT JOIN teams away_team ON away_team.team_id = away_slot.team_id
LEFT JOIN countries home_country ON home_country.country_id = home_team.country_id
LEFT JOIN countries away_country ON away_country.country_id = away_team.country_id;
```

### Team Schedule View

This makes questions like "When does USA play?" easy.

```sql
CREATE OR REPLACE VIEW v_team_schedule AS
SELECT
    m.match_id,
    m.match_number,
    team.team_id,
    team.display_name AS team_name,
    country.fifa_code,
    CASE
        WHEN home_slot.team_id = team.team_id THEN 'home'
        ELSE 'away'
    END AS side,
    COALESCE(opponent_team.display_name, opponent_slot.slot_name) AS opponent_name,
    m.kickoff_at,
    v.venue_name,
    v.city,
    v.country_code AS venue_country_code,
    s.stage_name,
    g.group_code,
    m.status,
    m.home_score,
    m.away_score
FROM matches m
JOIN stages s ON s.stage_id = m.stage_id
LEFT JOIN tournament_groups g ON g.group_id = m.group_id
LEFT JOIN venues v ON v.venue_id = m.venue_id
JOIN tournament_slots home_slot ON home_slot.slot_id = m.home_slot_id
JOIN tournament_slots away_slot ON away_slot.slot_id = m.away_slot_id
JOIN LATERAL (
    VALUES
        (home_slot.team_id, away_slot.slot_id),
        (away_slot.team_id, home_slot.slot_id)
) sides(team_id, opponent_slot_id) ON sides.team_id IS NOT NULL
JOIN teams team ON team.team_id = sides.team_id
JOIN countries country ON country.country_id = team.country_id
JOIN tournament_slots opponent_slot ON opponent_slot.slot_id = sides.opponent_slot_id
LEFT JOIN teams opponent_team ON opponent_team.team_id = opponent_slot.team_id;
```

### Group Standings View

This view calculates basic group standings from finished group matches.

```sql
CREATE OR REPLACE VIEW v_group_standings AS
WITH group_match_rows AS (
    SELECT
        m.group_id,
        home_slot.team_id,
        m.home_score AS goals_for,
        m.away_score AS goals_against,
        CASE
            WHEN m.home_score > m.away_score THEN 3
            WHEN m.home_score = m.away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN m.home_score > m.away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN m.home_score = m.away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN m.home_score < m.away_score THEN 1 ELSE 0 END AS losses
    FROM matches m
    JOIN stages s ON s.stage_id = m.stage_id
    JOIN tournament_slots home_slot ON home_slot.slot_id = m.home_slot_id
    WHERE s.stage_type = 'group'
      AND m.status = 'finished'
      AND m.home_score IS NOT NULL
      AND m.away_score IS NOT NULL
      AND home_slot.team_id IS NOT NULL

    UNION ALL

    SELECT
        m.group_id,
        away_slot.team_id,
        m.away_score AS goals_for,
        m.home_score AS goals_against,
        CASE
            WHEN m.away_score > m.home_score THEN 3
            WHEN m.away_score = m.home_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN m.away_score > m.home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN m.away_score = m.home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN m.away_score < m.home_score THEN 1 ELSE 0 END AS losses
    FROM matches m
    JOIN stages s ON s.stage_id = m.stage_id
    JOIN tournament_slots away_slot ON away_slot.slot_id = m.away_slot_id
    WHERE s.stage_type = 'group'
      AND m.status = 'finished'
      AND m.home_score IS NOT NULL
      AND m.away_score IS NOT NULL
      AND away_slot.team_id IS NOT NULL
),
team_totals AS (
    SELECT
        group_id,
        team_id,
        COUNT(*) AS played,
        SUM(wins) AS wins,
        SUM(draws) AS draws,
        SUM(losses) AS losses,
        SUM(goals_for) AS goals_for,
        SUM(goals_against) AS goals_against,
        SUM(goals_for - goals_against) AS goal_difference,
        SUM(points) AS points
    FROM group_match_rows
    GROUP BY group_id, team_id
)
SELECT
    g.group_code,
    ge.position_in_group,
    slot.slot_id,
    team.team_id,
    COALESCE(team.display_name, slot.slot_name) AS team_name,
    country.fifa_code,
    COALESCE(totals.played, 0) AS played,
    COALESCE(totals.wins, 0) AS wins,
    COALESCE(totals.draws, 0) AS draws,
    COALESCE(totals.losses, 0) AS losses,
    COALESCE(totals.goals_for, 0) AS goals_for,
    COALESCE(totals.goals_against, 0) AS goals_against,
    COALESCE(totals.goal_difference, 0) AS goal_difference,
    COALESCE(totals.points, 0) AS points
FROM group_entries ge
JOIN tournament_groups g ON g.group_id = ge.group_id
JOIN tournament_slots slot ON slot.slot_id = ge.slot_id
LEFT JOIN teams team ON team.team_id = slot.team_id
LEFT JOIN countries country ON country.country_id = team.country_id
LEFT JOIN team_totals totals
    ON totals.group_id = ge.group_id
   AND totals.team_id = slot.team_id;
```

Note: Official FIFA group ranking can require additional tie-breakers. The view above is good for basic standings, but a complete ranking implementation should add tie-break logic for head-to-head, fair play, and final ranking rules.

## Common Queries

### Full Schedule

```sql
SELECT *
FROM v_match_schedule
ORDER BY kickoff_at NULLS LAST, match_number;
```

### Team Schedule by FIFA Code

```sql
SELECT *
FROM v_team_schedule
WHERE fifa_code = 'USA'
ORDER BY kickoff_at NULLS LAST, match_number;
```

### Matches at a Venue

```sql
SELECT *
FROM v_match_schedule
WHERE venue_name ILIKE '%MetLife%'
ORDER BY kickoff_at NULLS LAST, match_number;
```

### Broadcasts for a Match

```sql
SELECT
    sched.match_number,
    sched.home_name,
    sched.away_name,
    broadcasts.market_country_code,
    broadcasts.language_code,
    broadcasts.broadcaster_name,
    broadcasts.broadcast_type
FROM v_match_schedule sched
JOIN match_broadcasts broadcasts ON broadcasts.match_id = sched.match_id
WHERE sched.match_number = 1
ORDER BY broadcasts.market_country_code, broadcasts.language_code, broadcasts.broadcaster_name;
```

### Group Table

```sql
SELECT *
FROM v_group_standings
WHERE group_code = 'A'
ORDER BY points DESC, goal_difference DESC, goals_for DESC, team_name;
```

## Ingestion Strategy

Use idempotent upserts for every scraper/API run.

Recommended flow:

1. Insert or update `external_sources`.
2. Upsert countries and teams.
3. Upsert venues.
4. Upsert tournament, stages, tournament groups, and slots.
5. Upsert matches by `(tournament_id, match_number)`.
6. Write source mappings to `source_records`.
7. Keep raw source payloads in `source_records.raw_payload` for debugging and reprocessing.

Recommended source priority:

1. FIFA official data.
2. Official broadcaster or confederation data.
3. Trusted sports data API.
4. Public pages used only for validation/backfill.

## ESPN Source Validation

ESPN is useful as a secondary validation and enrichment source, not the canonical source of truth when FIFA data is available.

What ESPN currently exposes on the checked pages:

- `https://www.espn.com/soccer/schedule/_/league/fifa.world` lists match date, teams, kickoff time, TV/streaming carrier, venue, city/region/country, ticket links, and betting line snippets.
- Schedule match links include ESPN game IDs, for example `/soccer/match/_/gameId/760415/...`.
- `https://www.espn.com/soccer/teams/_/league/fifa.world` lists participating teams and links each team to ESPN team pages.
- Team links include ESPN team IDs, for example `/soccer/team/_/id/203/mexico` and `/soccer/team/_/id/624/algeria`.
- Team pages can expose fixtures, current record, group standings, team leaders, squad/stats links, and related news.

Schema validation against ESPN:

- Team names and ESPN team IDs are covered by `teams`, `countries`, and `source_records`.
- ESPN game IDs are covered by `matches` plus `source_records` with `entity_type = 'match'`.
- ESPN's `fifa.world` league code is covered by `source_records` for the `tournaments` row.
- ESPN schedule dates/times map to `matches.kickoff_at`; use the venue timezone or explicit source offset when normalizing.
- ESPN venue strings map to `venues`; use `source_records.raw_payload` to keep the original display string.
- ESPN TV/streaming data maps to `match_broadcasts`.
- ESPN odds and ticket links should be treated as optional enrichment, not part of the core schedule schema.

Suggested ESPN source record examples:

```sql
-- Tournament mapping:
-- source_name='ESPN', entity_type='tournament', external_id='fifa.world'

-- Team mapping:
-- source_name='ESPN', entity_type='team', external_id='203' for Mexico
-- source_name='ESPN', entity_type='team', external_id='624' for Algeria

-- Match mapping:
-- source_name='ESPN', entity_type='match', external_id='760415'
```

Suggested ESPN parser behavior:

1. Parse team IDs and slugs from ESPN team URLs.
2. Parse game IDs from ESPN match URLs.
3. Upsert teams by source mapping first, then by normalized team name only as a fallback.
4. Upsert matches by ESPN `gameId` into `source_records`, then reconcile to FIFA `match_number` when available.
5. Split TV/streaming values into one row per carrier in `match_broadcasts`.
6. Store ticket URLs, odds snippets, and full source rows in `source_records.raw_payload` until those features become product requirements.

## Scraper/API Upsert Notes

### Teams

Use `countries.fifa_code` as the primary human-readable key. Store source-specific team IDs in `source_records`.

For teams that are placeholders at scrape time, create a `tournament_slots` row without a `team_id`. When the team becomes known, update the slot's `team_id`.

### Matches

Upsert matches by:

```sql
(tournament_id, match_number)
```

Do not rely on team names, because knockout matches and unresolved placeholders can change.

### Venues

Upsert venues by FIFA source ID when available. If unavailable, use a normalized combination of:

```sql
venue_name, city, country_code
```

### Time Zones

Store:

- `matches.kickoff_at` as absolute `TIMESTAMPTZ`.
- `venues.timezone` as the venue's local IANA timezone.

Avoid storing kickoff strings without offsets.

## Future Tables

These are not required for the first schedule/squad database, but are likely useful later.

```sql
CREATE TABLE match_events (
    match_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id BIGINT NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    team_id BIGINT REFERENCES teams(team_id) ON DELETE SET NULL,
    player_id BIGINT REFERENCES players(player_id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    minute INTEGER,
    stoppage_minute INTEGER,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE odds_snapshots (
    odds_snapshot_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id BIGINT NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    source_id BIGINT REFERENCES external_sources(source_id) ON DELETE SET NULL,
    sportsbook_name TEXT,
    market_type TEXT NOT NULL,
    selection_name TEXT,
    odds_american INTEGER,
    odds_decimal NUMERIC(10, 4),
    line_value NUMERIC(10, 2),
    captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    raw_payload JSONB
);

CREATE TABLE ticket_links (
    ticket_link_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id BIGINT REFERENCES matches(match_id) ON DELETE CASCADE,
    team_id BIGINT REFERENCES teams(team_id) ON DELETE CASCADE,
    source_id BIGINT REFERENCES external_sources(source_id) ON DELETE SET NULL,
    provider_name TEXT NOT NULL,
    ticket_url TEXT NOT NULL,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ticket_links_target_present CHECK (match_id IS NOT NULL OR team_id IS NOT NULL)
);
```

## Review of Original Google AI Schema

What is good:

- Separates teams, venues, and matches.
- Uses `TIMESTAMP WITH TIME ZONE`.
- Adds basic indexes for team and date lookups.
- Includes scores and penalty fields.

What should change:

- Add `tournaments`, because the app may later support other World Cups or historical comparison.
- Add `stages` and `tournament_groups`, instead of storing all stages and groups as loose strings.
- Add `tournament_slots`, because schedules contain placeholders and knockout paths.
- Add external source mapping for scraper/API upserts.
- Add venue timezones for clean local display.
- Add `players` and `squad_memberships` for player-name, role, and jersey-number Q/A.
- Prefer `GENERATED ALWAYS AS IDENTITY` over `SERIAL` for modern PostgreSQL.
- Add stricter status values via enums.
- Add Q/A-oriented views so app queries stay clean.

## Open Decisions Before Implementation

- Should the app track only FIFA World Cup 2026, or should the schema be multi-tournament from day one? This design supports multi-tournament with minimal extra effort.
- Should the first population script ingest only official schedule data, or also teams, groups, venues, and results?
- Do we want detailed tie-breaker correctness in SQL, or should the app layer handle official group ranking after basic points/goal difference?
- Will the app use semantic search over articles/pages? If yes, add `documents`, `document_chunks`, and embeddings later rather than mixing that into the schedule schema.

## Suggested Next Step

Implementation files created from this design:

- `ddl/001_schema.sql` creates the PostgreSQL schema, indexes, triggers, and Q/A views.
- `ddl/002_players_squads.sql` adds team display enrichment fields, player search support, squad memberships, and `v_squad_players`.
- `dml/001_seed_core.sql` seeds confederations, sources, countries, teams, tournament metadata, stages, Groups A-L, group slots, venues, the first 24 ESPN-listed group-stage matches, and USA broadcast rows.
- `dml/002_seed_full_schedule.sql` upserts the complete 104-match official schedule, corrects early match numbers from the initial ESPN chronological seed, creates knockout placeholder slots, and reseeds ESPN broadcast rows for matches 1-24.
- `scripts/import_espn_squads.py` fetches ESPN team/squad pages and generates `dml/003_seed_espn_squads_generated.sql`.

Current DML seed coverage:

- All 48 teams from the ESPN teams page.
- All 12 groups and 48 group slots using the published draw/group structure.
- All 16 tournament venues from ESPN/FIFA schedule context.
- Complete 104-match schedule after `dml/002_seed_full_schedule.sql`.
- FOX/FS1 and Peacock broadcast entries for the ESPN-visible first 24 matches.
- ESPN team IDs, player IDs, squad roles, jersey numbers, heights/weights, ages, and team logo/color details after the generated squad seed is applied.

## Setting up database, schema and data on new machine

Local PostgreSQL setup:

```bash
brew install postgresql
brew services list
brew services start postgresql
createdb fifa26
psql -l
psql fifa26 -c "SELECT version();"


```

Schema and seed run order for a fresh local database using committed DDL/DML files:

```bash
psql -v ON_ERROR_STOP=1 fifa26 -f fifa26/ddl/001_schema.sql
psql -v ON_ERROR_STOP=1 fifa26 -f fifa26/ddl/002_players_squads.sql
psql -v ON_ERROR_STOP=1 fifa26 -f fifa26/dml/001_seed_core.sql
psql -v ON_ERROR_STOP=1 fifa26 -f fifa26/dml/002_seed_full_schedule.sql
psql -v ON_ERROR_STOP=1 fifa26 -f fifa26/dml/003_seed_espn_squads_generated.sql
psql fifa26 -f fifa26/sql/validate_database.sql
```

You do not need to run `python3 fifa26/scripts/import_espn_squads.py` for a brand-new laptop if `dml/003_seed_espn_squads_generated.sql` is present in the repository. That SQL file is the replayable seed generated from ESPN.

Run the Python importer only when you want to refresh squad data from ESPN and regenerate `dml/003_seed_espn_squads_generated.sql`:

### ESPN
The ESPN squad importer reads the official ESPN World Cup team listing at `https://www.espn.com/soccer/teams/_/league/fifa.world`, then follows each squad page such as `https://www.espn.com/soccer/team/squad/_/id/202/arg`. ESPN team and player IDs are stored in `source_records`; canonical app queries should use local `team_id` and `player_id`.

Current ESPN squad import caveats:

- The generated seed loaded 1,220 players and squad memberships across 47 teams.
- Curaçao (`CUW`) has an ESPN team row, but its squad page did not expose squad groups in the parsed payload, so it is listed as an import note in `dml/003_seed_espn_squads_generated.sql`.
- ESPN currently has one duplicate jersey number in the parsed data: Paraguay jersey 13 appears for Jose Canale and Juan Caceres. Because source data can have this kind of anomaly, `squad_memberships.jersey_number` is indexed for search but is not unique-constrained.

On the first schema run, PostgreSQL may print notices like:

```text
NOTICE: trigger "trg_tournaments_updated_at" for relation "tournaments" does not exist, skipping
```

Those notices are expected. The schema script drops triggers with `IF EXISTS` before recreating them so the script can be rerun safely. A successful run ends with `COMMIT`.

The validation script compares current database row counts against the expected finished tournament shape:

- 48 teams.
- 12 groups.
- 48 group-stage team slots.
- 16 venues.
- 72 group-stage matches.
- 32 knockout matches.
- 104 total matches.
- A nonzero player and squad-membership count after `ddl/002_players_squads.sql` and the generated ESPN squad seed are loaded.
- Current ESPN roster coverage should show `players = 1220`, `squad_memberships = 1220`, and `teams_with_squads = 47` until Curaçao squad data is available.

After `dml/002_seed_full_schedule.sql`, match counts should pass with `all_matches = 104`, `group_stage_matches = 72`, and `knockout_matches = 32`. Broadcast rows may still show `partial` because only the ESPN-visible first 24 matches currently have seeded US broadcast entries.

Next implementation step:

- Run the DDL/DML against a local PostgreSQL database.
- Verify row counts and the `v_match_schedule`, `v_team_schedule`, and `v_group_standings` views.
- Verify player lookups through `v_squad_players`, for example by player name, role, team, and jersey number.
- Build scraper/API jobs that refresh squads, ESPN game IDs, official FIFA match numbers, live results, and source payloads.
