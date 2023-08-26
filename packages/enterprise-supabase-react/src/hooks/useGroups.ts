/* eslint-disable @typescript-eslint/no-floating-promises */

import {
  CreateGroup,
  Group,
  PaginatedResponse,
  Pagination,
  UpdateGroup,
} from "enterprise-supabase";
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
import { useOrganizationContext } from "../context/OrganizationProvider";

type CreateGroupParam = Omit<CreateGroup, "organization_id">;

export const useCreateGroup = (
  options: UseMutationOptions<Group, PostgrestError, CreateGroupParam> = {}
) => {
  const queryClient = useQueryClient();
  const { groups } = useEnterpriseSupabaseApiClient();
  const { primaryOrganization } = useOrganizationContext();
  return useMutation(
    (create: CreateGroupParam) => {
      if (!primaryOrganization) {
        throw new Error("missing primary organization");
      }
      return groups.create({
        ...create,
        organization_id: primaryOrganization.id,
      });
    },
    {
      onSuccess(data, ctx, vars) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", primaryOrganization?.id, "groups"],
        });
        options.onSuccess && options.onSuccess(data, ctx, vars);
      },
      retry: false,
      ...options,
    }
  );
};

export const useDeleteGroup = (
  options: UseMutationOptions<unknown, PostgrestError, string> = {}
) => {
  const queryClient = useQueryClient();
  const { groups } = useEnterpriseSupabaseApiClient();
  const { primaryOrganization } = useOrganizationContext();
  return useMutation(
    (groupId: string) => {
      if (!primaryOrganization) {
        throw new Error("primary organization missing");
      }
      return groups.deleteById([primaryOrganization.id, groupId]);
    },
    {
      ...options,
      onSuccess(data, ctx, vars) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", primaryOrganization?.id, "groups"],
        });
        options.onSuccess && options.onSuccess(data, ctx, vars);
      },
      retry: false,
    }
  );
};

type UpdateGroupVariable = {
  groupId: string;
  update: UpdateGroup;
};
export const useUpdateGroup = (
  options: UseMutationOptions<Group, PostgrestError, UpdateGroupVariable> = {}
) => {
  const queryClient = useQueryClient();
  const { groups } = useEnterpriseSupabaseApiClient();
  const { primaryOrganization } = useOrganizationContext();
  return useMutation(
    ({ groupId, update }: UpdateGroupVariable) => {
      if (!primaryOrganization) {
        throw new Error("missing primary organization");
      }
      return groups.updateById([primaryOrganization.id, groupId], update);
    },
    {
      ...options,
      onSuccess(data, vars, ctx) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", primaryOrganization?.id, "groups"],
        });
        options.onSuccess && options.onSuccess(data, vars, ctx);
      },
      retry: false,
    }
  );
};

export const useGroups = (
  pagination: Pagination<Group>,
  options: Omit<
    UseQueryOptions<
      PaginatedResponse<Group>,
      PostgrestError,
      PaginatedResponse<Group>,
      [string, string | undefined, string, Pagination<Group>]
    >,
    "queryKey" | "queryFn"
  > = {}
): UseQueryResult<PaginatedResponse<Group>> => {
  const { groups } = useEnterpriseSupabaseApiClient();
  const { primaryOrganization } = useOrganizationContext();
  return useQuery(
    ["enterprise", primaryOrganization?.id, "groups", pagination],
    () => {
      if (!primaryOrganization) {
        throw new Error("missing primary organization");
      }
      return groups.list(primaryOrganization.id, pagination);
    },
    {
      ...options,
      keepPreviousData: true,
    }
  );
};

export const useGroupById = (
  groupId: string,
  options: Omit<UseQueryOptions<Group>, "queryKey"> = {}
): UseQueryResult<Group> => {
  const { groups } = useEnterpriseSupabaseApiClient();
  const { primaryOrganization } = useOrganizationContext();
  return useQuery(
    ["enterprise", primaryOrganization?.id, "groups", groupId],
    () => {
      if (!primaryOrganization) {
        throw new Error("missing primary organization");
      }
      return groups.getById([primaryOrganization.id, groupId]);
    },
    options
  );
};
