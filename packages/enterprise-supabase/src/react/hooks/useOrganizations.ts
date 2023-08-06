import { organizations } from "../../api/organizations";
import { UseQueryOptions, UseQueryResult, useQuery } from "react-query";
import { useSupabaseClient } from "../context/SupabaseClientProvider";
import { PostgrestMaybeSingleResponse, PostgrestSingleResponse } from "@supabase/supabase-js";
import { Organization } from "../../types";

export const useOrganizations = (
  options: UseQueryOptions<PostgrestSingleResponse<Organization[]>> = {}
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
  options: UseQueryOptions<PostgrestMaybeSingleResponse<Organization>> = {}
): UseQueryResult<PostgrestMaybeSingleResponse<Organization>> => {
  const supabase = useSupabaseClient();
  return useQuery(
    ["enterprise", "organizations", organization],
    () => organizations(supabase).getOrganizationById(organization),
    options
  );
};
