from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from models import Conversation, ConversationName, Message
import conversation_repo

app = FastAPI()

#allows calls from the React frontend on port 5173
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)




#requests, (get, post, etc.. will be used to communicate with db)
#method implementations in conversation_repo.py

#home page enpoint
@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.get("/conversations/{conversation_id}")
def get_conversation(conversation_id: str):
    result = conversation_repo.see_convo(conversation_id)
    if not result:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return result

@app.get("/conversations")
def list_conversations():
    return conversation_repo.see_all_convos()

@app.post("/conversations")
def create_conversation(conversation: Conversation):
    conversation_repo.add_convo(conversation)
    return {"message": "Conversation created", "id": conversation.id}

@app.delete("/conversations/{conversation_id}")
def delete_conversation(conversation_id: str):
    conversation_repo.delete_convo(conversation_id)
    return {"message": "Deleted"}

@app.put("/conversations/{conversation_id}")
def update_conversation(conversation_id: str, conversation: Conversation):
    conversation_repo.replace_convo(conversation)
    return {"message": "Updated"}

@app.patch("/conversations/{conversation_id}/name")
def rename_conversation(conversation_id: str, body: ConversationName):
    conversation_repo.rename_convo(conversation_id, body.name)
    return {"message": "Renamed"}

