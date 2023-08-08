import { useOrganizationContext } from "../context/OrganizationProvider";
import { useOrganizations, useSetPrimaryOrganization } from "../hooks/useOrganizations";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import { Separator } from "./ui/separator";
import { DialogCreateOrganization } from "./dialogs/DialogCreateOrganization";
import { Button } from "./ui/button";
import { Skeleton } from "./ui/skeleton";

export function OrganizationSelector() {
  const { data: organizations, isLoading } = useOrganizations();
  const { primaryOrganization } = useOrganizationContext();
  const { mutateAsync } = useSetPrimaryOrganization();

  if (isLoading) {
    return <Skeleton className="h-[40px] w-[180px]"/>;
  }

  return (
    <Select
      onValueChange={async (value) => {
        try {
          await mutateAsync(value);
        } catch (err) {
          console.error(err);
        }
      }}
      defaultValue={primaryOrganization?.id}
    >
      <SelectTrigger className="w-[180px]">
        <SelectValue placeholder="Select Organization" />
      </SelectTrigger>
      <SelectContent>
        {organizations && organizations.length ? (
          <>
            <SelectGroup>
              <SelectLabel>Organizations</SelectLabel>
              {organizations.map((organization) => (
                  <SelectItem key={organization.id} value={organization.id}>
                    {organization.name}
                  </SelectItem>
                ))}
            </SelectGroup>
            <Separator className="my-2" />
          </>
        ) : null}
        <DialogCreateOrganization
          form={{
            async onSuccess(organization) {
              await mutateAsync(organization.id);
            }
          }}
          trigger={<Button className="w-full" variant={"secondary"}>Create organization</Button>}
        />
      </SelectContent>
    </Select>
  );
}
