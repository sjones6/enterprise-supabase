import type { PropsWithChildren } from "react";
import { HomeIcon, UserCircleIcon } from "@heroicons/react/24/outline";
import { useAuth } from "@/components/auth";
import { Link, useLocation } from "react-router-dom";
import { OrganizationSelector } from "enterprise-supabase-react";

const navigation = [{ name: "Home", href: "/", icon: HomeIcon, exact: true }];

function classNames(...classes: string[]) {
  return classes.filter(Boolean).join(" ");
}

export default function Layout({ children }: PropsWithChildren): JSX.Element {
  const location = useLocation();
  const session = useAuth();

  return (
    <div className="flex flex-row h-screen w-screen">
      {/* Static sidebar for desktop */}
      <div className="hidden lg:inset-y-0 lg:z-50 lg:flex lg:w-56 lg:flex-col h-full overflow-hidden">
        {/* Sidebar component, swap this element with another sidebar if you like */}
        <div className="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-200 bg-white px-6">
          <div className="flex h-16 shrink-0 items-center">
            <h1 className="text-3xl">Emails</h1>
          </div>
          <nav className="flex flex-1 flex-col">
            <ul role="list" className="flex flex-1 flex-col gap-y-7">
              <li>
                <OrganizationSelector />
              </li>
              <li>
                <ul role="list" className="-mx-2 space-y-1">
                  {navigation.map((item) => {
                    const current = item.exact
                      ? location.pathname === item.href
                      : location.pathname.startsWith(item.href);
                    return (
                      <li key={item.name}>
                        <Link
                          to={item.href}
                          className={classNames(
                            current
                              ? "bg-gray-50 text-gray-900"
                              : "text-gray-700 hover:text-gray-900 hover:bg-gray-50",
                            "group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                          )}
                        >
                          <item.icon
                            className={classNames(
                              current
                                ? "text-gray-900"
                                : "text-gray-400 group-hover:text-gray-900",
                              "h-6 w-6 shrink-0"
                            )}
                            aria-hidden="true"
                          />
                          {item.name}
                        </Link>
                      </li>
                    );
                  })}
                </ul>
              </li>

              {session.session && (
                <li className="-mx-6 mt-auto">
                  <Link
                    to="/profile"
                    className="flex items-center gap-x-4 px-6 py-3 text-sm font-semibold leading-6 text-gray-900 hover:bg-gray-50"
                  >
                    <UserCircleIcon className="h-6 w-6" aria-hidden="true" />
                    <span className="sr-only">Your profile</span>
                    <span aria-hidden="true">{session.session.user.email}</span>
                  </Link>
                </li>
              )}
            </ul>
          </nav>
        </div>
      </div>
      <main className="py-10 h-full flex-grow overflow-hidden">
        <div className="px-4 sm:px-6 lg:px-8 h-full">{children}</div>
      </main>
    </div>
  );
}
