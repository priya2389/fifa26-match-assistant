import { Flex, Box, Text, Button, ScrollArea, Card, TextField } from "@radix-ui/themes";
import { useState } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

//uvicorn agent_server:app --reload --port 8000

//turns the first user query into a short sidebar title, e.g. first sentence capped at 40 chars
function summarize(text, maxLen = 40) {
  const firstSentence = text.match(/^[^.?!]*[.?!]?/)[0].trim();
  const base = firstSentence || text;
  return base.length > maxLen ? base.slice(0, maxLen).trim() + "…" : base;
}

//chat area component - receives messages from chat_page, sends new ones to the agent
export default function Conversations({ messages, setMessages, activeId, isDraft, onSaved }) {
    const [input, setInput] = useState("");
    const [isLoading, setIsLoading] = useState(false);

    async function sendMessage() {
    {/* Trim whitespace, check if input is empty, and check a conversation is selected */}
    const text = input.trim();
    if (!text || isLoading || !activeId) return;

    {/* Name the conversation off the first query, before it's added to messages */}
    const isFirstMessage = messages.length === 0;

    {/* Build updated messages array explicitly so we can send it to the DB */}
    const userMessage = { role: "user", content: text };
    const updatedMessages = [...messages, userMessage];

    {/* Show user message immediately and clear input */}
    setMessages(updatedMessages);
    setInput("");
    setIsLoading(true);

    if (isFirstMessage) {
      {/* Drafts don't exist in the DB yet - create the row now that there's something to save */}
      const name = summarize(text);
      if (isDraft) {
        await fetch("http://localhost:8001/conversations", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ id: activeId, name, messages: [] }),
        });
      } else {
        await fetch(`http://localhost:8001/conversations/${activeId}/name`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name }),
        });
      }
      onSaved?.(activeId, name);
    }

    {/* Actual API call to agent_server */}
    try {
      {/* Send message to agent and wait for response */}
      const res = await fetch("http://localhost:8000/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: text }),
      });

      {/* Build final messages array with agent reply */}
      const data = await res.json();
      const agentMessage = { role: "agent", content: data.response };
      const finalMessages = [...updatedMessages, agentMessage];

      {/* Update UI */}
      setMessages(finalMessages);

      {/* Save full conversation to DB so it persists when switching or refreshing */}
      await fetch(`http://localhost:8001/conversations/${activeId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: activeId, messages: finalMessages }),
      });

    } catch (err) {
      setMessages((prev) => [...prev, { role: "agent", content: "Error: could not reach the server." }]);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    //Flex is the main container, fills remaining space after the sidebar
    <Flex direction="column" style={{ flex: 1 }}>

      {/* Box for the header, padded and bordered */}
      <Box p="3" style={{ borderBottom: "1px solid var(--gray-5)" }}>
        <Text size="4" weight="bold">FIFA 26 Agent</Text>
      </Box>

      {/* Scrollable box for the message area */}
      <ScrollArea style={{ flex: 1 }}>
        <Box p="4">
            {/* Messages saved after each rendering, turns each message into a card */}
            {/* Align to the right(user) or left(agent) */}
          {messages.map((msg, index) => (
            <Flex key={index} justify={msg.role === "user" ? "end" : "start"} mb="3">
                <Card style={{ maxWidth: "70%" }}>
                    {msg.role === "user" ? (
                      <Text size="2">{msg.content}</Text>
                    ) : (
                      <div className="markdown-message">
                      {/* used markdown-message for better formatting */}
                        <ReactMarkdown remarkPlugins={[remarkGfm]}>{msg.content}</ReactMarkdown>
                      </div>
                    )}
                </Card>
            </Flex>
          ))}
        </Box>
      </ScrollArea>

      {/* Box for the user input area at the bottom */}
      <Box p="3" style={{ borderTop: "1px solid var(--gray-5)" }}>
        <Flex gap="2">
            <TextField.Root
            size="3"
            style={{ flex: 1 }}
            placeholder="Ask about matches..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter") sendMessage(); }}
            />
            {/* Calls sendMessage on click */}
            <Button size="3" onClick={sendMessage} disabled={isLoading}>
              {isLoading ? "Thinking..." : "Send"}
            </Button>
        </Flex>
      </Box>

    </Flex>
  );
}
