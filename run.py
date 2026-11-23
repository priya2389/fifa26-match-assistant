import subprocess
import signal
import sys
import time
from pathlib import Path

#defining directories (relative to this file so the repo runs from any location)
BASE = str(Path(__file__).resolve().parent)
UVICORN = f"{BASE}/.venv/bin/uvicorn"
PYTHON = f"{BASE}/.venv/bin/python"

#tracks running processes
processes = []

#pulls latest World Cup scores/standings before the servers start - non-fatal if it fails
#(e.g. no network), since the app should still start with whatever data is already there
def refresh_database():
    for script in ["update_scores.py", "resolve_group_stage.py"]:
        print(f"Refreshing database: {script}")
        result = subprocess.run([PYTHON, f"data_sync/{script}"], cwd=BASE)
        if result.returncode != 0:
            print(f"WARNING: {script} exited with code {result.returncode}, continuing anyway")

#shutdown definition
def shutdown(sig=None, frame=None):
    print("\nShutting down all servers...")
    for p in processes:
        p.terminate()
    for p in processes:
        try:
            p.wait(timeout=5)
        except subprocess.TimeoutExpired:
            p.kill()
    sys.exit(0)

#shutdown functions occur on ctr+c or termination signal
signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)

#list of commands to run (the servers)
commands = [
    {
        "label": "Toolbox",
        "cmd": ["./toolbox", "--config", "tools.yaml"],
        "cwd": f"{BASE}/agent",
    },
    {
        "label": "Agent server (port 8000)",
        "cmd": [UVICORN, "agent_server:app", "--reload", "--port", "8000"],
        "cwd": f"{BASE}/agent",
        "delay": 2,  # wait for toolbox to be ready
    },
    {
        "label": "Public API (port 8001)",
        "cmd": [UVICORN, "app:app", "--reload", "--port", "8001"],
        "cwd": f"{BASE}/public_API/backend_api",
        "delay": 2,
    },
    {
        "label": "Frontend (npm dev)",
        "cmd": ["npm", "run", "dev"],
        "cwd": f"{BASE}/web_app_one",
    },
]

#refreshes everytime the servers start, can automate this to daily later if needed
refresh_database()

#starting the servers
for entry in commands:
    delay = entry.get("delay", 0)
    if delay:
        time.sleep(delay)
    print(f"Starting: {entry['label']}")
    p = subprocess.Popen(entry["cmd"], cwd=entry["cwd"])
    processes.append(p)

print("\nAll servers running. Press Ctrl+C to stop.\n")

#if any process exits unexpectedly, shut down all processes
while True:
    for p in processes:
        if p.poll() is not None:
            print(f"A process exited unexpectedly (pid {p.pid}). Shutting down.")
            shutdown()
    time.sleep(2)


#cd agent
#./toolbox --config tools.yaml


#cd agent
#source ../.venv/bin/activate
#uvicorn agent_server:app --reload --port 8000

#cd public_API/backend_api
#source ../../.venv/bin/activate
#uvicorn app:app --reload --port 8001

#cd web_app_one
#npm run dev
