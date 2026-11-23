import { Flex, Box, Button, Text, ScrollArea, ContextMenu } from "@radix-ui/themes";
import { PlusIcon } from "@radix-ui/react-icons";

export default function Sidebar({ conversations, activeId, onSelect, onNew, onDelete, onRename }) {
  return (
    <Flex
      direction="column"
      style={{ width: 220, borderRight: "1px solid var(--gray-5)", height: "100vh" }}
    >
      {/* New conversation button at the top */}
      <Box p="3" style={{ borderBottom: "1px solid var(--gray-5)" }}>
        <Button onClick={onNew} style={{ width: "100%" }}>
          <PlusIcon /> New Chat
        </Button>
      </Box>

      {/* Scrollable list of conversations - right click for options */}
      <ScrollArea style={{ flex: 1 }}>
        <Flex direction="column" p="2" gap="1">
          {conversations.map(({ id, name }) => (
            <ContextMenu.Root key={id}>

              {/* The conversation button is the right-click target */}
              <ContextMenu.Trigger>
                <Button
                  variant={id === activeId ? "solid" : "ghost"}
                  style={{
                    width: "100%",
                    height: "auto",
                    minHeight: 40,
                    padding: "10px 12px",
                    justifyContent: "flex-start",
                  }}
                  onClick={() => onSelect(id)}
                >
                  <Text
                    size="2"
                    style={{
                      display: "block",
                      width: "100%",
                      textAlign: "left",
                      whiteSpace: "nowrap",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                    }}
                  >
                    {name || id}
                  </Text>
                </Button>
              </ContextMenu.Trigger>

              {/* Menu that appears on right-click */}
              <ContextMenu.Content>
                <ContextMenu.Item onClick={() => onRename(id)}>
                  Rename
                </ContextMenu.Item>
                <ContextMenu.Separator />
                <ContextMenu.Item color="red" onClick={() => onDelete(id)}>
                  Delete
                </ContextMenu.Item>
              </ContextMenu.Content>

            </ContextMenu.Root>
          ))}
        </Flex>
      </ScrollArea>
    </Flex>
  );
}
