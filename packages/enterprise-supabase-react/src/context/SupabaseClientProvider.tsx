import { createContext, useContext, PropsWithChildren, useMemo } from "react";
import { QueryClient, QueryClientProvider } from "react-query";
import {
  createApi,
  type EnterpriseSupabaseAPIClient,
  type EnterpriseSupabaseClient,
} from "enterprise-supabase";
import { AuthContextProvider } from "./AuthContextProvider";
import { OrganizationProvider } from "./OrganizationProvider";

const defaultQueryClient = new QueryClient();

type SupabaseClientContext = {
  client: EnterpriseSupabaseClient;
  apiClient: EnterpriseSupabaseAPIClient;
};

const SupabaseClientProviderContext =
  createContext<SupabaseClientContext | null>(null);

export const SupabaseClientProvider = ({
  children,
  client,
  queryClient = defaultQueryClient,
}: PropsWithChildren<{
  client: EnterpriseSupabaseClient;
  queryClient?: QueryClient;
}>): JSX.Element => {
  const apiClient = useMemo(() => createApi(client), [client]);
  return (
    <QueryClientProvider client={queryClient}>
      <SupabaseClientProviderContext.Provider value={{ client, apiClient }}>
        <AuthContextProvider>
          <OrganizationProvider>{children}</OrganizationProvider>
        </AuthContextProvider>
      </SupabaseClientProviderContext.Provider>
    </QueryClientProvider>
  );
};

export const useSupabaseClient = (): EnterpriseSupabaseClient => {
  const ctx = useContext(SupabaseClientProviderContext);
  if (!ctx) {
    console.error(
      "Please be sure to wrap all elements in a <SupabaseClientProvider client={supabase}> context"
    );
    throw new Error("Missing SupabaseClientProvider context");
  }
  return ctx.client;
};

export const useEnterpriseSupabaseApiClient =
  (): EnterpriseSupabaseAPIClient => {
    const ctx = useContext(SupabaseClientProviderContext);
    if (!ctx) {
      console.error(
        "Please be sure to wrap all elements in a <SupabaseClientProvider client={supabase}> context"
      );
      throw new Error("Missing SupabaseClientProvider context");
    }
    return ctx.apiClient;
  };
