import { RouterProvider, createBrowserRouter } from "react-router-dom";
import { AuthProvider, RequireAuth } from "@/components/auth";
import Dashboard from "./routes/dashboard";
import Root from "./Root";
import Team from "./routes/team";
import Lost from "./routes/404";
import Login from "./routes/login";
import ErrorBoundary from "@/components/ErrorBoundar";

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
        path: "team",
        element: <Team />,
      },
    ],
  },
  {
    path: "login",
    element: <Login />,
  },
  {
    path: "*",
    element: <Lost />,
  },
]);

export default function Router() {
  return (
    <AuthProvider>
      <RouterProvider router={router} />
    </AuthProvider>
  );
}
