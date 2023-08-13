import { useForm } from "react-hook-form";
import * as z from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "../ui/form";
import { Input } from "../ui/input";
import { Button } from "../ui/button";
import { Organization } from "enterprise-supabase";
import { PostgrestError } from "@supabase/supabase-js";
import { useGroupById, useUpdateGroup } from "../../hooks/useGroups";
import { useOrganizationContext } from "../../context/OrganizationProvider";
import { useEffect } from "react";

const formSchema = z.object({
  name: z.string().min(2, {
    message: "Name must be at least 2 characters.",
  }),
  description: z.string(),
});

type FormSchema = z.infer<typeof formSchema>;

export type FormEditGroupProps = {
  onSuccess?: (organization: Organization) => void;
  onError?: (error: PostgrestError) => void;
  fields?: {
    name?: {
      label?: string;
      description?: string;
    };
    description?: {
      label?: string;
      description?: string;
    };
  };
  saveButtonLabel?: string;
  groupId: string;
};

export const FormEditGroup = (props: FormEditGroupProps): JSX.Element => {
  const { primaryOrganization } = useOrganizationContext();
  const { data: group } = useGroupById(props.groupId);
  const { mutateAsync, error } = useUpdateGroup();

  const form = useForm<FormSchema>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: "",
      description: "",
    },
  });

  useEffect(() => {
    if (group) {
      form.setValue("name", group.name);
      form.setValue("description", group.description);
    }
  }, [group, form]);

  async function onSubmit(update: FormSchema) {
    try {
      if (primaryOrganization) {
        const res = await mutateAsync({
          groupId: props.groupId,
          update,
        });
        props.onSuccess && props.onSuccess(res);
      }
    } catch (err) {
      props.onError && props.onError(err as PostgrestError);
    }
  }

  const handle = form.handleSubmit(onSubmit);

  return (
    <Form {...form}>
      <form
        onSubmit={(e) => {
          handle(e).catch((err) => {
            console.error(err);
          });
        }}
        className="space-y-8"
      >
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>
                {props.fields?.name?.label || "Name"} (required)
              </FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormDescription>
                {props.fields?.name?.description ||
                  "Required. The name of your group."}
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="description"
          render={({ field }) => (
            <FormItem>
              <FormLabel>
                {props.fields?.description?.label || "Description"}
              </FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormDescription>
                {props.fields?.description?.description ||
                  "Optional. The name of your group."}
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button
          disabled={
            !primaryOrganization ||
            form.formState.isSubmitting ||
            !form.formState.isValid
          }
          type="submit"
        >
          {props.saveButtonLabel || "Update group"}
        </Button>
        {error && <div className="text-red-500">Failed to update group.</div>}
      </form>
    </Form>
  );
};
