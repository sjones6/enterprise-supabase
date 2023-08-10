import type { EnterpriseSupabaseClient, Organization } from "../types";
import { unwrapPostgrestSingleReponse } from "./utils";

export type CreateOrUpdateOrganization = {
  name: string;
};

export interface IOrganizationsClient {
  create(organization: CreateOrUpdateOrganization): Promise<Organization>;
  getById(organizationId: string): Promise<Organization>;
  list(): Promise<Organization[]>;
  updateById(
    organizationId: string,
    organization: CreateOrUpdateOrganization
  ): Promise<Organization>;
  deleteById(organizationId: string): Promise<unknown>;
  setActiveOrganization(organizationId: string): Promise<void>;
}

export class OrganizationsClient implements IOrganizationsClient {
  constructor(private supabase: EnterpriseSupabaseClient) {}

  async create(
    organization: CreateOrUpdateOrganization
  ): Promise<Organization> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .rpc("create_organization", {
          name: organization.name,
        })
        .throwOnError()
    );
  }

  async getById(organizationId: string): Promise<Organization> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("organizations")
        .select()
        .eq("id", organizationId)
        .single()
        .throwOnError()
    );
  }

  async list(): Promise<Organization[]> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("organizations")
        .select()
        .order("name", {
          ascending: true,
        })
        .throwOnError()
    );
  }

  async updateById(
    organizationId: string,
    organization: CreateOrUpdateOrganization
  ): Promise<Organization> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("organizations")
        .update(organization)
        .eq("id", organizationId)
        .select()
        .single()
        .throwOnError()
    );
  }

  async deleteById(organizationId: string) {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .schema("authz")
        .from("organizations")
        .delete()
        .eq("id", organizationId)
        .single()
        .throwOnError()
    );
  }

  async setActiveOrganization(organizationId: string): Promise<void> {
    await this.supabase
      .schema("authz")
      .rpc("set_active_organization", {
        active_organization_id: organizationId,
      })
      .throwOnError();
    await this.supabase.auth.refreshSession();
  }
}
