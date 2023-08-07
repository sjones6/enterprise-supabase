import slugify from "slugify";
import type { EnterpriseSupabaseClient, Role } from "../types";
import { unwrapPostgrestSingleReponse } from "./utils";

export type CreateOrUpdateRole = {
  name: string;
  description?: string;
  organization_id: string;
};

export interface IRolesClient {
  create(role: CreateOrUpdateRole): Promise<Role>;
  getById(groupId: string): Promise<Role>;
  list(): Promise<Role[]>;
  updateById(groupId: string, role: CreateOrUpdateRole): Promise<Role>;
  deleteById(groupId: string): Promise<unknown>;
}

export class RolesClient implements IRolesClient {
  constructor(private supabase: EnterpriseSupabaseClient) {}

  private slugify(str: string): string {
    return slugify(str, {
      strict: true,
      lower: true,
      trim: true,
    });
  }

  async create(role: CreateOrUpdateRole): Promise<Role> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .from("roles")
        .insert({
          ...role,
          slug: this.slugify(role.name),
        })
        .returns()
        .single()
        .throwOnError()
    );
  }

  async getById(groupId: string): Promise<Role> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .from("roles")
        .select()
        .eq("id", groupId)
        .maybeSingle()
        .throwOnError()
    );
  }

  async list(): Promise<Role[]> {
    return unwrapPostgrestSingleReponse(
      await this.supabase.from("roles").select().throwOnError()
    );
  }

  async updateById(roleId: string, role: CreateOrUpdateRole): Promise<Role> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .from("roles")
        .update({
          ...role,
          slug: this.slugify(role.name),
        })
        .eq("id", roleId)
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
