import { PropsWithChildren, createContext, useContext } from "react";

type SettingsContextValue = {
  sync: {
    permissions: number | false;
  };
  format: {
    dateTime: string;
  };
  onError: (err: unknown) => unknown;
};

export type SettingsContextValueProp = Partial<{
  sync: {
    /**
     * How frequently to refresh permissions. Defaults to every 5 mins.
     */
    permissions: number | false;
  };
  format: Partial<{
    /**
     * A date-time string format for `date-fns`.
     *
     * See https://date-fns.org
     */
    dateTime: string;
  }>;
  onError: (err: unknown) => unknown;
}>;

const defaultSettings: SettingsContextValue = {
  sync: {
    permissions: 5 * 60 * 1000,
  },
  format: {
    dateTime: "Pp",
  },
  onError(err: unknown): void {
    console.warn("Uncaught error from supabase-enterprise-react", err);
  },
};

const SettingsContext = createContext<SettingsContextValue>(defaultSettings);

export const SettingsProvider = ({
  children,
  ...settings
}: PropsWithChildren<SettingsContextValueProp>): JSX.Element => {
  return (
    <SettingsContext.Provider
      value={{
        ...defaultSettings,
        ...settings,
        format: {
          ...defaultSettings.format,
          ...(settings.format ? settings.format : {}),
        },
      }}
    >
      {children}
    </SettingsContext.Provider>
  );
};

export const useSettings = (): SettingsContextValue =>
  useContext(SettingsContext);
