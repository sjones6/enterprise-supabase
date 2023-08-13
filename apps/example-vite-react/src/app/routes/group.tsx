import { useParams } from "react-router";
import { GroupPage as EnterpriseGroupPage } from "enterprise-supabase-react";

export const GroupPage = (): JSX.Element => {
  const { id } = useParams<{ id: string }>();

  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  return <EnterpriseGroupPage groupId={id!} />;
};
