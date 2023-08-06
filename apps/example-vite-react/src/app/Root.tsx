import { Outlet } from "react-router-dom";
import Layout from "./Layout";

export default function Root(): JSX.Element {
  return (
    <Layout>
      <Outlet />
    </Layout>
  );
}
