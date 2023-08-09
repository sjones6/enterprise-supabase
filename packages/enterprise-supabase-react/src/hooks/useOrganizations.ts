/* eslint-disable @typescript-eslint/no-floating-promises */

import { CreateOrUpdateOrganization, Organization } from "enterprise-supabase";
import {
  useMutation,
  useQueryClient,
  UseQueryOptions,
  UseQueryResult,
  useQuery,
  UseMutationOptions,
} from "react-query";
import { useEnterpriseSupabaseApiClient } from "../context/SupabaseClientProvider";
import { PostgrestError } from "@supabase/supabase-js";

export const useCreateOrganization = (
  options: UseMutationOptions<
    Organization,
    PostgrestError,
    CreateOrUpdateOrganization
  > = {}
) => {
  const queryClient = useQueryClient();
  const { organizations } = useEnterpriseSupabaseApiClient();
  return useMutation(
    (organization: CreateOrUpdateOrganization) =>
      organizations.create(organization),
    {
      onSuccess(data, ctx, vars) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", "organizations"],
        });
        options.onSuccess && options.onSuccess(data, ctx, vars);
      },
      retry: false,
      ...options,
    }
  );
};

export const useDeleteOrganization = (
  options: UseMutationOptions<unknown, PostgrestError, string> = {}
) => {
  const queryClient = useQueryClient();
  const { organizations } = useEnterpriseSupabaseApiClient();
  return useMutation(
    (organizationId: string) => organizations.deleteById(organizationId),
    {
      onSuccess(data, ctx, vars) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", "organizations"],
        });
        options.onSuccess && options.onSuccess(data, ctx, vars);
      },
      retry: false,
      ...options,
    }
  );
};

export const useSetPrimaryOrganization = (
  options: UseMutationOptions<unknown, PostgrestError, string> = {}
) => {
  const queryClient = useQueryClient();
  const { organizations } = useEnterpriseSupabaseApiClient();
  return useMutation(
    (organizationId: string) =>
      organizations.setActiveOrganization(organizationId),
    {
      onSuccess(data, ctx, vars) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", "organizations"],
        });
        options.onSuccess && options.onSuccess(data, ctx, vars);
      },
      retry: false,
      ...options,
    }
  );
};

type UpdateOrganizationVariable = {
  organizationId: string;
  update: CreateOrUpdateOrganization;
};
export const useUpdateOrganization = (
  options: UseMutationOptions<
    Organization,
    PostgrestError,
    UpdateOrganizationVariable
  > = {}
) => {
  const queryClient = useQueryClient();
  const { organizations } = useEnterpriseSupabaseApiClient();
  return useMutation(
    ({ organizationId, update }: UpdateOrganizationVariable) =>
      organizations.updateById(organizationId, update),
    {
      ...options,
      onSuccess(data, vars, ctx) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", "organizations"],
        });
        options.onSuccess && options.onSuccess(data, vars, ctx);
      },
      retry: false,
    }
  );
};

export const useOrganizations = (
  options: Omit<UseQueryOptions<Organization[]>, "queryKey"> = {}
): UseQueryResult<Organization[]> => {
  const { organizations } = useEnterpriseSupabaseApiClient();
  return useQuery(
    ["enterprise", "organizations"],
    () => organizations.list(),
    options
  );
};

export const useOrganizationById = (
  organization: string,
  options: Omit<UseQueryOptions<Organization>, "queryKey"> = {}
): UseQueryResult<Organization> => {
  const { organizations } = useEnterpriseSupabaseApiClient();
  return useQuery(
    ["enterprise", "organizations", organization],
    () => organizations.getById(organization),
    options
  );
};
