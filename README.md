# FIFA World Cup 2026 Match Assistant

A chat assistant for the 2026 World Cup. Ask about matches, schedules, scores and players in plain English. A Strands agent answers by calling SQL tools over a Postgres database that refreshes from public match data each time the app starts.

## Architecture

```
React + Radix chat UI (web_app_one, :5173)
   │  /chat                          │  /conversations
   ▼                                 ▼
Agent server (agent, FastAPI :8000)  Conversation API (public_API, FastAPI :8001)
   │  Strands agent, Gemini 2.5 Flash      │
   │                                       ▼
   ├─ MCP: Google MCP Toolbox (:5000) ──► FIFA26 Postgres DB   Conversation history DB
   ├─ MCP: mcp-file-reader (stdio)          ▲
   └─ calculator, current_time              │
                                       data_sync (runs on startup: scores + group stage)
```

| Folder | Purpose |
|---|---|
| `agent/` | `agent_server.py` exposes the Strands agent at `POST /chat`. `tools.yaml` defines the Toolbox SQL tools (list players, player → country, matches by date, match details). |
| `public_API/` | FastAPI service that stores, lists, renames and deletes chat conversations in Postgres. |
| `web_app_one/` | React + Vite + Radix UI chat interface with a conversation sidebar and markdown rendering. |
| `data_sync/` | Pulls the latest results from [openfootball/worldcup.json](https://github.com/openfootball/worldcup.json) and resolves group-stage standings. |
| `database/` | FIFA26 schema (DDL) and seed data (DML). See `database/DBDESIGN.md`. |
| `run.py` | Starts Toolbox, both APIs and the frontend together. Refreshes the database first and shuts everything down if any process exits. |

## Running locally

**Requirements:** Python 3.11+, Node 18+, PostgreSQL, a Gemini API key, and the [Google MCP Toolbox](https://github.com/googleapis/genai-toolbox) binary (v1.4.0) saved as `agent/toolbox`.

```bash
# 1. Python environment
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2. Frontend dependencies
cd web_app_one && npm install && cd ..

# 3. Databases
createdb fifa26
for f in database/ddl/*.sql database/dml/*.sql; do psql -d fifa26 -f "$f"; done
createdb conversation_db
psql -d conversation_db -f public_API/database/schema/schema_001.sql

# 4. Configuration
cp .env.example .env   # then fill in your values

# 5. Start everything
python run.py
```

Then open http://localhost:5173.

## Known limitations and next steps

- **Shared agent memory:** The server creates one agent at startup, so its context is shared by every conversation. History is saved to Postgres but not loaded back into the agent. The fix is to create an agent per conversation from its saved history.
- **Refresh on startup only:** Scores update each time `run.py` starts, not continuously. A scheduled job would keep them current.
- **Local only:** CORS and service URLs are set for localhost.

## Tech stack

Python · Strands Agents SDK · Gemini 2.5 Flash · MCP (Google MCP Toolbox) · FastAPI · PostgreSQL · React · Vite · Radix UI
