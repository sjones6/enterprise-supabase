import { GroupsPage as EnterpriseGroupsPage } from "enterprise-supabase-react";
import { useNavigate } from "react-router";
import * as paths from "@/lib/paths";
import { useCallback } from "react";
import { Group } from "enterprise-supabase";

export const GroupsPage = (): JSX.Element => {
  const navigate = useNavigate();
  const toGroup = useCallback(
    (group: Group) => {
      navigate(paths.group(group));
    },
    [navigate]
  );
  return <EnterpriseGroupsPage onEditGroup={toGroup} onCreateGroup={toGroup} />;
};
