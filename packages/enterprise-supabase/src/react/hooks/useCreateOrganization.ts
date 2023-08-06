import {
  CreateOrUpdateOrganization,
  organizations,
} from "../../api/organizations";
import { useMutation, useQueryClient } from "react-query";
import { useSupabaseClient } from "../context/SupabaseClientProvider";

export const useCreateOrganization = () => {
  const supabase = useSupabaseClient();
  const queryClient = useQueryClient();
  return useMutation(
    (organization: CreateOrUpdateOrganization) =>
      organizations(supabase).create(organization),
    {
      onMutate() {
        queryClient.invalidateQueries(["enterprise", "organizations"]);
      },
      retry: false,
    }
  );
};
