import "@/app/globals.css";
import React from "react";
import { AuthProvider } from "@/context/AuthContext";
import SidebarNav from "@/components/SidebarNav";

export const metadata = {
  title: "Kazi Admin Operations | Executive Dashboard",
  description: "Operations, pricing, analytics and monitoring dashboard for Kazi marketplace",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-slate-50 text-slate-900 font-sans antialiased selection:bg-emerald-500 selection:text-white">
        <AuthProvider>
          <div className="min-h-screen flex">
            {/* Sidebar Navigation */}
            <SidebarNav />

            {/* Main Content Area */}
            <main className="flex-1 p-8 overflow-y-auto bg-slate-50">
              <div className="max-w-7xl mx-auto space-y-8">
                {children}
              </div>
            </main>
          </div>
        </AuthProvider>
      </body>
    </html>
  );
}
