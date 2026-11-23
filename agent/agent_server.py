from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from dotenv import load_dotenv
from mcp import StdioServerParameters, stdio_client
from strands import Agent
from strands.models.gemini import GeminiModel
from strands.tools.mcp import MCPClient
from strands_tools import calculator, current_time
from mcp.client.streamable_http import streamable_http_client
from contextlib import asynccontextmanager

load_dotenv()


TOOLBOX_URL = "http://127.0.0.1:5000/mcp"

#initializing the "global" agent shared across all requests
chat_agent = None


def load_model():
    return GeminiModel(
        client_args={"api_key": os.getenv("GOOGLE_API_KEY")},
        model_id="gemini-2.5-flash",
        params={"temperature": 0.7, "max_output_tokens": 2048},
    )

# notes that the function below give instructions for what to do when the server starts and stops 
@asynccontextmanager
async def lifespan(app: FastAPI):
    global chat_agent

    #when the server starts create the agent once
    file_reader_client = MCPClient(
        lambda: stdio_client(StdioServerParameters(command="npx", args=["-y", "mcp-file-reader"]))
    )
    toolbox_client = MCPClient(lambda: streamable_http_client(TOOLBOX_URL))

    with file_reader_client:
        with toolbox_client:
            file_reader_tools = file_reader_client.list_tools_sync()
            toolbox_tools = toolbox_client.list_tools_sync()
            chat_agent = Agent(
                model=load_model(),
                tools=[calculator, current_time, *file_reader_tools, *toolbox_tools],
            )
            
            yield  #pauses the start/shutdown sequence, area where the server runs 

            #shutdown code here, (not necesarily needed because of the "with" statements above)
            print("Server is shutting down, cleaning up...")


#creates a FastAPI app/server instance and tells it to use the defined open/close routine above
app = FastAPI(lifespan=lifespan)

#allows calls from frontend (vite/react app) to the backend (this server)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

#predefined shape using pydantic for API call input validation
class ChatRequest(BaseModel):
    message: str


#a function that call be called by frontend, 
@app.post("/chat")
def chat(request: ChatRequest):
    result = chat_agent(request.message)  #call the agent using user input
    return {"response": str(result)} #send the answer back as JSON to frontend
