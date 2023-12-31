import { createContext, useContext, PropsWithChildren, useMemo } from "react";
import { QueryClient, QueryClientProvider } from "react-query";
import {
  createApi,
  type EnterpriseSupabaseAPIClient,
  type EnterpriseSupabaseClient,
} from "enterprise-supabase";
import { AuthContextProvider } from "./AuthContextProvider";
import { OrganizationProvider } from "./OrganizationProvider";
import { SettingsContextValueProp, SettingsProvider } from "./SettingsProvider";
import { PermissionsProvider } from "./PermissionsContext";

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
  settings,
}: PropsWithChildren<{
  client: EnterpriseSupabaseClient;
  queryClient?: QueryClient;
  settings?: SettingsContextValueProp;
}>): JSX.Element => {
  const apiClient = useMemo(() => createApi(client), [client]);
  return (
    <SettingsProvider {...settings}>
      <QueryClientProvider client={queryClient}>
        <SupabaseClientProviderContext.Provider value={{ client, apiClient }}>
          <AuthContextProvider>
            <OrganizationProvider>
              <PermissionsProvider>{children}</PermissionsProvider>
            </OrganizationProvider>
          </AuthContextProvider>
        </SupabaseClientProviderContext.Provider>
      </QueryClientProvider>
    </SettingsProvider>
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
