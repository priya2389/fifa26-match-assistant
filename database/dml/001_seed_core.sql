BEGIN;

-- Sources used for this seed:
-- FIFA tournament page: https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026
-- ESPN schedule page: https://www.espn.com/soccer/schedule/_/league/fifa.world
-- ESPN teams page: https://www.espn.com/soccer/teams/_/league/fifa.world
--
-- Assumption: ESPN schedule times are displayed in US Eastern time for this seed.
-- Future scraper work should replace/confirm kickoff_at values with provider payload offsets.

INSERT INTO confederations (confederation_code, confederation_name) VALUES
('AFC', 'Asian Football Confederation'),
('CAF', 'Confederation of African Football'),
('CONCACAF', 'Confederation of North, Central America and Caribbean Association Football'),
('CONMEBOL', 'South American Football Confederation'),
('OFC', 'Oceania Football Confederation'),
('UEFA', 'Union of European Football Associations')
ON CONFLICT (confederation_code) DO UPDATE SET
    confederation_name = EXCLUDED.confederation_name;

INSERT INTO external_sources (source_name, base_url, priority, is_canonical) VALUES
('FIFA', 'https://www.fifa.com', 10, true),
('ESPN', 'https://www.espn.com', 30, false)
ON CONFLICT (source_name) DO UPDATE SET
    base_url = EXCLUDED.base_url,
    priority = EXCLUDED.priority,
    is_canonical = EXCLUDED.is_canonical;

WITH country_seed(fifa_code, iso2_code, iso3_code, country_name, confederation_code) AS (
    VALUES
    ('ALG', 'DZ', 'DZA', 'Algeria', 'CAF'),
    ('ARG', 'AR', 'ARG', 'Argentina', 'CONMEBOL'),
    ('AUS', 'AU', 'AUS', 'Australia', 'AFC'),
    ('AUT', 'AT', 'AUT', 'Austria', 'UEFA'),
    ('BEL', 'BE', 'BEL', 'Belgium', 'UEFA'),
    ('BIH', 'BA', 'BIH', 'Bosnia-Herzegovina', 'UEFA'),
    ('BRA', 'BR', 'BRA', 'Brazil', 'CONMEBOL'),
    ('CAN', 'CA', 'CAN', 'Canada', 'CONCACAF'),
    ('CIV', 'CI', 'CIV', 'Ivory Coast', 'CAF'),
    ('COD', 'CD', 'COD', 'Congo DR', 'CAF'),
    ('COL', 'CO', 'COL', 'Colombia', 'CONMEBOL'),
    ('CPV', 'CV', 'CPV', 'Cape Verde', 'CAF'),
    ('CRO', 'HR', 'HRV', 'Croatia', 'UEFA'),
    ('CUW', 'CW', 'CUW', 'Curacao', 'CONCACAF'),
    ('CZE', 'CZ', 'CZE', 'Czechia', 'UEFA'),
    ('ECU', 'EC', 'ECU', 'Ecuador', 'CONMEBOL'),
    ('EGY', 'EG', 'EGY', 'Egypt', 'CAF'),
    ('ENG', 'GB', 'GBR', 'England', 'UEFA'),
    ('ESP', 'ES', 'ESP', 'Spain', 'UEFA'),
    ('FRA', 'FR', 'FRA', 'France', 'UEFA'),
    ('GER', 'DE', 'DEU', 'Germany', 'UEFA'),
    ('GHA', 'GH', 'GHA', 'Ghana', 'CAF'),
    ('HAI', 'HT', 'HTI', 'Haiti', 'CONCACAF'),
    ('IRN', 'IR', 'IRN', 'Iran', 'AFC'),
    ('IRQ', 'IQ', 'IRQ', 'Iraq', 'AFC'),
    ('JOR', 'JO', 'JOR', 'Jordan', 'AFC'),
    ('JPN', 'JP', 'JPN', 'Japan', 'AFC'),
    ('KOR', 'KR', 'KOR', 'South Korea', 'AFC'),
    ('KSA', 'SA', 'SAU', 'Saudi Arabia', 'AFC'),
    ('MAR', 'MA', 'MAR', 'Morocco', 'CAF'),
    ('MEX', 'MX', 'MEX', 'Mexico', 'CONCACAF'),
    ('NED', 'NL', 'NLD', 'Netherlands', 'UEFA'),
    ('NOR', 'NO', 'NOR', 'Norway', 'UEFA'),
    ('NZL', 'NZ', 'NZL', 'New Zealand', 'OFC'),
    ('PAN', 'PA', 'PAN', 'Panama', 'CONCACAF'),
    ('PAR', 'PY', 'PRY', 'Paraguay', 'CONMEBOL'),
    ('POR', 'PT', 'PRT', 'Portugal', 'UEFA'),
    ('QAT', 'QA', 'QAT', 'Qatar', 'AFC'),
    ('RSA', 'ZA', 'ZAF', 'South Africa', 'CAF'),
    ('SCO', 'GB', 'GBR', 'Scotland', 'UEFA'),
    ('SEN', 'SN', 'SEN', 'Senegal', 'CAF'),
    ('SUI', 'CH', 'CHE', 'Switzerland', 'UEFA'),
    ('SWE', 'SE', 'SWE', 'Sweden', 'UEFA'),
    ('TUN', 'TN', 'TUN', 'Tunisia', 'CAF'),
    ('TUR', 'TR', 'TUR', 'Turkiye', 'UEFA'),
    ('URU', 'UY', 'URY', 'Uruguay', 'CONMEBOL'),
    ('USA', 'US', 'USA', 'United States', 'CONCACAF'),
    ('UZB', 'UZ', 'UZB', 'Uzbekistan', 'AFC')
)
INSERT INTO countries (fifa_code, iso2_code, iso3_code, country_name, confederation_code)
SELECT fifa_code, iso2_code, iso3_code, country_name, confederation_code
FROM country_seed
ON CONFLICT (fifa_code) DO UPDATE SET
    iso2_code = EXCLUDED.iso2_code,
    iso3_code = EXCLUDED.iso3_code,
    country_name = EXCLUDED.country_name,
    confederation_code = EXCLUDED.confederation_code;

WITH team_seed(fifa_code, display_name, short_name) AS (
    VALUES
    ('ALG', 'Algeria', 'Algeria'),
    ('ARG', 'Argentina', 'Argentina'),
    ('AUS', 'Australia', 'Australia'),
    ('AUT', 'Austria', 'Austria'),
    ('BEL', 'Belgium', 'Belgium'),
    ('BIH', 'Bosnia-Herzegovina', 'Bosnia-Herzegovina'),
    ('BRA', 'Brazil', 'Brazil'),
    ('CAN', 'Canada', 'Canada'),
    ('CIV', 'Ivory Coast', 'Ivory Coast'),
    ('COD', 'Congo DR', 'Congo DR'),
    ('COL', 'Colombia', 'Colombia'),
    ('CPV', 'Cape Verde', 'Cape Verde'),
    ('CRO', 'Croatia', 'Croatia'),
    ('CUW', 'Curacao', 'Curacao'),
    ('CZE', 'Czechia', 'Czechia'),
    ('ECU', 'Ecuador', 'Ecuador'),
    ('EGY', 'Egypt', 'Egypt'),
    ('ENG', 'England', 'England'),
    ('ESP', 'Spain', 'Spain'),
    ('FRA', 'France', 'France'),
    ('GER', 'Germany', 'Germany'),
    ('GHA', 'Ghana', 'Ghana'),
    ('HAI', 'Haiti', 'Haiti'),
    ('IRN', 'Iran', 'Iran'),
    ('IRQ', 'Iraq', 'Iraq'),
    ('JOR', 'Jordan', 'Jordan'),
    ('JPN', 'Japan', 'Japan'),
    ('KOR', 'South Korea', 'South Korea'),
    ('KSA', 'Saudi Arabia', 'Saudi Arabia'),
    ('MAR', 'Morocco', 'Morocco'),
    ('MEX', 'Mexico', 'Mexico'),
    ('NED', 'Netherlands', 'Netherlands'),
    ('NOR', 'Norway', 'Norway'),
    ('NZL', 'New Zealand', 'New Zealand'),
    ('PAN', 'Panama', 'Panama'),
    ('PAR', 'Paraguay', 'Paraguay'),
    ('POR', 'Portugal', 'Portugal'),
    ('QAT', 'Qatar', 'Qatar'),
    ('RSA', 'South Africa', 'South Africa'),
    ('SCO', 'Scotland', 'Scotland'),
    ('SEN', 'Senegal', 'Senegal'),
    ('SUI', 'Switzerland', 'Switzerland'),
    ('SWE', 'Sweden', 'Sweden'),
    ('TUN', 'Tunisia', 'Tunisia'),
    ('TUR', 'Turkiye', 'Turkiye'),
    ('URU', 'Uruguay', 'Uruguay'),
    ('USA', 'United States', 'United States'),
    ('UZB', 'Uzbekistan', 'Uzbekistan')
)
INSERT INTO teams (country_id, display_name, short_name)
SELECT c.country_id, ts.display_name, ts.short_name
FROM team_seed ts
JOIN countries c ON c.fifa_code = ts.fifa_code
ON CONFLICT (country_id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    short_name = EXCLUDED.short_name,
    is_active = true;

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
ON CONFLICT (name, season_year) DO UPDATE SET
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    host_countries = EXCLUDED.host_countries,
    format_summary = EXCLUDED.format_summary;

WITH stage_seed(stage_code, stage_name, stage_type, sort_order) AS (
    VALUES
    ('GROUP', 'Group Stage', 'group'::stage_type, 1),
    ('R32', 'Round of 32', 'knockout'::stage_type, 2),
    ('R16', 'Round of 16', 'knockout'::stage_type, 3),
    ('QF', 'Quarterfinals', 'knockout'::stage_type, 4),
    ('SF', 'Semifinals', 'knockout'::stage_type, 5),
    ('THIRD', 'Third-place Match', 'knockout'::stage_type, 6),
    ('FINAL', 'Final', 'knockout'::stage_type, 7)
)
INSERT INTO stages (tournament_id, stage_code, stage_name, stage_type, sort_order)
SELECT t.tournament_id, ss.stage_code, ss.stage_name, ss.stage_type, ss.sort_order
FROM stage_seed ss
CROSS JOIN tournaments t
WHERE t.name = 'FIFA World Cup 2026'
ON CONFLICT (tournament_id, stage_code) DO UPDATE SET
    stage_name = EXCLUDED.stage_name,
    stage_type = EXCLUDED.stage_type,
    sort_order = EXCLUDED.sort_order;

WITH group_seed(group_code, group_name, sort_order) AS (
    VALUES
    ('A', 'Group A', 1), ('B', 'Group B', 2), ('C', 'Group C', 3), ('D', 'Group D', 4),
    ('E', 'Group E', 5), ('F', 'Group F', 6), ('G', 'Group G', 7), ('H', 'Group H', 8),
    ('I', 'Group I', 9), ('J', 'Group J', 10), ('K', 'Group K', 11), ('L', 'Group L', 12)
)
INSERT INTO tournament_groups (tournament_id, group_code, group_name, sort_order)
SELECT t.tournament_id, gs.group_code, gs.group_name, gs.sort_order
FROM group_seed gs
CROSS JOIN tournaments t
WHERE t.name = 'FIFA World Cup 2026'
ON CONFLICT (tournament_id, group_code) DO UPDATE SET
    group_name = EXCLUDED.group_name,
    sort_order = EXCLUDED.sort_order;

WITH venue_seed(venue_name, city, region, country_code, timezone) AS (
    VALUES
    ('AT&T Stadium', 'Arlington', 'Texas', 'USA', 'America/Chicago'),
    ('BC Place', 'Vancouver', 'British Columbia', 'CAN', 'America/Vancouver'),
    ('BMO Field', 'Toronto', 'Ontario', 'CAN', 'America/Toronto'),
    ('Estadio Akron', 'Guadalajara', 'Jalisco', 'MEX', 'America/Mexico_City'),
    ('Estadio Banorte', 'Mexico City', 'Mexico City', 'MEX', 'America/Mexico_City'),
    ('Estadio BBVA', 'Guadalupe', 'Nuevo Leon', 'MEX', 'America/Monterrey'),
    ('GEHA Field at Arrowhead Stadium', 'Kansas City', 'Missouri', 'USA', 'America/Chicago'),
    ('Gillette Stadium', 'Foxborough', 'Massachusetts', 'USA', 'America/New_York'),
    ('Hard Rock Stadium', 'Miami Gardens', 'Florida', 'USA', 'America/New_York'),
    ('Levi''s Stadium', 'Santa Clara', 'California', 'USA', 'America/Los_Angeles'),
    ('Lincoln Financial Field', 'Philadelphia', 'Pennsylvania', 'USA', 'America/New_York'),
    ('Lumen Field', 'Seattle', 'Washington', 'USA', 'America/Los_Angeles'),
    ('Mercedes-Benz Stadium', 'Atlanta', 'Georgia', 'USA', 'America/New_York'),
    ('MetLife Stadium', 'East Rutherford', 'New Jersey', 'USA', 'America/New_York'),
    ('NRG Stadium', 'Houston', 'Texas', 'USA', 'America/Chicago'),
    ('SoFi Stadium', 'Inglewood', 'California', 'USA', 'America/Los_Angeles')
)
INSERT INTO venues (venue_name, city, region, country_code, timezone)
SELECT venue_name, city, region, country_code, timezone
FROM venue_seed
ON CONFLICT (venue_name, city, country_code) DO UPDATE SET
    region = EXCLUDED.region,
    timezone = EXCLUDED.timezone;

WITH slot_seed(slot_code, slot_name, group_code, position_in_group, draw_pot, fifa_code) AS (
    VALUES
    ('A1', 'Mexico', 'A', 1, 1, 'MEX'),
    ('A2', 'South Africa', 'A', 2, 3, 'RSA'),
    ('A3', 'South Korea', 'A', 3, 2, 'KOR'),
    ('A4', 'Czechia', 'A', 4, 4, 'CZE'),
    ('B1', 'Canada', 'B', 1, 1, 'CAN'),
    ('B2', 'Bosnia-Herzegovina', 'B', 2, 4, 'BIH'),
    ('B3', 'Qatar', 'B', 3, 3, 'QAT'),
    ('B4', 'Switzerland', 'B', 4, 2, 'SUI'),
    ('C1', 'Brazil', 'C', 1, 1, 'BRA'),
    ('C2', 'Morocco', 'C', 2, 2, 'MAR'),
    ('C3', 'Haiti', 'C', 3, 4, 'HAI'),
    ('C4', 'Scotland', 'C', 4, 3, 'SCO'),
    ('D1', 'United States', 'D', 1, 1, 'USA'),
    ('D2', 'Paraguay', 'D', 2, 3, 'PAR'),
    ('D3', 'Australia', 'D', 3, 4, 'AUS'),
    ('D4', 'Turkiye', 'D', 4, 2, 'TUR'),
    ('E1', 'Germany', 'E', 1, 1, 'GER'),
    ('E2', 'Curacao', 'E', 2, 4, 'CUW'),
    ('E3', 'Ivory Coast', 'E', 3, 3, 'CIV'),
    ('E4', 'Ecuador', 'E', 4, 2, 'ECU'),
    ('F1', 'Netherlands', 'F', 1, 1, 'NED'),
    ('F2', 'Japan', 'F', 2, 2, 'JPN'),
    ('F3', 'Sweden', 'F', 3, 3, 'SWE'),
    ('F4', 'Tunisia', 'F', 4, 4, 'TUN'),
    ('G1', 'Belgium', 'G', 1, 1, 'BEL'),
    ('G2', 'Egypt', 'G', 2, 4, 'EGY'),
    ('G3', 'Iran', 'G', 3, 3, 'IRN'),
    ('G4', 'New Zealand', 'G', 4, 2, 'NZL'),
    ('H1', 'Spain', 'H', 1, 1, 'ESP'),
    ('H2', 'Cape Verde', 'H', 2, 2, 'CPV'),
    ('H3', 'Saudi Arabia', 'H', 3, 4, 'KSA'),
    ('H4', 'Uruguay', 'H', 4, 3, 'URU'),
    ('I1', 'France', 'I', 1, 1, 'FRA'),
    ('I2', 'Senegal', 'I', 2, 2, 'SEN'),
    ('I3', 'Iraq', 'I', 3, 4, 'IRQ'),
    ('I4', 'Norway', 'I', 4, 3, 'NOR'),
    ('J1', 'Argentina', 'J', 1, 1, 'ARG'),
    ('J2', 'Algeria', 'J', 2, 3, 'ALG'),
    ('J3', 'Austria', 'J', 3, 2, 'AUT'),
    ('J4', 'Jordan', 'J', 4, 4, 'JOR'),
    ('K1', 'Portugal', 'K', 1, 1, 'POR'),
    ('K2', 'Congo DR', 'K', 2, 4, 'COD'),
    ('K3', 'Uzbekistan', 'K', 3, 3, 'UZB'),
    ('K4', 'Colombia', 'K', 4, 2, 'COL'),
    ('L1', 'England', 'L', 1, 1, 'ENG'),
    ('L2', 'Croatia', 'L', 2, 2, 'CRO'),
    ('L3', 'Ghana', 'L', 3, 4, 'GHA'),
    ('L4', 'Panama', 'L', 4, 3, 'PAN')
)
INSERT INTO tournament_slots (tournament_id, slot_code, slot_name, slot_type, team_id, group_id)
SELECT
    t.tournament_id,
    ss.slot_code,
    ss.slot_name,
    'group_position'::slot_type,
    team.team_id,
    grp.group_id
FROM slot_seed ss
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
JOIN tournament_groups grp
    ON grp.tournament_id = t.tournament_id
   AND grp.group_code = ss.group_code
JOIN countries country ON country.fifa_code = ss.fifa_code
JOIN teams team ON team.country_id = country.country_id
ON CONFLICT (tournament_id, slot_code) DO UPDATE SET
    slot_name = EXCLUDED.slot_name,
    slot_type = EXCLUDED.slot_type,
    team_id = EXCLUDED.team_id,
    group_id = EXCLUDED.group_id;

WITH slot_seed(slot_code, group_code, position_in_group, draw_pot) AS (
    VALUES
    ('A1', 'A', 1, 1), ('A2', 'A', 2, 3), ('A3', 'A', 3, 2), ('A4', 'A', 4, 4),
    ('B1', 'B', 1, 1), ('B2', 'B', 2, 4), ('B3', 'B', 3, 3), ('B4', 'B', 4, 2),
    ('C1', 'C', 1, 1), ('C2', 'C', 2, 2), ('C3', 'C', 3, 4), ('C4', 'C', 4, 3),
    ('D1', 'D', 1, 1), ('D2', 'D', 2, 3), ('D3', 'D', 3, 4), ('D4', 'D', 4, 2),
    ('E1', 'E', 1, 1), ('E2', 'E', 2, 4), ('E3', 'E', 3, 3), ('E4', 'E', 4, 2),
    ('F1', 'F', 1, 1), ('F2', 'F', 2, 2), ('F3', 'F', 3, 3), ('F4', 'F', 4, 4),
    ('G1', 'G', 1, 1), ('G2', 'G', 2, 4), ('G3', 'G', 3, 3), ('G4', 'G', 4, 2),
    ('H1', 'H', 1, 1), ('H2', 'H', 2, 2), ('H3', 'H', 3, 4), ('H4', 'H', 4, 3),
    ('I1', 'I', 1, 1), ('I2', 'I', 2, 2), ('I3', 'I', 3, 4), ('I4', 'I', 4, 3),
    ('J1', 'J', 1, 1), ('J2', 'J', 2, 3), ('J3', 'J', 3, 2), ('J4', 'J', 4, 4),
    ('K1', 'K', 1, 1), ('K2', 'K', 2, 4), ('K3', 'K', 3, 3), ('K4', 'K', 4, 2),
    ('L1', 'L', 1, 1), ('L2', 'L', 2, 2), ('L3', 'L', 3, 4), ('L4', 'L', 4, 3)
)
INSERT INTO group_entries (tournament_id, group_id, slot_id, position_in_group, draw_pot)
SELECT
    t.tournament_id,
    grp.group_id,
    slot.slot_id,
    ss.position_in_group,
    ss.draw_pot
FROM slot_seed ss
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
JOIN tournament_groups grp
    ON grp.tournament_id = t.tournament_id
   AND grp.group_code = ss.group_code
JOIN tournament_slots slot
    ON slot.tournament_id = t.tournament_id
   AND slot.slot_code = ss.slot_code
ON CONFLICT (slot_id) DO UPDATE SET
    group_id = EXCLUDED.group_id,
    position_in_group = EXCLUDED.position_in_group,
    draw_pot = EXCLUDED.draw_pot;

WITH match_seed(match_number, group_code, home_slot_code, away_slot_code, kickoff_at, venue_name, city, country_code, tv_carrier, notes) AS (
    VALUES
    (1, 'A', 'A1', 'A2', '2026-06-11 15:00:00-04'::timestamptz, 'Estadio Banorte', 'Mexico City', 'MEX', 'FOX', 'ESPN schedule showed Mexico v South Africa at 3:00 PM ET.'),
    (2, 'A', 'A3', 'A4', '2026-06-11 22:00:00-04'::timestamptz, 'Estadio Akron', 'Guadalajara', 'MEX', 'FS1', 'ESPN schedule showed South Korea v Czechia at 10:00 PM ET.'),
    (3, 'B', 'B1', 'B2', '2026-06-12 15:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'FOX', 'ESPN schedule showed Canada v Bosnia-Herzegovina at 3:00 PM ET.'),
    (4, 'D', 'D1', 'D2', '2026-06-12 21:00:00-04'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'FOX', 'ESPN schedule showed United States v Paraguay at 9:00 PM ET.'),
    (5, 'B', 'B3', 'B4', '2026-06-13 15:00:00-04'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'FOX', 'ESPN schedule showed Qatar v Switzerland at 3:00 PM ET.'),
    (6, 'C', 'C1', 'C2', '2026-06-13 18:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'FOX', 'ESPN schedule showed Brazil v Morocco at 6:00 PM ET.'),
    (7, 'C', 'C3', 'C4', '2026-06-13 21:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'FOX', 'ESPN schedule showed Haiti v Scotland at 9:00 PM ET.'),
    (8, 'D', 'D3', 'D4', '2026-06-14 00:00:00-04'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'FS1', 'ESPN schedule showed Australia v Turkiye at 12:00 AM ET.'),
    (9, 'E', 'E1', 'E2', '2026-06-14 13:00:00-04'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'FOX', 'ESPN schedule showed Germany v Curacao at 1:00 PM ET.'),
    (10, 'F', 'F1', 'F2', '2026-06-14 16:00:00-04'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'FOX', 'ESPN schedule showed Netherlands v Japan at 4:00 PM ET.'),
    (11, 'E', 'E3', 'E4', '2026-06-14 19:00:00-04'::timestamptz, 'Lincoln Financial Field', 'Philadelphia', 'USA', 'FS1', 'ESPN schedule showed Ivory Coast v Ecuador at 7:00 PM ET.'),
    (12, 'F', 'F3', 'F4', '2026-06-14 22:00:00-04'::timestamptz, 'Estadio BBVA', 'Guadalupe', 'MEX', 'FS1', 'ESPN schedule showed Sweden v Tunisia at 10:00 PM ET.'),
    (13, 'H', 'H1', 'H2', '2026-06-15 12:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'FOX', 'ESPN schedule showed Spain v Cape Verde at 12:00 PM ET.'),
    (14, 'G', 'G1', 'G2', '2026-06-15 15:00:00-04'::timestamptz, 'Lumen Field', 'Seattle', 'USA', 'FOX', 'ESPN schedule showed Belgium v Egypt at 3:00 PM ET.'),
    (15, 'H', 'H3', 'H4', '2026-06-15 18:00:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'FS1', 'ESPN schedule showed Saudi Arabia v Uruguay at 6:00 PM ET.'),
    (16, 'G', 'G3', 'G4', '2026-06-15 21:00:00-04'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'FS1', 'ESPN schedule showed Iran v New Zealand at 9:00 PM ET.'),
    (17, 'I', 'I1', 'I2', '2026-06-16 15:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'FOX', 'ESPN schedule showed France v Senegal at 3:00 PM ET.'),
    (18, 'I', 'I3', 'I4', '2026-06-16 18:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'FOX', 'ESPN schedule showed Iraq v Norway at 6:00 PM ET.'),
    (19, 'J', 'J1', 'J2', '2026-06-16 21:00:00-04'::timestamptz, 'GEHA Field at Arrowhead Stadium', 'Kansas City', 'USA', 'FOX', 'ESPN schedule showed Argentina v Algeria at 9:00 PM ET.'),
    (20, 'J', 'J3', 'J4', '2026-06-17 00:00:00-04'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'FS1', 'ESPN schedule showed Austria v Jordan at 12:00 AM ET.'),
    (21, 'K', 'K1', 'K2', '2026-06-17 13:00:00-04'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'FOX', 'ESPN schedule showed Portugal v Congo DR at 1:00 PM ET.'),
    (22, 'L', 'L1', 'L2', '2026-06-17 16:00:00-04'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'FOX', 'ESPN schedule showed England v Croatia at 4:00 PM ET.'),
    (23, 'L', 'L3', 'L4', '2026-06-17 19:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'FS1', 'ESPN schedule showed Ghana v Panama at 7:00 PM ET.'),
    (24, 'K', 'K3', 'K4', '2026-06-17 22:00:00-04'::timestamptz, 'Estadio Banorte', 'Mexico City', 'MEX', 'FS1', 'ESPN schedule showed Uzbekistan v Colombia at 10:00 PM ET.')
)
INSERT INTO matches (
    tournament_id,
    match_number,
    stage_id,
    group_id,
    venue_id,
    kickoff_at,
    status,
    home_slot_id,
    away_slot_id,
    notes
)
SELECT
    t.tournament_id,
    ms.match_number,
    stage.stage_id,
    grp.group_id,
    venue.venue_id,
    ms.kickoff_at,
    'scheduled'::match_status,
    home_slot.slot_id,
    away_slot.slot_id,
    ms.notes
FROM match_seed ms
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
JOIN stages stage
    ON stage.tournament_id = t.tournament_id
   AND stage.stage_code = 'GROUP'
JOIN tournament_groups grp
    ON grp.tournament_id = t.tournament_id
   AND grp.group_code = ms.group_code
JOIN tournament_slots home_slot
    ON home_slot.tournament_id = t.tournament_id
   AND home_slot.slot_code = ms.home_slot_code
JOIN tournament_slots away_slot
    ON away_slot.tournament_id = t.tournament_id
   AND away_slot.slot_code = ms.away_slot_code
JOIN venues venue
    ON venue.venue_name = ms.venue_name
   AND venue.city = ms.city
   AND venue.country_code = ms.country_code
ON CONFLICT (tournament_id, match_number) DO UPDATE SET
    stage_id = EXCLUDED.stage_id,
    group_id = EXCLUDED.group_id,
    venue_id = EXCLUDED.venue_id,
    kickoff_at = EXCLUDED.kickoff_at,
    status = EXCLUDED.status,
    home_slot_id = EXCLUDED.home_slot_id,
    away_slot_id = EXCLUDED.away_slot_id,
    notes = EXCLUDED.notes;

WITH broadcast_seed(match_number, broadcaster_name, language_code, broadcast_type) AS (
    SELECT match_number, tv_carrier, 'en', 'tv'
    FROM (
        VALUES
        (1, 'FOX'), (2, 'FS1'), (3, 'FOX'), (4, 'FOX'), (5, 'FOX'), (6, 'FOX'),
        (7, 'FOX'), (8, 'FS1'), (9, 'FOX'), (10, 'FOX'), (11, 'FS1'), (12, 'FS1'),
        (13, 'FOX'), (14, 'FOX'), (15, 'FS1'), (16, 'FS1'), (17, 'FOX'), (18, 'FOX'),
        (19, 'FOX'), (20, 'FS1'), (21, 'FOX'), (22, 'FOX'), (23, 'FS1'), (24, 'FS1')
    ) x(match_number, tv_carrier)

    UNION ALL

    SELECT gs.match_number, 'Peacock', 'es', 'streaming'
    FROM generate_series(1, 24) AS gs(match_number)
)
INSERT INTO match_broadcasts (
    match_id,
    market_country_code,
    language_code,
    broadcaster_name,
    broadcast_type,
    source_id
)
SELECT
    m.match_id,
    'USA',
    bs.language_code,
    bs.broadcaster_name,
    bs.broadcast_type,
    src.source_id
FROM broadcast_seed bs
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
JOIN matches m
    ON m.tournament_id = t.tournament_id
   AND m.match_number = bs.match_number
JOIN external_sources src ON src.source_name = 'ESPN'
ON CONFLICT DO NOTHING;

WITH tournament_sources(source_name, entity_type, external_id, source_url, raw_payload) AS (
    VALUES
    ('FIFA', 'tournament', 'fifa-world-cup-2026', 'https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026', '{"note":"Canonical tournament page used for competition context."}'::jsonb),
    ('ESPN', 'tournament', 'fifa.world', 'https://www.espn.com/soccer/worldcup/', '{"league_code":"fifa.world"}'::jsonb)
)
INSERT INTO source_records (source_id, entity_type, entity_id, external_id, source_url, raw_payload)
SELECT
    src.source_id,
    ts.entity_type,
    t.tournament_id,
    ts.external_id,
    ts.source_url,
    ts.raw_payload
FROM tournament_sources ts
JOIN external_sources src ON src.source_name = ts.source_name
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
ON CONFLICT (source_id, entity_type, external_id) DO UPDATE SET
    entity_id = EXCLUDED.entity_id,
    source_url = EXCLUDED.source_url,
    raw_payload = EXCLUDED.raw_payload,
    last_seen_at = now();

WITH espn_team_seed(fifa_code, external_id, source_url) AS (
    VALUES
    ('MEX', '203', 'https://www.espn.com/soccer/team/_/id/203/mexico'),
    ('ALG', '624', 'https://www.espn.com/soccer/team/_/id/624/algeria')
)
INSERT INTO source_records (source_id, entity_type, entity_id, external_id, source_url, raw_payload)
SELECT
    src.source_id,
    'team',
    team.team_id,
    ets.external_id,
    ets.source_url,
    jsonb_build_object('fifa_code', ets.fifa_code)
FROM espn_team_seed ets
JOIN external_sources src ON src.source_name = 'ESPN'
JOIN countries country ON country.fifa_code = ets.fifa_code
JOIN teams team ON team.country_id = country.country_id
ON CONFLICT (source_id, entity_type, external_id) DO UPDATE SET
    entity_id = EXCLUDED.entity_id,
    source_url = EXCLUDED.source_url,
    raw_payload = EXCLUDED.raw_payload,
    last_seen_at = now();

INSERT INTO source_records (source_id, entity_type, entity_id, external_id, source_url, raw_payload)
SELECT
    src.source_id,
    'match',
    m.match_id,
    '760415',
    'https://www.espn.com/soccer/match/_/gameId/760415/south-africa-mexico',
    '{"match_number_assumption":1,"note":"ESPN gameId captured from schedule match link."}'::jsonb
FROM external_sources src
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
JOIN matches m
    ON m.tournament_id = t.tournament_id
   AND m.match_number = 1
WHERE src.source_name = 'ESPN'
ON CONFLICT (source_id, entity_type, external_id) DO UPDATE SET
    entity_id = EXCLUDED.entity_id,
    source_url = EXCLUDED.source_url,
    raw_payload = EXCLUDED.raw_payload,
    last_seen_at = now();

COMMIT;
