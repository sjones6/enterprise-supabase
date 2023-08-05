import { supabase } from "@/lib/supabase";
import { useQuery } from "react-query";

export default function Dashboard(): JSX.Element {
  const { data } = useQuery(
    ["organizations"],
    async () => await supabase.from("organizations").select(),
  );
  return (
    <>
      <h1>Dashboard</h1>
      {data?.error
        ? data.error.message
        : data?.count
        ? data.data.map((organization) => (
            <h1 key={organization.id}>{organization.name}</h1>
          ))
        : "No organizations yet."}
    </>
  );
}
