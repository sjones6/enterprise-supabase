import { CreateOrUpdateOrganization, organizations } from "enterprise-supabase";
import { useMutation, useQueryClient } from "react-query";
import { useSupabaseClient } from "../context/SupabaseClientProvider";

export const useCreateOrganization = () => {
  const supabase = useSupabaseClient();
  const queryClient = useQueryClient();
  return useMutation(
    (organization: CreateOrUpdateOrganization) =>
      organizations(supabase).create(organization),
    {
      onSuccess() {
        queryClient.invalidateQueries({
          queryKey: ["enterprise", "organizations"],
        });
      },
      retry: false,
    }
  );
};
