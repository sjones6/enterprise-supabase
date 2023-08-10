import { createContext, useContext, PropsWithChildren } from "react";
import type { Organization } from "enterprise-supabase";
import { useAuth } from "./AuthContextProvider";
import { useOrganizations } from "../hooks/useOrganizations";

type OrganizationContextValue = {
  primaryOrganization: string | null;
  organizations: Organization[];
};

const OrganizationContext = createContext<OrganizationContextValue | null>(
  null
);

export const OrganizationProvider = ({
  children,
}: PropsWithChildren): JSX.Element => {
  const auth = useAuth();
  const { data } = useOrganizations({
    enabled: !!auth.session,
  });
  const primaryOrganization =
    auth.session && (auth.session.user.app_metadata.organization as string);
  return (
    <OrganizationContext.Provider
      value={{
        organizations: data || [],
        primaryOrganization: primaryOrganization || null,
      }}
    >
      {children}
    </OrganizationContext.Provider>
  );
};

export const useOrganizationContext = (): {
  primaryOrganization: Organization | null;
  organizations: Organization[];
} => {
  const ctx = useContext(OrganizationContext);
  if (!ctx) {
    return {
      primaryOrganization: null,
      organizations: [],
    };
  }
  const { primaryOrganization, organizations } = ctx;
  const organization =
    primaryOrganization &&
    organizations.find((org) => org.id === primaryOrganization);
  return {
    primaryOrganization: organization || null,
    organizations,
  };
};
