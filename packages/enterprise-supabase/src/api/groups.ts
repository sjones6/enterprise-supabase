import type { EnterpriseSupabaseClient, Group } from "../types";
import { unwrapPostgrestSingleReponse } from "./utils";

export type CreateOrUpdateGroup = {
  name: string;
  description?: string;
  organization_id: string;
};

export interface IGroupsClient {
  create(group: CreateOrUpdateGroup): Promise<Group>;
  getById(groupId: string): Promise<Group>;
  list(): Promise<Group[]>;
  updateById(groupId: string, group: CreateOrUpdateGroup): Promise<Group>;
  deleteById(groupId: string): Promise<unknown>;
}

export class GroupsClient implements IGroupsClient {
  constructor(private supabase: EnterpriseSupabaseClient) {}

  async create(group: CreateOrUpdateGroup): Promise<Group> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
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
        .from("groups")
        .select()
        .eq("id", organizationId)
        .maybeSingle()
        .throwOnError()
    );
  }

  async list(): Promise<Group[]> {
    return unwrapPostgrestSingleReponse(
      await this.supabase.from("groups").select().throwOnError()
    );
  }

  async updateById(
    groupId: string,
    group: CreateOrUpdateGroup
  ): Promise<Group> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
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
        .from("groups")
        .delete()
        .eq("id", groupId)
        .single()
        .throwOnError()
    );
  }
}
