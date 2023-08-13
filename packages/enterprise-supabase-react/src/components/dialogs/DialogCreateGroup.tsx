import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../ui/dialog";
import {
  FormCreateGroupProps,
  FormCreateGroup,
} from "../forms/FormCreateGroup";
import { useState } from "react";

export type DialogCreateGroupProps = {
  trigger: React.ReactNode;
  dialog?: {
    header?: string;
    description?: string;
  };
  form?: FormCreateGroupProps;
};

export function DialogCreateGroup({
  dialog = {},
  form = {},
  trigger,
}: DialogCreateGroupProps) {
  const [open, setOpen] = useState<boolean>(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{dialog.description || "Create group"}</DialogTitle>
          <DialogDescription>
            {dialog.description ||
              "Once your group has been created, you will be able to add members and roles to the group."}
          </DialogDescription>
        </DialogHeader>
        <FormCreateGroup
          {...form}
          onSuccess={(group) => {
            setOpen(false);
            form.onSuccess && form.onSuccess(group);
          }}
        />
      </DialogContent>
    </Dialog>
  );
}
