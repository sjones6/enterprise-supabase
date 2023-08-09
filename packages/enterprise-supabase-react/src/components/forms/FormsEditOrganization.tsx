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
import {
  useOrganizationById,
  useUpdateOrganization,
} from "../../hooks/useOrganizations";
import { Organization } from "enterprise-supabase";
import { PostgrestError } from "@supabase/supabase-js";
import { useEffect } from "react";

const formSchema = z.object({
  name: z.string().min(2, {
    message: "Name must be at least 2 characters.",
  }),
});

type FormSchema = z.infer<typeof formSchema>;

export type FormEditOrganizationProps = {
  organizationId: string;
  onSuccess?: (organization: Organization) => void;
  onError?: (error: PostgrestError) => void;
  fields?: {
    name?: {
      label?: string;
      description?: string;
    };
  };
  saveButtonLabel?: string;
};

export const FromEditOrganization = (
  props: FormEditOrganizationProps
): JSX.Element => {
  const { data: organization, isLoading } = useOrganizationById(
    props.organizationId
  );
  const { mutateAsync, error } = useUpdateOrganization();

  const form = useForm<FormSchema>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: "",
    },
  });

  useEffect(() => {
    if (organization) {
      form.setValue("name", organization.name);
    }
  }, [organization, form]);

  async function onSubmit(update: FormSchema) {
    try {
      console.log("submitting");
      const res = await mutateAsync({
        organizationId: props.organizationId,
        update,
      });
      props.onSuccess && props.onSuccess(res);
    } catch (err) {
      console.log(err);
      props.onError && props.onError(err as PostgrestError);
    }
  }

  return (
    <Form {...form}>
      <form onSubmit={() => {
        const handle = () => form.handleSubmit(onSubmit);
        handle();
      }} className="space-y-8">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>{props.fields?.name?.label || "Name"}</FormLabel>
              <FormControl>
                <Input {...field} disabled={isLoading} />
              </FormControl>
              <FormDescription>
                {props.fields?.name?.description ||
                  "Required. The name of your organization."}
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button
          disabled={form.formState.isSubmitting || !form.formState.isValid}
          type="submit"
        >
          {props.saveButtonLabel || "Update organization"}
        </Button>
        {error && (
          <div className="text-red-500">Failed to update organization.</div>
        )}
      </form>
    </Form>
  );
};
