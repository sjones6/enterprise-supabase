import type { EnterpriseSupabaseClient, Group } from "../types";
import { PaginatedResponse, Pagination, UUID } from "./types";
import {
  calculatePagination,
  paginateResponse,
  unwrapPostgrestSingleReponse,
} from "./utils";

export type CreateGroup = Pick<
  Group,
  "name" | "description" | "organization_id"
>;

export type CompositeGroupId = [UUID, UUID];

export type UpdateGroup = Pick<Group, "name" | "description">;

export interface IGroupsClient {
  create(group: CreateGroup): Promise<Group>;
  getById(id: CompositeGroupId): Promise<Group>;
  list(
    organizationId: string,
    pagination?: Pagination<Group>
  ): Promise<PaginatedResponse<Group>>;
  updateById(id: CompositeGroupId, group: UpdateGroup): Promise<Group>;
  deleteById(id: CompositeGroupId): Promise<unknown>;
}

export class GroupsClient implements IGroupsClient {
  constructor(private supabase: EnterpriseSupabaseClient) {}

  async create(group: CreateGroup): Promise<Group> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("groups")
        .insert(group)
        .returns()
        .single()
        .throwOnError()
    );
  }

  async getById([organizationId, groupId]: CompositeGroupId): Promise<Group> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("groups")
        .select()
        .eq("organization_id", organizationId)
        .eq("id", groupId)
        .single()
        .throwOnError()
    );
  }

  async list(
    organizationId: string,
    pagination: Pagination<Group>
  ): Promise<PaginatedResponse<Group>> {
    const { from, to } = calculatePagination(pagination);
    let query = this.supabase
      .schema("authz")
      .from("groups")
      .select("*", { count: "exact" })
      .eq("organization_id", organizationId)
      .range(from, to);
    if (pagination.orderBy) {
      query = query.order(pagination.orderBy, {
        ascending: pagination.direction ? pagination.direction === "asc" : true,
      });
    }
    return paginateResponse<Group>(await query.throwOnError(), pagination);
  }

  async updateById(
    [organizationId, groupId]: CompositeGroupId,
    group: UpdateGroup
  ): Promise<Group> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("groups")
        .update(group)
        .eq("organization_id", organizationId)
        .eq("id", groupId)
        .select()
        .single()
        .throwOnError()
    );
  }

  async deleteById([organizationId, groupId]: CompositeGroupId) {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("groups")
        .delete()
        .eq("organization_id", organizationId)
        .eq("id", groupId)
        .single()
        .throwOnError()
    );
  }
}
