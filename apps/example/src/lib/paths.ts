import { Organization } from "supabase-enterprise/types";

export const organization = (organization: Pick<Organization, "id">): string =>
  `/organizations/${organization.id}`;
