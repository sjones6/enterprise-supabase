import { EnterpriseSupabaseClient } from "../types";
import { GroupsClient, IGroupsClient } from "./groups";
import { IOrganizationsClient, OrganizationsClient } from "./organizations";
import { IRolesClient, RolesClient } from "./roles";

export { OrganizationsClient } from "./organizations";
export type {
  CreateOrUpdateOrganization,
  IOrganizationsClient,
} from "./organizations";

export { RolesClient } from "./roles";
export type { CreateOrUpdateRole, IRolesClient } from "./roles";

export { GroupsClient } from "./groups";
export type { CreateOrUpdateGroup, IGroupsClient } from "./groups";

export type EnterpriseSupabaseAPIClient = {
  organizations: IOrganizationsClient;
  groups: IGroupsClient;
  roles: IRolesClient;
};

export const createApi = (
  supabase: EnterpriseSupabaseClient
): EnterpriseSupabaseAPIClient => {
  return {
    organizations: new OrganizationsClient(supabase),
    groups: new GroupsClient(supabase),
    roles: new RolesClient(supabase),
  };
};
