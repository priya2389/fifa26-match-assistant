CREATE TABLE conversations (
    id          TEXT PRIMARY KEY,
    name        TEXT,
    created_at  TIMESTAMP DEFAULT NOW());

CREATE TABLE messages (
    id                  SERIAL PRIMARY KEY,
    conversation_id     TEXT REFERENCES conversations(id) ON DELETE CASCADE,
    role                TEXT NOT NULL,
    content             TEXT NOT NULL,
    created_at          TIMESTAMP DEFAULT NOW());