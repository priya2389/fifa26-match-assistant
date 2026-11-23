BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE teams
    ADD COLUMN IF NOT EXISTS abbreviation TEXT,
    ADD COLUMN IF NOT EXISTS logo_url TEXT,
    ADD COLUMN IF NOT EXISTS primary_color TEXT;

CREATE TABLE IF NOT EXISTS players (
    player_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    display_name TEXT NOT NULL,
    short_name TEXT,
    first_name TEXT,
    last_name TEXT,
    nationality TEXT,
    nationality_country_id BIGINT REFERENCES countries(country_id) ON DELETE SET NULL,
    height_text TEXT,
    weight_text TEXT,
    birth_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT players_display_name_not_blank CHECK (btrim(display_name) <> '')
);

CREATE TABLE IF NOT EXISTS squad_memberships (
    squad_membership_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tournament_id BIGINT NOT NULL REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    team_id BIGINT NOT NULL REFERENCES teams(team_id) ON DELETE CASCADE,
    player_id BIGINT NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
    jersey_number INTEGER,
    position_code TEXT,
    position_name TEXT,
    roster_group TEXT,
    age INTEGER,
    is_active BOOLEAN NOT NULL DEFAULT true,
    source_id BIGINT REFERENCES external_sources(source_id) ON DELETE SET NULL,
    source_url TEXT,
    raw_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT squad_memberships_unique_player UNIQUE (tournament_id, team_id, player_id),
    CONSTRAINT squad_memberships_jersey_valid CHECK (
        jersey_number IS NULL OR jersey_number BETWEEN 1 AND 99
    ),
    CONSTRAINT squad_memberships_age_valid CHECK (
        age IS NULL OR age BETWEEN 14 AND 60
    )
);

DROP INDEX IF EXISTS idx_squad_memberships_unique_jersey;

CREATE INDEX IF NOT EXISTS idx_players_display_name_trgm
    ON players USING GIN (display_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_players_short_name_trgm
    ON players USING GIN (short_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_players_nationality_country
    ON players(nationality_country_id);

CREATE INDEX IF NOT EXISTS idx_squad_memberships_team
    ON squad_memberships(tournament_id, team_id);

CREATE INDEX IF NOT EXISTS idx_squad_memberships_player
    ON squad_memberships(player_id);

CREATE INDEX IF NOT EXISTS idx_squad_memberships_position
    ON squad_memberships(position_code, position_name);

CREATE INDEX IF NOT EXISTS idx_squad_memberships_jersey
    ON squad_memberships(tournament_id, team_id, jersey_number);

DROP TRIGGER IF EXISTS trg_players_updated_at ON players;
CREATE TRIGGER trg_players_updated_at
BEFORE UPDATE ON players
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_squad_memberships_updated_at ON squad_memberships;
CREATE TRIGGER trg_squad_memberships_updated_at
BEFORE UPDATE ON squad_memberships
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE VIEW v_squad_players AS
SELECT
    sm.squad_membership_id,
    tournament.name AS tournament_name,
    team.team_id,
    team.display_name AS team_name,
    country.fifa_code,
    team.abbreviation,
    team.logo_url,
    sm.jersey_number,
    sm.position_code,
    sm.position_name,
    sm.roster_group,
    sm.age,
    player.player_id,
    player.display_name AS player_name,
    player.short_name AS player_short_name,
    player.nationality,
    player.height_text,
    player.weight_text,
    sm.is_active,
    squad_source.source_name AS squad_source_name,
    sm.source_url AS squad_source_url,
    player_source.external_id AS espn_player_id,
    team_source.external_id AS espn_team_id
FROM squad_memberships sm
JOIN tournaments tournament ON tournament.tournament_id = sm.tournament_id
JOIN teams team ON team.team_id = sm.team_id
JOIN countries country ON country.country_id = team.country_id
JOIN players player ON player.player_id = sm.player_id
LEFT JOIN external_sources squad_source ON squad_source.source_id = sm.source_id
LEFT JOIN external_sources espn_source ON espn_source.source_name = 'ESPN'
LEFT JOIN source_records player_source
    ON player_source.source_id = espn_source.source_id
   AND player_source.entity_type = 'player'
   AND player_source.entity_id = player.player_id
LEFT JOIN source_records team_source
    ON team_source.source_id = espn_source.source_id
   AND team_source.entity_type = 'team'
   AND team_source.entity_id = team.team_id;

COMMIT;
