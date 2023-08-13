import { RouterProvider, createBrowserRouter } from "react-router-dom";
import { AuthProvider, RequireAuth } from "@/components/auth";
import Dashboard from "./routes/dashboard";
import Root from "./Root";
import Lost from "./routes/404";
import Login from "./routes/login";
import ErrorBoundary from "@/components/ErrorBoundary";
import { QueryProvider } from "@/lib/query";
import Profile from "./routes/profile";
import { GroupsPage } from "./routes/groups";
import { GroupPage } from "./routes/group";

const router = createBrowserRouter([
  {
    path: "/",
    element: (
      <RequireAuth>
        <Root />
      </RequireAuth>
    ),
    ErrorBoundary: ErrorBoundary,
    children: [
      {
        path: "",
        element: <Dashboard />,
      },
      {
        path: "organization",
        children: [
          {
            path: "groups",
            element: <GroupsPage />,
          },
        ],
      },
      {
        path: "profile",
        element: <Profile />,
      },
    ],
  },
  {
    path: "login",
    ErrorBoundary: ErrorBoundary,
    element: <Login />,
  },
  {
    path: "*",
    ErrorBoundary: ErrorBoundary,
    element: <Lost />,
  },
]);

export default function Router() {
  return (
    <QueryProvider>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </QueryProvider>
  );
}
