import React from "react";
import ReactDOM from "react-dom/client";
import "./index.css";
import Router from "./app/Router.tsx";
import ErrorBoundary from "./components/ErrorBoundar.tsx";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <Router />
    </ErrorBoundary>
  </React.StrictMode>,
);
