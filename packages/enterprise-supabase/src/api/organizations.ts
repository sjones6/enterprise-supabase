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
}

export class OrganizationsClient implements IOrganizationsClient {
  constructor(private supabase: EnterpriseSupabaseClient) {}

  async create(
    organization: CreateOrUpdateOrganization
  ): Promise<Organization> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .rpc("create_organization", {
          name: organization.name,
        })
        .throwOnError()
    );
  }

  async getById(organizationId: string): Promise<Organization> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .from("organizations")
        .select()
        .eq("id", organizationId)
        .maybeSingle()
        .throwOnError()
    );
  }

  async list(): Promise<Organization[]> {
    return unwrapPostgrestSingleReponse(
      await this.supabase
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
        .from("organizations")
        .update(organization)
        .eq("id", organizationId)
        .select()
        .maybeSingle()
        .throwOnError()
    );
  }

  async deleteById(organizationId: string) {
    return unwrapPostgrestSingleReponse(
      await this.supabase
        .from("organizations")
        .delete()
        .eq("id", organizationId)
        .single()
        .throwOnError()
    );
  }
}
