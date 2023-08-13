import type { Group, Organization } from "enterprise-supabase";

export const organization = (organization: Pick<Organization, "id">): string =>
  `/organizations/${organization.id}`;

export const group = (group: Pick<Group, "id">): string =>
  `/organization/groups/${group.id}`;
