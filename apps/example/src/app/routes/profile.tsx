import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { useAuth } from "@/components/auth";
import { supabase } from "@/lib/supabase";

export default function Profile(): JSX.Element {
  const session = useAuth();
  if (!session.session) {
    return <></>;
  }
  return (
    <>
      <h1 className="text-lg font-bold mb-3">Profile</h1>
      <div>Logged in as {session.session.user.email}.</div>
      <Separator className="my-3" />
      <Button variant={"outline"} onClick={() => supabase.auth.signOut()}>
        Sign out
      </Button>
    </>
  );
}
