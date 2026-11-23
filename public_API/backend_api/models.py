from pydantic import BaseModel 

class Message(BaseModel):
    role: str
    content: str

class Conversation(BaseModel):
    id: str
    name: str | None = None
    messages: list[Message]

class ConversationName(BaseModel):
    name: str