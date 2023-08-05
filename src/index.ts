import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "database";

export function createClient<UserDB extends Database>(
  supabase: SupabaseClient<UserDB, "authz">,
) {
  return {
    getOrganizations: () => supabase.from("organizations").select(),
    getOrganizationById: (id: string) =>
      supabase.from("organizations").select().eq("id", id).maybeSingle(),
    getGroups: () => supabase.from("groups").select(),
    getGroupById: (id: string) =>
      supabase.from("groups").select().eq("id", id).maybeSingle(),
  };
}
