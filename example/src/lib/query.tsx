import type { PropsWithChildren } from "react";
import { QueryClient, QueryClientProvider } from "react-query";

export const queryClient = new QueryClient();

export const QueryProvider = ({
  children,
}: PropsWithChildren<{}>): JSX.Element => (
  <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
);
