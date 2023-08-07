import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../ui/dialog";
import { useState } from "react";
import {
  FromEditOrganization,
  FormEditOrganizationProps,
} from "../forms/FormsEditOrganization";

export type DialogEditOrganizationProps = {
  organizationId: string;
  trigger: React.ReactNode;
  dialog?: {
    header?: string;
    description?: string;
  };
  form?: Omit<FormEditOrganizationProps, "organizationId">;
};

export function DialogEditOrganization({
  organizationId,
  dialog = {},
  form = {},
  trigger,
}: DialogEditOrganizationProps) {
  const [open, setOpen] = useState<boolean>(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>
            {dialog.description || "Update organization"}
          </DialogTitle>
        </DialogHeader>
        <FromEditOrganization
          {...form}
          organizationId={organizationId}
          onSuccess={(organization) => {
            setOpen(false);
            form.onSuccess && form.onSuccess(organization);
          }}
        />
      </DialogContent>
    </Dialog>
  );
}
