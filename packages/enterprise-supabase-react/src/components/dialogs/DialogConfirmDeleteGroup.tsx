import { useEffect, useState } from "react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "../ui/alert-dialog";
import { useDeleteGroup, useGroupById } from "../../hooks/useGroups";
import { Group } from "enterprise-supabase";

type BaseProps = {
  groupId: string;
  onSuccess?: (group: Group) => void;
};

type Controlled = BaseProps & {
  open: boolean;
};

type WithTrigger = BaseProps & {
  trigger: React.ReactNode;
};

type DialogConfirmDeleteGroupProps = WithTrigger | Controlled;

export function DialogConfirmDeleteGroup(props: DialogConfirmDeleteGroupProps) {
  const { groupId } = props;

  const open: boolean = "open" in props ? props.open : false;
  const trigger: React.ReactNode = "trigger" in props ? props.trigger : null;

  const [isDialogOpen, setIsDialogOpen] = useState<boolean>(
    trigger ? false : open
  );
  useEffect(() => {
    setIsDialogOpen(open);
  }, [open]);

  const { mutateAsync } = useDeleteGroup();
  const { data, isLoading } = useGroupById(groupId, {
    enabled: isDialogOpen,
  });
  const alertDialogProps = trigger === null ? { open: isDialogOpen } : {};

  if (!trigger && isLoading) {
    return <></>;
  }

  return (
    <AlertDialog {...alertDialogProps} onOpenChange={setIsDialogOpen}>
      {trigger && <AlertDialogTrigger asChild>{trigger}</AlertDialogTrigger>}
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            Are you sure you want to delete &quot;{data?.name}&quot;?
          </AlertDialogTitle>
          <AlertDialogDescription>
            This action cannot be undone. This will permanently delete your
            group and remove associated data from our servers.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          {data && (
            <>
              <AlertDialogCancel>Cancel</AlertDialogCancel>
              <AlertDialogAction
                onClick={async () => {
                  await mutateAsync(groupId);
                  props.onSuccess && props.onSuccess(data);
                }}
              >
                Delete permantenly
              </AlertDialogAction>
            </>
          )}
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
