import {
  useContext,
  useState,
  useEffect,
  createContext,
  PropsWithChildren,
  useMemo,
} from "react";
import { supabase } from "../lib/supabase";
import type { Session } from "@supabase/supabase-js";

// create a context for authentication
const AuthContext = createContext<{
  session: Session | null;
  loading: boolean;
}>({
  session: null,
  loading: true,
});

export const AuthProvider = ({
  children,
}: PropsWithChildren) => {
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
  }, []);

  // use a provider to pass down the value
  return (
    <AuthContext.Provider value={value}>
      {loading ? (
        <div className="w-full h-screen flex justify-center items-center">
          Loading ...
        </div>
      ) : (
        children
      )}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);

export const RequireAuth = ({
  children,
  redirect = "/login",
}: PropsWithChildren<{
  redirect?: string;
}>): JSX.Element => {
  const ctx = useAuth();
  if (ctx.loading) {
    return <>loading...</>;
  }
  if (!ctx.session) {
    window.location.href = redirect;
    return <></>;
  }
  return <>{children}</>;
};
