BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_status') THEN
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
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'stage_type') THEN
        CREATE TYPE stage_type AS ENUM ('group', 'knockout');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'slot_type') THEN
        CREATE TYPE slot_type AS ENUM (
            'group_position',
            'team',
            'draw_placeholder',
            'group_rank',
            'best_third',
            'match_winner',
            'match_loser'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_decision_method') THEN
        CREATE TYPE match_decision_method AS ENUM (
            'regulation',
            'extra_time',
            'penalties',
            'forfeit',
            'walkover'
        );
    END IF;
END $$;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS tournaments (
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

CREATE TABLE IF NOT EXISTS confederations (
    confederation_code TEXT PRIMARY KEY,
    confederation_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS countries (
    country_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fifa_code CHAR(3) NOT NULL UNIQUE,
    iso2_code CHAR(2),
    iso3_code CHAR(3),
    country_name TEXT NOT NULL,
    confederation_code TEXT REFERENCES confederations(confederation_code),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS teams (
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

CREATE TABLE IF NOT EXISTS venues (
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
    CONSTRAINT venues_longitude_valid CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT venues_identity_unique UNIQUE (venue_name, city, country_code)
);

CREATE TABLE IF NOT EXISTS stages (
    stage_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    stage_code TEXT NOT NULL,
    stage_name TEXT NOT NULL,
    stage_type stage_type NOT NULL,
    sort_order INTEGER NOT NULL,

    CONSTRAINT stages_tournament_code_unique UNIQUE (tournament_id, stage_code),
    CONSTRAINT stages_sort_unique UNIQUE (tournament_id, sort_order)
);

CREATE TABLE IF NOT EXISTS tournament_groups (
    group_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    group_code CHAR(1) NOT NULL,
    group_name TEXT NOT NULL,
    sort_order INTEGER NOT NULL,

    CONSTRAINT tournament_groups_code_valid CHECK (group_code BETWEEN 'A' AND 'L'),
    CONSTRAINT tournament_groups_tournament_code_unique UNIQUE (tournament_id, group_code),
    CONSTRAINT tournament_groups_tournament_sort_unique UNIQUE (tournament_id, sort_order)
);

CREATE TABLE IF NOT EXISTS tournament_slots (
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

CREATE TABLE IF NOT EXISTS group_entries (
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

CREATE TABLE IF NOT EXISTS matches (
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
    CONSTRAINT matches_slots_different CHECK (home_slot_id <> away_slot_id),
    CONSTRAINT matches_scores_nonnegative CHECK (
        (home_score IS NULL OR home_score >= 0) AND
        (away_score IS NULL OR away_score >= 0) AND
        (home_penalties IS NULL OR home_penalties >= 0) AND
        (away_penalties IS NULL OR away_penalties >= 0)
    ),
    CONSTRAINT matches_attendance_nonnegative CHECK (attendance IS NULL OR attendance >= 0)
);

CREATE TABLE IF NOT EXISTS external_sources (
    source_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_name TEXT NOT NULL UNIQUE,
    base_url TEXT,
    priority INTEGER NOT NULL DEFAULT 100,
    is_canonical BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS match_broadcasts (
    match_broadcast_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id BIGINT NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    market_country_code CHAR(3) REFERENCES countries(fifa_code) ON DELETE RESTRICT,
    language_code TEXT,
    broadcaster_name TEXT NOT NULL,
    broadcast_type TEXT,
    source_id BIGINT REFERENCES external_sources(source_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_match_broadcasts_unique
    ON match_broadcasts (
        match_id,
        COALESCE(market_country_code::text, ''),
        COALESCE(language_code, ''),
        broadcaster_name,
        COALESCE(broadcast_type, '')
    );

CREATE TABLE IF NOT EXISTS source_records (
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

CREATE INDEX IF NOT EXISTS idx_countries_confederation ON countries(confederation_code);
CREATE INDEX IF NOT EXISTS idx_teams_fifa_team_id ON teams(fifa_team_id);
CREATE INDEX IF NOT EXISTS idx_venues_country_city ON venues(country_code, city);
CREATE INDEX IF NOT EXISTS idx_matches_kickoff_at ON matches(kickoff_at);
CREATE INDEX IF NOT EXISTS idx_matches_stage ON matches(stage_id);
CREATE INDEX IF NOT EXISTS idx_matches_group ON matches(group_id);
CREATE INDEX IF NOT EXISTS idx_matches_venue ON matches(venue_id);
CREATE INDEX IF NOT EXISTS idx_matches_home_slot ON matches(home_slot_id);
CREATE INDEX IF NOT EXISTS idx_matches_away_slot ON matches(away_slot_id);
CREATE INDEX IF NOT EXISTS idx_match_broadcasts_match ON match_broadcasts(match_id);
CREATE INDEX IF NOT EXISTS idx_match_broadcasts_broadcaster ON match_broadcasts(broadcaster_name);
CREATE INDEX IF NOT EXISTS idx_tournament_slots_team ON tournament_slots(team_id);
CREATE INDEX IF NOT EXISTS idx_source_records_entity ON source_records(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_source_records_raw_payload_gin ON source_records USING GIN (raw_payload);

DROP TRIGGER IF EXISTS trg_tournaments_updated_at ON tournaments;
CREATE TRIGGER trg_tournaments_updated_at
BEFORE UPDATE ON tournaments
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_countries_updated_at ON countries;
CREATE TRIGGER trg_countries_updated_at
BEFORE UPDATE ON countries
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_teams_updated_at ON teams;
CREATE TRIGGER trg_teams_updated_at
BEFORE UPDATE ON teams
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_venues_updated_at ON venues;
CREATE TRIGGER trg_venues_updated_at
BEFORE UPDATE ON venues
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_tournament_slots_updated_at ON tournament_slots;
CREATE TRIGGER trg_tournament_slots_updated_at
BEFORE UPDATE ON tournament_slots
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_group_entries_updated_at ON group_entries;
CREATE TRIGGER trg_group_entries_updated_at
BEFORE UPDATE ON group_entries
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_matches_updated_at ON matches;
CREATE TRIGGER trg_matches_updated_at
BEFORE UPDATE ON matches
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_match_broadcasts_updated_at ON match_broadcasts;
CREATE TRIGGER trg_match_broadcasts_updated_at
BEFORE UPDATE ON match_broadcasts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

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

COMMIT;
