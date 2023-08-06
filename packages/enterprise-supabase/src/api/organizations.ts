import type {
  PostgrestMaybeSingleResponse,
  PostgrestSingleResponse,
} from "@supabase/supabase-js";
import type { EnterpriseSupabaseClient, Organization } from "../types";

export type CreateOrUpdateOrganization = {
  name: string;
};

export const organizations = (supabase: EnterpriseSupabaseClient) => ({
  async create(
    organization: CreateOrUpdateOrganization
  ): Promise<PostgrestSingleResponse<Organization>> {
    return await supabase.rpc("create_organization", {
      name: organization.name,
    });
  },
  async getOrganizationById(
    organizationId: string
  ): Promise<PostgrestMaybeSingleResponse<Organization>> {
    return await supabase
      .from("organizations")
      .select()
      .eq("id", organizationId)
      .maybeSingle();
  },
  async listOrganizations(): Promise<PostgrestSingleResponse<Organization[]>> {
    return await supabase.from("organizations").select().throwOnError();
  },
  async updateOrganization(
    organizationId: string,
    organization: CreateOrUpdateOrganization
  ): Promise<PostgrestSingleResponse<Organization>> {
    return await supabase
      .from("organizations")
      .update(organization)
      .eq("id", organizationId)
      .select()
      .single()
      .throwOnError();
  },
  async deleteOrganization(organizationId: string) {
    return await supabase
      .from("organizations")
      .delete()
      .eq("id", organizationId)
      .single()
      .throwOnError();
  },
});
