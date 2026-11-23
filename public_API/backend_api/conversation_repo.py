import os
import psycopg
from dotenv import load_dotenv
from models import Conversation, Message

#uvicorn app:app --reload --port 8001
#http://localhost:8001/docs

#connection string for the conversation history database comes from .env
load_dotenv()
DB_URL = os.getenv("CONVERSATION_DB_URL", "dbname=conversation_db host=localhost")


#methods that take a conversation, execute SQL and return as needed
def see_convo(conversation_id: str):
    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name FROM conversations WHERE id = %s", (conversation_id,))
            convo = cur.fetchone()
            if not convo:
                return None
            cur.execute(
                "SELECT role, content FROM messages WHERE conversation_id = %s ORDER BY created_at ASC",
                (conversation_id,)
            )
            msgs = [{"role": row[0], "content": row[1]} for row in cur.fetchall()]
            return {"id": convo[0], "name": convo[1], "messages": msgs}

def see_all_convos():
    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name FROM conversations ORDER BY created_at DESC")
            rows = cur.fetchall()
            return [{"id": row[0], "name": row[1]} for row in rows]

def add_convo(conversation: Conversation):
    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO conversations (id, name) VALUES (%s, %s)",
                (conversation.id, conversation.name)
            )
            for msg in conversation.messages:
                cur.execute(
                    "INSERT INTO messages (conversation_id, role, content) VALUES (%s, %s, %s)",
                    (conversation.id, msg.role, msg.content))
            conn.commit()

def rename_convo(conversation_id: str, name: str):
    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE conversations SET name = %s WHERE id = %s",
                (name, conversation_id)
            )
            conn.commit()

def delete_convo(conversation_id: str):
    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM conversations WHERE id = %s", (conversation_id,))
            conn.commit()

def replace_convo(conversation: Conversation):
    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM messages WHERE conversation_id = %s", (conversation.id,))
            for msg in conversation.messages:
                cur.execute(
                    "INSERT INTO messages (conversation_id, role, content) VALUES (%s, %s, %s)",
                    (conversation.id, msg.role, msg.content)
                )
            conn.commit()