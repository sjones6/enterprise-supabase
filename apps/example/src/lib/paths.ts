import type { Organization } from "enterprise-supabase";

export const organization = (organization: Pick<Organization, "id">): string =>
  `/organizations/${organization.id}`;
