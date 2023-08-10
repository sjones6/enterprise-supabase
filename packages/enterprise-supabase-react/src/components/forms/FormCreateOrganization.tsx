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
import { useCreateOrganization } from "../../hooks/useOrganizations";
import { Organization } from "enterprise-supabase";
import { PostgrestError } from "@supabase/supabase-js";

const formSchema = z.object({
  name: z.string().min(2, {
    message: "Name must be at least 2 characters.",
  }),
});

type FormSchema = z.infer<typeof formSchema>;

export type FormCreateOrganizationProps = {
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

export const FromCreateOrganization = (
  props: FormCreateOrganizationProps = {}
): JSX.Element => {
  const { mutateAsync, error } = useCreateOrganization();

  const form = useForm<FormSchema>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      name: "",
    },
  });

  async function onSubmit(values: FormSchema) {
    try {
      const res = await mutateAsync(values);
      props.onSuccess && props.onSuccess(res);
    } catch (err) {
      props.onError && props.onError(err as PostgrestError);
    }
  }

  return (
    <Form {...form}>
      <form
        onSubmit={() => {
          const handle = () => form.handleSubmit(onSubmit);
          handle();
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
          {props.saveButtonLabel || "Create organization"}
        </Button>
        {error && (
          <div className="text-red-500">Failed to create organization.</div>
        )}
      </form>
    </Form>
  );
};
