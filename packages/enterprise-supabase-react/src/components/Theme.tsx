import { useEffect, useState } from "react";

/**
 * All color values should be supplied as `hsl` values
 * without the `hsl()` function call.
 */
export type ThemeProps = {
  background: string;
  foreground: string;
  muted: string;
  "muted-foreground": string;
  popover: string;
  "popover-foreground": string;
  border: string;
  input: string;
  card: string;
  "card-foreground": string;
  primary: string;
  "primary-foreground": string;
  secondary: string;
  "secondary-foreground": string;
  accent: string;
  "accent-foreground": string;
  destructive: string;
  "destructive-foreground": string;
  ring: string;
  radius: string;
};

const defaultLightTheme: ThemeProps = {
  background: "0 0% 100%",
  foreground: "222.2 47.4% 11.2%",
  muted: "210 40% 96.1%",
  "muted-foreground": "215.4 16.3% 46.9%",
  popover: "0 0% 100%",
  "popover-foreground": "222.2 47.4% 11.2%",
  border: "214.3 31.8% 91.4%",
  input: "214.3 31.8% 91.4%",
  card: "0 0% 100%",
  "card-foreground": "222.2 47.4% 11.2%",
  primary: "222.2 47.4% 11.2%",
  "primary-foreground": "210 40% 98%",
  secondary: "210 40% 96.1%",
  "secondary-foreground": "222.2 47.4% 11.2%",
  accent: "210 40% 96.1%",
  "accent-foreground": "222.2 47.4% 11.2%",
  destructive: "0 100% 50%",
  "destructive-foreground": "210 40% 98%",
  ring: "215 20.2% 65.1%",
  radius: "0.5rem",
};
const defaultDarkTheme: ThemeProps = {
  background: "224 71% 4%",
  foreground: "213 31% 91%",
  muted: "223 47% 11%",
  "muted-foreground": "215.4 16.3% 56.9%",
  accent: "216 34% 17%",
  "accent-foreground": "210 40% 98%",
  popover: "224 71% 4%",
  "popover-foreground": "215 20.2% 65.1%",
  border: "216 34% 17%",
  input: "216 34% 17%",
  card: "224 71% 4%",
  "card-foreground": "213 31% 91%",
  primary: "210 40% 98%",
  "primary-foreground": "222.2 47.4% 1.2%",
  secondary: "222.2 47.4% 11.2%",
  "secondary-foreground": "210 40% 98%",
  destructive: "0 63% 31%",
  "destructive-foreground": "210 40% 98%",
  ring: "216 34% 17%",
  radius: "0.5rem",
};

export const Theme = ({
  dark,
  light,
}: {
  dark?: Partial<ThemeProps>;
  light?: Partial<ThemeProps>;
}): JSX.Element => {
  const [isClient, setIsClient] = useState<boolean>(false);
  useEffect(() => {
    setIsClient(true);
  }, []);

  useEffect(() => {
    if (isClient) {
      const lightTheme: ThemeProps = {
        ...defaultLightTheme,
        ...light,
      };

      const root = document.querySelector(":root") as HTMLElement;
      Object.entries(lightTheme).map(([key, value]) => {
        root.style.setProperty(`--${key}`, value);
      });

      const darkTheme: ThemeProps = {
        ...defaultDarkTheme,
        ...dark,
      };

      const darks = document.getElementsByClassName(".dark");
      if (darks.length > 0) {
        Array.prototype.forEach.call(darks, (dark) => {
          Object.entries(darkTheme).map(([key, value]) => {
            /* eslint-disable @typescript-eslint/no-unsafe-member-access */
            /* eslint-disable @typescript-eslint/no-unsafe-call */
            dark.style.setProperty(`--${key}`, value);
          });
        });
      }
    }
    /* eslint-disable-next-line react-hooks/exhaustive-deps */
  }, [isClient]);
  return <></>;
};
