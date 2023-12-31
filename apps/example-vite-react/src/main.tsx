import React from "react";
import ReactDOM from "react-dom/client";
import "enterprise-supabase-react/dist/index.css";
import "./index.css";
import Router from "./app/Router.tsx";
import ErrorBoundary from "./components/ErrorBoundary.tsx";
import { SupabaseClientProvider } from "enterprise-supabase-react";
import { supabase } from "./lib/supabase.ts";

/* eslint-disable @typescript-eslint/no-non-null-assertion */
ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <SupabaseClientProvider client={supabase}>
        <Router />
      </SupabaseClientProvider>
    </ErrorBoundary>
  </React.StrictMode>
);
