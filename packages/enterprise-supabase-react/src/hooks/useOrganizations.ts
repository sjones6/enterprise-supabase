import { organizations } from "enterprise-supabase";
import type { Organization } from "enterprise-supabase";
import { UseQueryOptions, UseQueryResult, useQuery } from "react-query";
import { useSupabaseClient } from "../context/SupabaseClientProvider";
import { PostgrestMaybeSingleResponse, PostgrestSingleResponse } from "@supabase/supabase-js";

export const useOrganizations = (
  options: Omit<UseQueryOptions<PostgrestSingleResponse<Organization[]>>, 'queryKey'> = {}
): UseQueryResult<PostgrestSingleResponse<Organization[]>> => {
  const supabase = useSupabaseClient();
  return useQuery(
    ["enterprise", "organizations"],
    () => organizations(supabase).listOrganizations(),
    options
  );
};

export const useOrganizationById = (
  organization: string,
  options: Omit<UseQueryOptions<PostgrestMaybeSingleResponse<Organization>>, 'queryKey'> = {}
): UseQueryResult<PostgrestMaybeSingleResponse<Organization>> => {
  const supabase = useSupabaseClient();
  return useQuery(
    ["enterprise", "organizations", organization],
    () => organizations(supabase).getOrganizationById(organization),
    options
  );
};
