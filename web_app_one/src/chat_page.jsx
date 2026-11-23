import { useState, useEffect } from "react";
import { Flex } from "@radix-ui/themes";
import Sidebar from "./sidebar";
import Conversations from "./conversations";

const API = "http://localhost:8001";

export default function ChatPage() {
  // each entry is { id, name }
  const [conversations, setConversations] = useState([]);
  const [activeId, setActiveId] = useState(null);
  const [messages, setMessages] = useState([]);
  // true once the active conversation is only a local draft, not yet saved to the DB
  const [isDraft, setIsDraft] = useState(false);

  // Fetch all conversations once on load, then open somewhere sensible:
  // a fresh unnamed draft if there's nothing yet, otherwise the most recent conversation.
  useEffect(() => {
    fetch(`${API}/conversations`)
      .then(res => res.json())
      .then(data => {
        setConversations(data);
        if (data.length === 0) {
          handleNew();
        } else {
          setActiveId(data[0].id);
          setIsDraft(false);
        }
      });
  }, []);

  // Fetch messages whenever the active conversation changes (skip for unsaved drafts)
  useEffect(() => {
    if (!activeId || isDraft) return;
    fetch(`${API}/conversations/${activeId}`)
      .then(res => res.json())
      .then(data => setMessages(data.messages || []));
  }, [activeId, isDraft]);

  function handleSelect(id) {
    setActiveId(id);
    setIsDraft(false);
  }

  function handleNew() {
    const id = `conv_${Date.now()}`;
    setActiveId(id);
    setIsDraft(true);
    setMessages([]);
  }

  // Called by Conversations once the first message actually persists the draft
  function handleSaved(id, name) {
    setConversations(prev =>
      prev.some(c => c.id === id)
        ? prev.map(c => (c.id === id ? { ...c, name } : c))
        : [{ id, name }, ...prev]
    );
    setIsDraft(false);
  }

  async function handleRename(id) {
    const current = conversations.find(c => c.id === id);
    const newName = window.prompt("Rename conversation:", current?.name || id);
    if (newName && newName.trim()) {
      const name = newName.trim();
      await fetch(`${API}/conversations/${id}/name`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name }),
      });
      setConversations(prev => prev.map(c => (c.id === id ? { ...c, name } : c)));
    }
  }

  async function handleDelete(id) {
    await fetch(`${API}/conversations/${id}`, { method: "DELETE" });
    const remaining = conversations.filter(c => c.id !== id);
    setConversations(remaining);
    if (activeId === id) {
      if (remaining.length > 0) {
        setActiveId(remaining[0].id);
        setIsDraft(false);
      } else {
        handleNew();
      }
    }
  }

  return (
    <Flex style={{ height: "100vh" }}>
      <Sidebar
        conversations={conversations}
        activeId={activeId}
        onSelect={handleSelect}
        onNew={handleNew}
        onDelete={handleDelete}
        onRename={handleRename}
      />
      <Conversations
        messages={messages}
        setMessages={setMessages}
        activeId={activeId}
        isDraft={isDraft}
        onSaved={handleSaved}
      />
    </Flex>
  );
}