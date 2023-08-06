import React from "react";
import ReactDOM from "react-dom/client";
import "./index.css";
import Router from "./app/Router.tsx";
import ErrorBoundary from "./components/ErrorBoundary.tsx";
import { SupabaseClientProvider } from "enterprise-supabase";
import { supabase } from "./lib/supabase.ts";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <SupabaseClientProvider client={supabase}>
        <Router />
      </SupabaseClientProvider>
    </ErrorBoundary>
  </React.StrictMode>
);
