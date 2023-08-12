import type { EnterpriseSupabaseClient, Group } from "../types";
import { PaginatedResponse, Pagination } from "./types";
import {
  calculatePagination,
  paginateResponse,
  unwrapPostgrestSingleReponse,
} from "./utils";

export type CreateGroup = Pick<
  Group,
  "name" | "description" | "organization_id"
>;

export type UpdateGroup = Pick<Group, "name" | "description">;

export interface IGroupsClient {
  create(group: CreateGroup): Promise<Group>;
  getById(groupId: string): Promise<Group>;
  list(pagination?: Pagination<Group>): Promise<PaginatedResponse<Group>>;
  updateById(groupId: string, group: UpdateGroup): Promise<Group>;
  deleteById(groupId: string): Promise<unknown>;
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

  async getById(organizationId: string): Promise<Group> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("groups")
        .select()
        .eq("id", organizationId)
        .single()
        .throwOnError()
    );
  }

  async list(pagination: Pagination<Group>): Promise<PaginatedResponse<Group>> {
    const { from, to } = calculatePagination(pagination);
    let query = this.supabase
      .schema("authz")
      .from("groups")
      .select("*", { count: "exact" })
      .range(from, to);
    if (pagination.orderBy) {
      query = query.order(pagination.orderBy, {
        ascending: pagination.direction ? pagination.direction === "asc" : true,
      });
    }
    return paginateResponse<Group>(await query.throwOnError(), pagination);
  }

  async updateById(groupId: string, group: UpdateGroup): Promise<Group> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("groups")
        .update(group)
        .eq("id", groupId)
        .select()
        .single()
        .throwOnError()
    );
  }

  async deleteById(groupId: string) {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("groups")
        .delete()
        .eq("id", groupId)
        .single()
        .throwOnError()
    );
  }
}
