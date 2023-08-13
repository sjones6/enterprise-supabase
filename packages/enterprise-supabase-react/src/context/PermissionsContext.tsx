import { PropsWithChildren, createContext, useContext, useMemo } from "react";
import { PostgrestError } from "@supabase/supabase-js";
import { usePermissionsForAuthenticatedUser } from "../hooks/usePermissions";
import { Permission } from "enterprise-supabase";
import { useSettings } from "./SettingsProvider";

type PermissionsContextValue = {
  isLoading: boolean;
  isLoadingError: boolean;
  isError: boolean;
  isFetched: boolean;
  error: PostgrestError | null;
  permissions: Permission[];
  slugs: string[];
};

const PermissionsContext = createContext<PermissionsContextValue>({
  permissions: [],
  slugs: [],
  isLoading: false,
  isLoadingError: false,
  isError: false,
  isFetched: false,
  error: null,
});

export const PermissionsProvider = ({
  children,
}: PropsWithChildren): JSX.Element => {
  const settings = useSettings();
  const {
    data: permissions,
    isError,
    isLoading,
    isLoadingError,
    isFetched,
    error,
  } = usePermissionsForAuthenticatedUser({
    refetchInterval: settings.sync.permissions,
  });
  const value = useMemo<PermissionsContextValue>(
    () => ({
      permissions: permissions ? permissions : [],
      slugs: permissions
        ? permissions.map((permission) => permission.slug)
        : [],
      isError,
      isLoading,
      isLoadingError,
      isFetched,
      error,
    }),
    [permissions, isError, isLoading, isLoadingError, isFetched, error]
  );
  return (
    <PermissionsContext.Provider value={value}>
      {children}
    </PermissionsContext.Provider>
  );
};

export const usePermissions = () =>
  useContext<PermissionsContextValue>(PermissionsContext);

type PermissionsChecks = {
  hasPermission(slug: string): boolean;
  hasAllPermissions(slugs: string[]): boolean;
  hasAnyPermission(slugs: string[]): boolean;
};

export const usePermissionChecks = (): PermissionsChecks => {
  const { slugs } = usePermissions();
  return useMemo<PermissionsChecks>(
    () => ({
      hasPermission(slug: string): boolean {
        return slugs.includes(slug);
      },
      hasAllPermissions(slugsToCheck: string[]): boolean {
        return !slugsToCheck
          .map((slug) => slugs.includes(slug))
          .includes(false);
      },
      hasAnyPermission(slugsToCheck: string[]): boolean {
        return !!slugsToCheck.find((slug) => slugs.includes(slug));
      },
    }),
    [slugs]
  );
};
