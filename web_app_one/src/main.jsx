//what connects react to root index to render component
import React from "react";
import ReactDOM from "react-dom/client";
import { Theme } from "@radix-ui/themes";
import "@radix-ui/themes/styles.css";
import ChatPage from "./chat_page.jsx";

//Imports a component and renders it in the root index.html (entry point for vite that loads main -->component)
ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <Theme
      accentColor="iris"
      grayColor="slate"
      radius="large"
      panelBackground="translucent"
      scaling="100%"
    >
      <ChatPage />
    </Theme>
  </React.StrictMode>
);
