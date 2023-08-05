import { Auth } from "@supabase/auth-ui-react";
import { supabase } from "@/lib/supabase";
import { buttonVariants } from "@/components/ui/button";
import { useAuth } from "@/components/auth";
import { useEffect } from "react";

function AuthUi() {
  const auth = useAuth();

  useEffect(() => {
    if (auth.session) {
      window.location.href = "/";
    }
  }, [auth]);

  if (auth.session) {
    return <></>;
  }

  return (
    <Auth
      supabaseClient={supabase}
      appearance={{
        // If you want to extend the default styles instead of overriding it, set this to true
        extend: false,
        // Your custom classes
        className: {
          anchor: "hover:underline block",
          button: buttonVariants({ variant: "default" }),
          container: "mb-6 mt-3",
          divider: "shrink-0 bg-border h-[1px] w-full",
          input:
            "mb-6 flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
          label:
            "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70",
          // loader?: string;
          message: "text-sm font-medium leading-none",
        },
      }}
      providers={
        [
          /*'google'*/
        ]
      }
    />
  );
}

export default function Login() {
  return (
    <div className="max-w-lg mx-auto py-12">
      <h1 className="text-2xl font-bold mb-6">Login</h1>
      <AuthUi />
    </div>
  );
}
