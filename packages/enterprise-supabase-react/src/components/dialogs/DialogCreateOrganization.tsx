import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../ui/dialog";
import {
  FormCreateOrganizationProps,
  FromCreateOrganization,
} from "../forms/FormCreateOrganization";
import { useState } from "react";

export type DialogCreateOrganizationProps = {
  trigger: React.ReactNode;
  dialog?: {
    header?: string;
    description?: string;
  };
  form?: FormCreateOrganizationProps;
};

export function DialogCreateOrganization({
  dialog = {},
  form = {},
  trigger,
}: DialogCreateOrganizationProps) {
  const [open, setOpen] = useState<boolean>(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>
            {dialog.description || "Create organization"}
          </DialogTitle>
          <DialogDescription>
            {dialog.description ||
              "Once your organization has been created, you will be able to add members, roles, and groups."}
          </DialogDescription>
        </DialogHeader>
        <FromCreateOrganization
          {...form}
          onSuccess={(organization) => {
            setOpen(false);
            form.onSuccess && form.onSuccess(organization);
          }}
        />
      </DialogContent>
    </Dialog>
  );
}
