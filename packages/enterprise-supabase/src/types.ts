import { SupabaseClient } from "@supabase/supabase-js";
import { Database } from "./database";

export type EnterpriseSupabaseClient = SupabaseClient<Database>;

type Tables = Database["authz"]["Tables"];

export type Group = Tables["groups"]["Row"];
export type GroupMember = Tables["group_members"]["Row"];
export type Organization = Tables["organizations"]["Row"];
export type OrganizationMember = Tables["members"]["Row"];
export type Permission = Tables["permissions"]["Row"];
export type Role = Tables["roles"]["Row"];
