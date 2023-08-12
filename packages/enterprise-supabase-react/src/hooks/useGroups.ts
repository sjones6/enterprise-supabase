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

export const useCreateGroup = (
  options: UseMutationOptions<Group, PostgrestError, CreateGroup> = {}
) => {
  const queryClient = useQueryClient();
  const { groups } = useEnterpriseSupabaseApiClient();
  return useMutation((create: CreateGroup) => groups.create(create), {
    onSuccess(data, ctx, vars) {
      queryClient.invalidateQueries({
        queryKey: ["enterprise", "groups"],
      });
      options.onSuccess && options.onSuccess(data, ctx, vars);
    },
    retry: false,
    ...options,
  });
};

export const useDeleteGroup = (
  options: UseMutationOptions<unknown, PostgrestError, string> = {}
) => {
  const queryClient = useQueryClient();
  const { groups } = useEnterpriseSupabaseApiClient();
  return useMutation((groupId: string) => groups.deleteById(groupId), {
    onSuccess(data, ctx, vars) {
      queryClient.invalidateQueries({
        queryKey: ["enterprise", "groups"],
      });
      options.onSuccess && options.onSuccess(data, ctx, vars);
    },
    retry: false,
    ...options,
  });
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
  return useMutation(
    ({ groupId, update }: UpdateGroupVariable) =>
      groups.updateById(groupId, update),
    {
      ...options,
      onSuccess(data, vars, ctx) {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", "groups"],
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
      [string, string, Pagination<Group>]
    >,
    "queryKey" | "queryFn"
  > = {}
): UseQueryResult<PaginatedResponse<Group>> => {
  const { groups } = useEnterpriseSupabaseApiClient();
  return useQuery(
    ["enterprise", "groups", pagination],
    () => groups.list(pagination),
    {
      ...options,
      keepPreviousData: true,
    }
  );
};

export const useGroupById = (
  organization: string,
  options: Omit<UseQueryOptions<Group>, "queryKey"> = {}
): UseQueryResult<Group> => {
  const { groups } = useEnterpriseSupabaseApiClient();
  return useQuery(
    ["enterprise", "groups", organization],
    () => groups.getById(organization),
    options
  );
};
