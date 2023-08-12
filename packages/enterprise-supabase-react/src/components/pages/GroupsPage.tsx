import { DialogCreateGroup } from "../dialogs/DialogCreateGroup";
import { GroupsTable } from "../tables/GroupsTable";
import { Button } from "../ui/button";

export const GroupsPage = (): JSX.Element => {
  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl">Groups</h1>
        <DialogCreateGroup trigger={<Button>Create group</Button>} />
      </div>
      <div className="flex-grow overflow-scroll">
        <GroupsTable />
      </div>
    </div>
  );
};
