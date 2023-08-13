import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "../ui/dialog";
import { useState } from "react";
import { FormEditGroup, FormEditGroupProps } from "../forms/FormEditGroup";

export type DialogEditGroupProps = {
  groupId: string;
  trigger: React.ReactNode;
  dialog?: {
    header?: string;
    description?: string;
  };
  form?: Omit<FormEditGroupProps, "groupId">;
};

export function DialogEditGroup({
  groupId,
  dialog = {},
  form = {},
  trigger,
}: DialogEditGroupProps) {
  const [open, setOpen] = useState<boolean>(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{dialog.header || "Edit group"}</DialogTitle>
          {dialog.description && (
            <DialogDescription>{dialog.description}</DialogDescription>
          )}
        </DialogHeader>
        <FormEditGroup
          {...form}
          groupId={groupId}
          onSuccess={(group) => {
            setOpen(false);
            form.onSuccess && form.onSuccess(group);
          }}
        />
      </DialogContent>
    </Dialog>
  );
}
