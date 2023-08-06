import { createContext, useContext, PropsWithChildren } from "react";
import { QueryClient, QueryClientProvider } from "react-query";
import type { EnterpriseSupabaseClient } from "../../types";

const defaultQueryClient = new QueryClient();

type SupabaseClientContext = {
  client: EnterpriseSupabaseClient;
};

const SupabaseClientProviderContext =
  createContext<SupabaseClientContext>(null);

export const SupabaseClientProvider = ({
  children,
  client,
  queryClient = defaultQueryClient,
}: PropsWithChildren<{
  client: EnterpriseSupabaseClient;
  queryClient?: QueryClient;
}>): JSX.Element => {
  return (
    <QueryClientProvider client={queryClient}>
      <SupabaseClientProviderContext.Provider value={{ client }}>
        {children}
      </SupabaseClientProviderContext.Provider>
    </QueryClientProvider>
  );
};

export const useSupabaseClient = (): EnterpriseSupabaseClient => {
  const ctx = useContext(SupabaseClientProviderContext);
  return ctx.client!;
};
