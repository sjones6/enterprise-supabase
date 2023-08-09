import type { PropsWithChildren } from "react";
import { QueryClient, QueryClientProvider } from "react-query";

const queryClient = new QueryClient();

export const QueryProvider = ({
  children,
}: PropsWithChildren<Record<string, never>>): JSX.Element => (
  <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
);
