import { Group } from "enterprise-supabase";
import { DialogCreateGroup } from "../dialogs/DialogCreateGroup";
import { GroupsTable } from "../tables/GroupsTable";
import { Button } from "../ui/button";

type GroupsPageProps = {
  onCreateGroup: (group: Group) => void;
  onEditGroup: (group: Group) => void;
  onDeleteGroup?: (group: Group) => void;
};

export const GroupsPage = ({
  onCreateGroup,
  onDeleteGroup,
  onEditGroup,
}: GroupsPageProps): JSX.Element => {
  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl">Groups</h1>
        <DialogCreateGroup
          form={{
            onSuccess: onCreateGroup,
          }}
          trigger={<Button>Create group</Button>}
        />
      </div>
      <div className="flex-grow overflow-scroll">
        <GroupsTable onEditGroup={onEditGroup} onDeleteGroup={onDeleteGroup} />
      </div>
    </div>
  );
};
