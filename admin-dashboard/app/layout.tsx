"use client";

import "@/app/globals.css";
import React from "react";
import { usePathname } from "next/navigation";
import { AuthProvider } from "@/context/AuthContext";
import SidebarNav from "@/components/SidebarNav";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const isLoginPage = pathname === "/login";

  return (
    <html lang="en">
      <body className="bg-slate-50 text-slate-900 font-sans antialiased selection:bg-emerald-500 selection:text-white">
        <AuthProvider>
          {isLoginPage ? (
            /* Full Bleed Layout for Login Page */
            <main className="w-full min-h-screen bg-slate-950">
              {children}
            </main>
          ) : (
            /* Standard Dashboard Layout with Sidebar */
            <div className="min-h-screen flex">
              <SidebarNav />
              <main className="flex-1 p-8 overflow-y-auto bg-slate-50">
                <div className="max-w-7xl mx-auto space-y-8">
                  {children}
                </div>
              </main>
            </div>
          )}
        </AuthProvider>
      </body>
    </html>
  );
}
