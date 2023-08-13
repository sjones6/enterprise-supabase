import { useSettings } from "../../context/SettingsProvider";
import { useGroupById } from "../../hooks/useGroups";
import { Alert, AlertDescription, AlertTitle } from "../ui/alert";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../ui/tabs";

export type GroupPageProps = {
  groupId: string;
};

export const GroupPage = ({ groupId }: GroupPageProps): JSX.Element => {
  const settings = useSettings();
  const { data, isError, isLoading } = useGroupById(groupId, {
    onError(err) {
      settings.onError(err);
    },
  });
  return (
    <div>
      {isError && (
        <Alert>
          <AlertTitle>System Error!</AlertTitle>
          <AlertDescription>
            We encountered an error loading that group.
          </AlertDescription>
        </Alert>
      )}
      {isLoading || !data ? null : (
        <>
          <h1>{data.name}</h1>
          <Tabs defaultValue="members" className="w-[400px]">
            <TabsList>
              <TabsTrigger value="members">Members</TabsTrigger>
              <TabsTrigger value="roles">Roles</TabsTrigger>
            </TabsList>
            <TabsContent value="members">Members</TabsContent>
            <TabsContent value="roles">Roles.</TabsContent>
          </Tabs>
        </>
      )}
    </div>
  );
};
