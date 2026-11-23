BEGIN;

-- Completes the FIFA World Cup 2026 schedule to 104 matches.
-- Rows were generated from public FIFA-referenced group and knockout schedule pages.
-- This file also corrects early match numbers from the initial ESPN chronological seed.

WITH knockout_slot_seed(slot_code, slot_name, slot_type, group_code, group_rank, source_match_number) AS (
    VALUES
    ('BEST_3RD_A_B_C_D_F', 'Best third-place team from Groups A/B/C/D/F', 'best_third'::slot_type, NULL, NULL, NULL),
    ('BEST_3RD_A_E_H_I_J', 'Best third-place team from Groups A/E/H/I/J', 'best_third'::slot_type, NULL, NULL, NULL),
    ('BEST_3RD_B_E_F_I_J', 'Best third-place team from Groups B/E/F/I/J', 'best_third'::slot_type, NULL, NULL, NULL),
    ('BEST_3RD_C_D_F_G_H', 'Best third-place team from Groups C/D/F/G/H', 'best_third'::slot_type, NULL, NULL, NULL),
    ('BEST_3RD_C_E_F_H_I', 'Best third-place team from Groups C/E/F/H/I', 'best_third'::slot_type, NULL, NULL, NULL),
    ('BEST_3RD_D_E_I_J_L', 'Best third-place team from Groups D/E/I/J/L', 'best_third'::slot_type, NULL, NULL, NULL),
    ('BEST_3RD_E_F_G_I_J', 'Best third-place team from Groups E/F/G/I/J', 'best_third'::slot_type, NULL, NULL, NULL),
    ('BEST_3RD_E_H_I_J_K', 'Best third-place team from Groups E/H/I/J/K', 'best_third'::slot_type, NULL, NULL, NULL),
    ('GROUP_A_1', 'Winner Group A', 'group_rank'::slot_type, 'A', 1, NULL),
    ('GROUP_A_2', 'Runner-up Group A', 'group_rank'::slot_type, 'A', 2, NULL),
    ('GROUP_B_1', 'Winner Group B', 'group_rank'::slot_type, 'B', 1, NULL),
    ('GROUP_B_2', 'Runner-up Group B', 'group_rank'::slot_type, 'B', 2, NULL),
    ('GROUP_C_1', 'Winner Group C', 'group_rank'::slot_type, 'C', 1, NULL),
    ('GROUP_C_2', 'Runner-up Group C', 'group_rank'::slot_type, 'C', 2, NULL),
    ('GROUP_D_1', 'Winner Group D', 'group_rank'::slot_type, 'D', 1, NULL),
    ('GROUP_D_2', 'Runner-up Group D', 'group_rank'::slot_type, 'D', 2, NULL),
    ('GROUP_E_1', 'Winner Group E', 'group_rank'::slot_type, 'E', 1, NULL),
    ('GROUP_E_2', 'Runner-up Group E', 'group_rank'::slot_type, 'E', 2, NULL),
    ('GROUP_F_1', 'Winner Group F', 'group_rank'::slot_type, 'F', 1, NULL),
    ('GROUP_F_2', 'Runner-up Group F', 'group_rank'::slot_type, 'F', 2, NULL),
    ('GROUP_G_1', 'Winner Group G', 'group_rank'::slot_type, 'G', 1, NULL),
    ('GROUP_G_2', 'Runner-up Group G', 'group_rank'::slot_type, 'G', 2, NULL),
    ('GROUP_H_1', 'Winner Group H', 'group_rank'::slot_type, 'H', 1, NULL),
    ('GROUP_H_2', 'Runner-up Group H', 'group_rank'::slot_type, 'H', 2, NULL),
    ('GROUP_I_1', 'Winner Group I', 'group_rank'::slot_type, 'I', 1, NULL),
    ('GROUP_I_2', 'Runner-up Group I', 'group_rank'::slot_type, 'I', 2, NULL),
    ('GROUP_J_1', 'Winner Group J', 'group_rank'::slot_type, 'J', 1, NULL),
    ('GROUP_J_2', 'Runner-up Group J', 'group_rank'::slot_type, 'J', 2, NULL),
    ('GROUP_K_1', 'Winner Group K', 'group_rank'::slot_type, 'K', 1, NULL),
    ('GROUP_K_2', 'Runner-up Group K', 'group_rank'::slot_type, 'K', 2, NULL),
    ('GROUP_L_1', 'Winner Group L', 'group_rank'::slot_type, 'L', 1, NULL),
    ('GROUP_L_2', 'Runner-up Group L', 'group_rank'::slot_type, 'L', 2, NULL),
    ('L101', 'Loser Match 101', 'match_loser'::slot_type, NULL, NULL, 101),
    ('L102', 'Loser Match 102', 'match_loser'::slot_type, NULL, NULL, 102),
    ('W100', 'Winner Match 100', 'match_winner'::slot_type, NULL, NULL, 100),
    ('W101', 'Winner Match 101', 'match_winner'::slot_type, NULL, NULL, 101),
    ('W102', 'Winner Match 102', 'match_winner'::slot_type, NULL, NULL, 102),
    ('W73', 'Winner Match 73', 'match_winner'::slot_type, NULL, NULL, 73),
    ('W74', 'Winner Match 74', 'match_winner'::slot_type, NULL, NULL, 74),
    ('W75', 'Winner Match 75', 'match_winner'::slot_type, NULL, NULL, 75),
    ('W76', 'Winner Match 76', 'match_winner'::slot_type, NULL, NULL, 76),
    ('W77', 'Winner Match 77', 'match_winner'::slot_type, NULL, NULL, 77),
    ('W78', 'Winner Match 78', 'match_winner'::slot_type, NULL, NULL, 78),
    ('W79', 'Winner Match 79', 'match_winner'::slot_type, NULL, NULL, 79),
    ('W80', 'Winner Match 80', 'match_winner'::slot_type, NULL, NULL, 80),
    ('W81', 'Winner Match 81', 'match_winner'::slot_type, NULL, NULL, 81),
    ('W82', 'Winner Match 82', 'match_winner'::slot_type, NULL, NULL, 82),
    ('W83', 'Winner Match 83', 'match_winner'::slot_type, NULL, NULL, 83),
    ('W84', 'Winner Match 84', 'match_winner'::slot_type, NULL, NULL, 84),
    ('W85', 'Winner Match 85', 'match_winner'::slot_type, NULL, NULL, 85),
    ('W86', 'Winner Match 86', 'match_winner'::slot_type, NULL, NULL, 86),
    ('W87', 'Winner Match 87', 'match_winner'::slot_type, NULL, NULL, 87),
    ('W88', 'Winner Match 88', 'match_winner'::slot_type, NULL, NULL, 88),
    ('W89', 'Winner Match 89', 'match_winner'::slot_type, NULL, NULL, 89),
    ('W90', 'Winner Match 90', 'match_winner'::slot_type, NULL, NULL, 90),
    ('W91', 'Winner Match 91', 'match_winner'::slot_type, NULL, NULL, 91),
    ('W92', 'Winner Match 92', 'match_winner'::slot_type, NULL, NULL, 92),
    ('W93', 'Winner Match 93', 'match_winner'::slot_type, NULL, NULL, 93),
    ('W94', 'Winner Match 94', 'match_winner'::slot_type, NULL, NULL, 94),
    ('W95', 'Winner Match 95', 'match_winner'::slot_type, NULL, NULL, 95),
    ('W96', 'Winner Match 96', 'match_winner'::slot_type, NULL, NULL, 96),
    ('W97', 'Winner Match 97', 'match_winner'::slot_type, NULL, NULL, 97),
    ('W98', 'Winner Match 98', 'match_winner'::slot_type, NULL, NULL, 98),
    ('W99', 'Winner Match 99', 'match_winner'::slot_type, NULL, NULL, 99)
)
INSERT INTO tournament_slots (tournament_id, slot_code, slot_name, slot_type, group_id, group_rank, source_match_number)
SELECT t.tournament_id, kss.slot_code, kss.slot_name, kss.slot_type, grp.group_id, kss.group_rank, kss.source_match_number
FROM knockout_slot_seed kss
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
LEFT JOIN tournament_groups grp
    ON grp.tournament_id = t.tournament_id
   AND grp.group_code = kss.group_code
ON CONFLICT (tournament_id, slot_code) DO UPDATE SET
    slot_name = EXCLUDED.slot_name,
    slot_type = EXCLUDED.slot_type,
    group_id = EXCLUDED.group_id,
    group_rank = EXCLUDED.group_rank,
    source_match_number = EXCLUDED.source_match_number;

WITH match_seed(match_number, stage_code, group_code, home_slot_code, away_slot_code, kickoff_at, venue_name, city, country_code, notes) AS (
    VALUES
    (1, 'GROUP', 'A', 'A1', 'A2', '2026-06-11 13:00:00-06'::timestamptz, 'Estadio Banorte', 'Mexico City', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group A page; venue name normalized to local canonical row when needed.'),
    (2, 'GROUP', 'A', 'A3', 'A4', '2026-06-11 20:00:00-06'::timestamptz, 'Estadio Akron', 'Guadalajara', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group A page; venue name normalized to local canonical row when needed.'),
    (3, 'GROUP', 'B', 'B1', 'B2', '2026-06-12 15:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group B page; venue name normalized to local canonical row when needed.'),
    (4, 'GROUP', 'D', 'D1', 'D2', '2026-06-12 18:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group D page; venue name normalized to local canonical row when needed.'),
    (5, 'GROUP', 'C', 'C3', 'C4', '2026-06-13 21:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group C page; venue name normalized to local canonical row when needed.'),
    (6, 'GROUP', 'D', 'D3', 'D4', '2026-06-13 21:00:00-07'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group D page; venue name normalized to local canonical row when needed.'),
    (7, 'GROUP', 'C', 'C1', 'C2', '2026-06-13 18:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group C page; venue name normalized to local canonical row when needed.'),
    (8, 'GROUP', 'B', 'B3', 'B4', '2026-06-13 12:00:00-07'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group B page; venue name normalized to local canonical row when needed.'),
    (9, 'GROUP', 'E', 'E3', 'E4', '2026-06-14 19:00:00-04'::timestamptz, 'Lincoln Financial Field', 'Philadelphia', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group E page; venue name normalized to local canonical row when needed.'),
    (10, 'GROUP', 'E', 'E1', 'E2', '2026-06-14 12:00:00-05'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group E page; venue name normalized to local canonical row when needed.'),
    (11, 'GROUP', 'F', 'F1', 'F2', '2026-06-14 15:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group F page; venue name normalized to local canonical row when needed.'),
    (12, 'GROUP', 'F', 'F3', 'F4', '2026-06-14 20:00:00-06'::timestamptz, 'Estadio BBVA', 'Guadalupe', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group F page; venue name normalized to local canonical row when needed.'),
    (13, 'GROUP', 'H', 'H3', 'H4', '2026-06-15 18:00:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group H page; venue name normalized to local canonical row when needed.'),
    (14, 'GROUP', 'H', 'H1', 'H2', '2026-06-15 12:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group H page; venue name normalized to local canonical row when needed.'),
    (15, 'GROUP', 'G', 'G3', 'G4', '2026-06-15 18:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group G page; venue name normalized to local canonical row when needed.'),
    (16, 'GROUP', 'G', 'G1', 'G2', '2026-06-15 12:00:00-07'::timestamptz, 'Lumen Field', 'Seattle', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group G page; venue name normalized to local canonical row when needed.'),
    (17, 'GROUP', 'I', 'I1', 'I2', '2026-06-16 15:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group I page; venue name normalized to local canonical row when needed.'),
    (18, 'GROUP', 'I', 'I3', 'I4', '2026-06-16 18:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group I page; venue name normalized to local canonical row when needed.'),
    (19, 'GROUP', 'J', 'J1', 'J2', '2026-06-16 20:00:00-05'::timestamptz, 'GEHA Field at Arrowhead Stadium', 'Kansas City', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group J page; venue name normalized to local canonical row when needed.'),
    (20, 'GROUP', 'J', 'J3', 'J4', '2026-06-16 21:00:00-07'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group J page; venue name normalized to local canonical row when needed.'),
    (21, 'GROUP', 'L', 'L3', 'L4', '2026-06-17 19:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group L page; venue name normalized to local canonical row when needed.'),
    (22, 'GROUP', 'L', 'L1', 'L2', '2026-06-17 15:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group L page; venue name normalized to local canonical row when needed.'),
    (23, 'GROUP', 'K', 'K1', 'K2', '2026-06-17 12:00:00-05'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group K page; venue name normalized to local canonical row when needed.'),
    (24, 'GROUP', 'K', 'K3', 'K4', '2026-06-17 20:00:00-06'::timestamptz, 'Estadio Banorte', 'Mexico City', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group K page; venue name normalized to local canonical row when needed.'),
    (25, 'GROUP', 'A', 'A4', 'A2', '2026-06-18 12:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group A page; venue name normalized to local canonical row when needed.'),
    (26, 'GROUP', 'B', 'B4', 'B2', '2026-06-18 12:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group B page; venue name normalized to local canonical row when needed.'),
    (27, 'GROUP', 'B', 'B1', 'B3', '2026-06-18 15:00:00-07'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group B page; venue name normalized to local canonical row when needed.'),
    (28, 'GROUP', 'A', 'A1', 'A3', '2026-06-18 19:00:00-06'::timestamptz, 'Estadio Akron', 'Guadalajara', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group A page; venue name normalized to local canonical row when needed.'),
    (29, 'GROUP', 'C', 'C1', 'C3', '2026-06-19 20:30:00-04'::timestamptz, 'Lincoln Financial Field', 'Philadelphia', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group C page; venue name normalized to local canonical row when needed.'),
    (30, 'GROUP', 'C', 'C4', 'C2', '2026-06-19 18:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group C page; venue name normalized to local canonical row when needed.'),
    (31, 'GROUP', 'D', 'D4', 'D2', '2026-06-19 20:00:00-07'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group D page; venue name normalized to local canonical row when needed.'),
    (32, 'GROUP', 'D', 'D1', 'D3', '2026-06-19 12:00:00-07'::timestamptz, 'Lumen Field', 'Seattle', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group D page; venue name normalized to local canonical row when needed.'),
    (33, 'GROUP', 'E', 'E1', 'E3', '2026-06-20 16:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group E page; venue name normalized to local canonical row when needed.'),
    (34, 'GROUP', 'E', 'E4', 'E2', '2026-06-20 19:00:00-05'::timestamptz, 'GEHA Field at Arrowhead Stadium', 'Kansas City', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group E page; venue name normalized to local canonical row when needed.'),
    (35, 'GROUP', 'F', 'F1', 'F3', '2026-06-20 12:00:00-05'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group F page; venue name normalized to local canonical row when needed.'),
    (36, 'GROUP', 'F', 'F4', 'F2', '2026-06-20 22:00:00-06'::timestamptz, 'Estadio BBVA', 'Guadalupe', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group F page; venue name normalized to local canonical row when needed.'),
    (37, 'GROUP', 'H', 'H4', 'H2', '2026-06-21 18:00:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group H page; venue name normalized to local canonical row when needed.'),
    (38, 'GROUP', 'H', 'H1', 'H3', '2026-06-21 12:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group H page; venue name normalized to local canonical row when needed.'),
    (39, 'GROUP', 'G', 'G1', 'G3', '2026-06-21 12:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group G page; venue name normalized to local canonical row when needed.'),
    (40, 'GROUP', 'G', 'G4', 'G2', '2026-06-21 18:00:00-07'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group G page; venue name normalized to local canonical row when needed.'),
    (41, 'GROUP', 'I', 'I4', 'I2', '2026-06-22 20:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group I page; venue name normalized to local canonical row when needed.'),
    (42, 'GROUP', 'I', 'I1', 'I3', '2026-06-22 17:00:00-04'::timestamptz, 'Lincoln Financial Field', 'Philadelphia', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group I page; venue name normalized to local canonical row when needed.'),
    (43, 'GROUP', 'J', 'J1', 'J3', '2026-06-22 12:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group J page; venue name normalized to local canonical row when needed.'),
    (44, 'GROUP', 'J', 'J4', 'J2', '2026-06-22 20:00:00-07'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group J page; venue name normalized to local canonical row when needed.'),
    (45, 'GROUP', 'L', 'L1', 'L3', '2026-06-23 16:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group L page; venue name normalized to local canonical row when needed.'),
    (46, 'GROUP', 'L', 'L4', 'L2', '2026-06-23 19:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group L page; venue name normalized to local canonical row when needed.'),
    (47, 'GROUP', 'K', 'K1', 'K3', '2026-06-23 12:00:00-05'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group K page; venue name normalized to local canonical row when needed.'),
    (48, 'GROUP', 'K', 'K4', 'K2', '2026-06-23 20:00:00-06'::timestamptz, 'Estadio Akron', 'Guadalajara', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group K page; venue name normalized to local canonical row when needed.'),
    (49, 'GROUP', 'C', 'C4', 'C1', '2026-06-24 18:00:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group C page; venue name normalized to local canonical row when needed.'),
    (50, 'GROUP', 'C', 'C2', 'C3', '2026-06-24 18:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group C page; venue name normalized to local canonical row when needed.'),
    (51, 'GROUP', 'B', 'B4', 'B1', '2026-06-24 12:00:00-07'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group B page; venue name normalized to local canonical row when needed.'),
    (52, 'GROUP', 'B', 'B2', 'B3', '2026-06-24 12:00:00-07'::timestamptz, 'Lumen Field', 'Seattle', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group B page; venue name normalized to local canonical row when needed.'),
    (53, 'GROUP', 'A', 'A4', 'A1', '2026-06-24 19:00:00-06'::timestamptz, 'Estadio Banorte', 'Mexico City', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group A page; venue name normalized to local canonical row when needed.'),
    (54, 'GROUP', 'A', 'A2', 'A3', '2026-06-24 19:00:00-06'::timestamptz, 'Estadio BBVA', 'Guadalupe', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group A page; venue name normalized to local canonical row when needed.'),
    (55, 'GROUP', 'E', 'E2', 'E3', '2026-06-25 16:00:00-04'::timestamptz, 'Lincoln Financial Field', 'Philadelphia', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group E page; venue name normalized to local canonical row when needed.'),
    (56, 'GROUP', 'E', 'E4', 'E1', '2026-06-25 16:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group E page; venue name normalized to local canonical row when needed.'),
    (57, 'GROUP', 'F', 'F2', 'F3', '2026-06-25 18:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group F page; venue name normalized to local canonical row when needed.'),
    (58, 'GROUP', 'F', 'F4', 'F1', '2026-06-25 18:00:00-05'::timestamptz, 'GEHA Field at Arrowhead Stadium', 'Kansas City', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group F page; venue name normalized to local canonical row when needed.'),
    (59, 'GROUP', 'D', 'D4', 'D1', '2026-06-25 19:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group D page; venue name normalized to local canonical row when needed.'),
    (60, 'GROUP', 'D', 'D2', 'D3', '2026-06-25 19:00:00-07'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group D page; venue name normalized to local canonical row when needed.'),
    (61, 'GROUP', 'I', 'I4', 'I1', '2026-06-26 15:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group I page; venue name normalized to local canonical row when needed.'),
    (62, 'GROUP', 'I', 'I2', 'I3', '2026-06-26 15:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group I page; venue name normalized to local canonical row when needed.'),
    (63, 'GROUP', 'G', 'G2', 'G3', '2026-06-26 20:00:00-07'::timestamptz, 'Lumen Field', 'Seattle', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group G page; venue name normalized to local canonical row when needed.'),
    (64, 'GROUP', 'G', 'G4', 'G1', '2026-06-26 20:00:00-07'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'Official group-stage schedule from FIFA/Wikipedia Group G page; venue name normalized to local canonical row when needed.'),
    (65, 'GROUP', 'H', 'H2', 'H3', '2026-06-26 19:00:00-05'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group H page; venue name normalized to local canonical row when needed.'),
    (66, 'GROUP', 'H', 'H4', 'H1', '2026-06-26 18:00:00-06'::timestamptz, 'Estadio Akron', 'Guadalajara', 'MEX', 'Official group-stage schedule from FIFA/Wikipedia Group H page; venue name normalized to local canonical row when needed.'),
    (67, 'GROUP', 'L', 'L4', 'L1', '2026-06-27 17:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group L page; venue name normalized to local canonical row when needed.'),
    (68, 'GROUP', 'L', 'L2', 'L3', '2026-06-27 17:00:00-04'::timestamptz, 'Lincoln Financial Field', 'Philadelphia', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group L page; venue name normalized to local canonical row when needed.'),
    (69, 'GROUP', 'J', 'J2', 'J3', '2026-06-27 21:00:00-05'::timestamptz, 'GEHA Field at Arrowhead Stadium', 'Kansas City', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group J page; venue name normalized to local canonical row when needed.'),
    (70, 'GROUP', 'J', 'J4', 'J1', '2026-06-27 21:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group J page; venue name normalized to local canonical row when needed.'),
    (71, 'GROUP', 'K', 'K4', 'K1', '2026-06-27 19:30:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group K page; venue name normalized to local canonical row when needed.'),
    (72, 'GROUP', 'K', 'K2', 'K3', '2026-06-27 19:30:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official group-stage schedule from FIFA/Wikipedia Group K page; venue name normalized to local canonical row when needed.'),
    (73, 'R32', NULL, 'GROUP_A_2', 'GROUP_B_2', '2026-06-28 12:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (74, 'R32', NULL, 'GROUP_E_1', 'BEST_3RD_A_B_C_D_F', '2026-06-29 16:30:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (75, 'R32', NULL, 'GROUP_F_1', 'GROUP_C_2', '2026-06-29 19:00:00-06'::timestamptz, 'Estadio BBVA', 'Guadalupe', 'MEX', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (76, 'R32', NULL, 'GROUP_C_1', 'GROUP_F_2', '2026-06-29 12:00:00-05'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (77, 'R32', NULL, 'GROUP_I_1', 'BEST_3RD_C_D_F_G_H', '2026-06-30 17:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (78, 'R32', NULL, 'GROUP_E_2', 'GROUP_I_2', '2026-06-30 12:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (79, 'R32', NULL, 'GROUP_A_1', 'BEST_3RD_C_E_F_H_I', '2026-06-30 19:00:00-06'::timestamptz, 'Estadio Banorte', 'Mexico City', 'MEX', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (80, 'R32', NULL, 'GROUP_L_1', 'BEST_3RD_E_H_I_J_K', '2026-07-01 12:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (81, 'R32', NULL, 'GROUP_D_1', 'BEST_3RD_B_E_F_I_J', '2026-07-01 17:00:00-07'::timestamptz, 'Levi''s Stadium', 'Santa Clara', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (82, 'R32', NULL, 'GROUP_G_1', 'BEST_3RD_A_E_H_I_J', '2026-07-01 13:00:00-07'::timestamptz, 'Lumen Field', 'Seattle', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (83, 'R32', NULL, 'GROUP_K_2', 'GROUP_L_2', '2026-07-02 19:00:00-04'::timestamptz, 'BMO Field', 'Toronto', 'CAN', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (84, 'R32', NULL, 'GROUP_H_1', 'GROUP_J_2', '2026-07-02 12:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (85, 'R32', NULL, 'GROUP_B_1', 'BEST_3RD_E_F_G_I_J', '2026-07-02 20:00:00-07'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (86, 'R32', NULL, 'GROUP_J_1', 'GROUP_H_2', '2026-07-03 18:00:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (87, 'R32', NULL, 'GROUP_K_1', 'BEST_3RD_D_E_I_J_L', '2026-07-03 20:30:00-05'::timestamptz, 'GEHA Field at Arrowhead Stadium', 'Kansas City', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (88, 'R32', NULL, 'GROUP_D_2', 'GROUP_G_2', '2026-07-03 13:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (89, 'R16', NULL, 'W74', 'W77', '2026-07-04 17:00:00-04'::timestamptz, 'Lincoln Financial Field', 'Philadelphia', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (90, 'R16', NULL, 'W73', 'W75', '2026-07-04 12:00:00-05'::timestamptz, 'NRG Stadium', 'Houston', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (91, 'R16', NULL, 'W76', 'W78', '2026-07-05 16:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (92, 'R16', NULL, 'W79', 'W80', '2026-07-05 18:00:00-06'::timestamptz, 'Estadio Banorte', 'Mexico City', 'MEX', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (93, 'R16', NULL, 'W83', 'W84', '2026-07-06 14:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (94, 'R16', NULL, 'W81', 'W82', '2026-07-06 17:00:00-07'::timestamptz, 'Lumen Field', 'Seattle', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (95, 'R16', NULL, 'W86', 'W88', '2026-07-07 12:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (96, 'R16', NULL, 'W85', 'W87', '2026-07-07 13:00:00-07'::timestamptz, 'BC Place', 'Vancouver', 'CAN', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (97, 'QF', NULL, 'W89', 'W90', '2026-07-09 16:00:00-04'::timestamptz, 'Gillette Stadium', 'Foxborough', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (98, 'QF', NULL, 'W93', 'W94', '2026-07-10 12:00:00-07'::timestamptz, 'SoFi Stadium', 'Inglewood', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (99, 'QF', NULL, 'W91', 'W92', '2026-07-11 17:00:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (100, 'QF', NULL, 'W95', 'W96', '2026-07-11 20:00:00-05'::timestamptz, 'GEHA Field at Arrowhead Stadium', 'Kansas City', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (101, 'SF', NULL, 'W97', 'W98', '2026-07-14 14:00:00-05'::timestamptz, 'AT&T Stadium', 'Arlington', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (102, 'SF', NULL, 'W99', 'W100', '2026-07-15 15:00:00-04'::timestamptz, 'Mercedes-Benz Stadium', 'Atlanta', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (103, 'THIRD', NULL, 'L101', 'L102', '2026-07-18 17:00:00-04'::timestamptz, 'Hard Rock Stadium', 'Miami Gardens', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.'),
    (104, 'FINAL', NULL, 'W101', 'W102', '2026-07-19 15:00:00-04'::timestamptz, 'MetLife Stadium', 'East Rutherford', 'USA', 'Official knockout schedule placeholder from FIFA/Wikipedia knockout page.')
)
INSERT INTO matches (
    tournament_id, match_number, stage_id, group_id, venue_id, kickoff_at, status, home_slot_id, away_slot_id, notes
)
SELECT t.tournament_id, ms.match_number, stage.stage_id, grp.group_id, venue.venue_id, ms.kickoff_at,
       'scheduled'::match_status, home_slot.slot_id, away_slot.slot_id, ms.notes
FROM match_seed ms
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
JOIN stages stage
    ON stage.tournament_id = t.tournament_id
   AND stage.stage_code = ms.stage_code
LEFT JOIN tournament_groups grp
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

-- Reset and reinsert ESPN broadcast rows for the first 24 matches using official FIFA match numbers.
DELETE FROM match_broadcasts mb
USING matches m, tournaments t, external_sources src
WHERE mb.match_id = m.match_id
  AND m.tournament_id = t.tournament_id
  AND t.name = 'FIFA World Cup 2026'
  AND src.source_name = 'ESPN'
  AND mb.source_id = src.source_id
  AND m.match_number BETWEEN 1 AND 24;

WITH broadcast_seed(match_number, broadcaster_name, language_code, broadcast_type) AS (
    VALUES
    (1, 'FOX', 'en', 'tv'),
    (2, 'FS1', 'en', 'tv'),
    (3, 'FOX', 'en', 'tv'),
    (4, 'FOX', 'en', 'tv'),
    (5, 'FOX', 'en', 'tv'),
    (6, 'FS1', 'en', 'tv'),
    (7, 'FOX', 'en', 'tv'),
    (8, 'FOX', 'en', 'tv'),
    (9, 'FS1', 'en', 'tv'),
    (10, 'FOX', 'en', 'tv'),
    (11, 'FOX', 'en', 'tv'),
    (12, 'FS1', 'en', 'tv'),
    (13, 'FS1', 'en', 'tv'),
    (14, 'FOX', 'en', 'tv'),
    (15, 'FS1', 'en', 'tv'),
    (16, 'FOX', 'en', 'tv'),
    (17, 'FOX', 'en', 'tv'),
    (18, 'FOX', 'en', 'tv'),
    (19, 'FOX', 'en', 'tv'),
    (20, 'FS1', 'en', 'tv'),
    (21, 'FS1', 'en', 'tv'),
    (22, 'FOX', 'en', 'tv'),
    (23, 'FOX', 'en', 'tv'),
    (24, 'FS1', 'en', 'tv'),
    (1, 'Peacock', 'es', 'streaming'),
    (2, 'Peacock', 'es', 'streaming'),
    (3, 'Peacock', 'es', 'streaming'),
    (4, 'Peacock', 'es', 'streaming'),
    (5, 'Peacock', 'es', 'streaming'),
    (6, 'Peacock', 'es', 'streaming'),
    (7, 'Peacock', 'es', 'streaming'),
    (8, 'Peacock', 'es', 'streaming'),
    (9, 'Peacock', 'es', 'streaming'),
    (10, 'Peacock', 'es', 'streaming'),
    (11, 'Peacock', 'es', 'streaming'),
    (12, 'Peacock', 'es', 'streaming'),
    (13, 'Peacock', 'es', 'streaming'),
    (14, 'Peacock', 'es', 'streaming'),
    (15, 'Peacock', 'es', 'streaming'),
    (16, 'Peacock', 'es', 'streaming'),
    (17, 'Peacock', 'es', 'streaming'),
    (18, 'Peacock', 'es', 'streaming'),
    (19, 'Peacock', 'es', 'streaming'),
    (20, 'Peacock', 'es', 'streaming'),
    (21, 'Peacock', 'es', 'streaming'),
    (22, 'Peacock', 'es', 'streaming'),
    (23, 'Peacock', 'es', 'streaming'),
    (24, 'Peacock', 'es', 'streaming')
)
INSERT INTO match_broadcasts (match_id, market_country_code, language_code, broadcaster_name, broadcast_type, source_id)
SELECT m.match_id, 'USA', bs.language_code, bs.broadcaster_name, bs.broadcast_type, src.source_id
FROM broadcast_seed bs
JOIN tournaments t ON t.name = 'FIFA World Cup 2026'
JOIN matches m
    ON m.tournament_id = t.tournament_id
   AND m.match_number = bs.match_number
JOIN external_sources src ON src.source_name = 'ESPN'
ON CONFLICT DO NOTHING;

COMMIT;
