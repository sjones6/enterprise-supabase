import {
  useContext,
  useState,
  useEffect,
  createContext,
  PropsWithChildren,
  useMemo,
} from "react";
import type { Session } from "@supabase/supabase-js";
import { useSupabaseClient } from "./SupabaseClientProvider";

// create a context for authentication
const AuthContext = createContext<{
  session: Session | null;
  loading: boolean;
}>({
  session: null,
  loading: true,
});

export const AuthContextProvider = ({
  children,
}: PropsWithChildren) => {
  const supabase = useSupabaseClient();
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const value = useMemo(() => ({ session, loading }), [session, loading]);

  useEffect(() => {
    const run = async () => {
      // get session data if there is an active session
      const session = await supabase.auth.getSession();
      setSession(session.data.session ?? null);
      setLoading(false);
    };

    // listen for changes to auth
    const { data: listener } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setSession(session ?? null);
        setLoading(false);
      }
    );

    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    run();

    // cleanup the useEffect hook
    return () => {
      listener.subscription.unsubscribe();
    };
  }, [supabase.auth]);

  return (
    <AuthContext.Provider value={value}>
      {loading ? null : children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
