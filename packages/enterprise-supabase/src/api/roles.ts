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
  getById(roleId: string): Promise<Role>;
  list(): Promise<Role[]>;
  updateById(roleId: string, role: CreateOrUpdateRole): Promise<Role>;
  deleteById(roleId: string): Promise<unknown>;
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
        .schema("authz")
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

  async getById(roleId: string): Promise<Role> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("roles")
        .select()
        .eq("id", roleId)
        .single()
        .throwOnError()
    );
  }

  async list(): Promise<Role[]> {
    return unwrapPostgrestSingleReponse(
      await this.supabase.schema("authz").from("roles").select().throwOnError()
    );
  }

  async updateById(roleId: string, role: CreateOrUpdateRole): Promise<Role> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
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

  async deleteById(roleId: string) {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("roles")
        .delete()
        .eq("id", roleId)
        .single()
        .throwOnError()
    );
  }
}
