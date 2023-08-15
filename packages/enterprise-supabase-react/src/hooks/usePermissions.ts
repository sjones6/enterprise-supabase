import { PostgrestError } from "@supabase/supabase-js";
import { Permission } from "enterprise-supabase";
import { useEnterpriseSupabaseApiClient } from "../context/SupabaseClientProvider";
import { useAuth } from "../context/AuthContextProvider";
import { useQuery, UseQueryResult, UseQueryOptions } from "react-query";
import { useOrganizationContext } from "../context/OrganizationProvider";

export const usePermissionsForAuthenticatedUser = (
  options: Omit<UseQueryOptions<Permission[], PostgrestError>, "queryKey"> = {}
): UseQueryResult<Permission[], PostgrestError> => {
  const { organizations } = useEnterpriseSupabaseApiClient();
  const { primaryOrganization } = useOrganizationContext();
  const auth = useAuth();
  return useQuery<Permission[], PostgrestError>(
    ["enterprise", primaryOrganization?.id, "permissions"],
    async (): Promise<Permission[]> => {
      if (!primaryOrganization) {
        return [];
      }
      return await organizations.getPermissionsForAuthenticatedUser(
        primaryOrganization.id
      );
    },
    {
      ...options,
      enabled: !!(auth.session && primaryOrganization),
    }
  );
};
