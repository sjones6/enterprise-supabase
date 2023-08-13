<<<<<<< HEAD
=======
import { Group } from "enterprise-supabase";
>>>>>>> 450d9dd (progress)
import { DialogCreateGroup } from "../dialogs/DialogCreateGroup";
import { GroupsTable } from "../tables/GroupsTable";
import { Button } from "../ui/button";

<<<<<<< HEAD
export const GroupsPage = (): JSX.Element => {
=======
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
>>>>>>> 450d9dd (progress)
  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl">Groups</h1>
<<<<<<< HEAD
        <DialogCreateGroup trigger={<Button>Create group</Button>} />
      </div>
      <div className="flex-grow overflow-scroll">
        <GroupsTable />
=======
        <DialogCreateGroup
          form={{
            onSuccess: onCreateGroup,
          }}
          trigger={<Button>Create group</Button>}
        />
      </div>
      <div className="flex-grow overflow-scroll">
        <GroupsTable onEditGroup={onEditGroup} onDeleteGroup={onDeleteGroup} />
>>>>>>> 450d9dd (progress)
      </div>
    </div>
  );
};
