import "@/app/globals.css";
import React from "react";
import Link from "next/link";
import { AuthProvider } from "@/context/AuthContext";
import { Briefcase, Users, AlertTriangle, LayoutDashboard, Shield } from "lucide-react";

export const metadata = {
  title: "Kazi Admin Dashboard",
  description: "Operations and monitoring dashboard for Kazi marketplace",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50 font-sans antialiased">
        <AuthProvider>
          <div className="min-h-screen flex">
            {/* Sidebar Navigation */}
            <aside className="w-64 bg-slate-900 text-white flex flex-col justify-between p-4 border-r border-slate-800">
              <div>
                <div className="flex items-center space-x-3 px-3 py-4 border-b border-slate-800 mb-6">
                  <div className="w-8 h-8 rounded-lg bg-green-600 flex items-center justify-center font-bold text-lg text-white">
                    K
                  </div>
                  <div>
                    <h2 className="font-bold text-base text-white leading-tight">KAZI ADMIN</h2>
                    <p className="text-xs text-slate-400">Nairobi Marketplace</p>
                  </div>
                </div>

                <nav className="space-y-1">
                  <Link
                    href="/"
                    className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-colors"
                  >
                    <LayoutDashboard className="w-4 h-4 text-green-500" />
                    <span>Overview</span>
                  </Link>

                  <Link
                    href="/users"
                    className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-colors"
                  >
                    <Users className="w-4 h-4 text-blue-400" />
                    <span>User & Verification</span>
                  </Link>

                  <Link
                    href="/jobs"
                    className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-colors"
                  >
                    <Briefcase className="w-4 h-4 text-amber-400" />
                    <span>Jobs & Escrow</span>
                  </Link>

                  <Link
                    href="/disputes"
                    className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-colors"
                  >
                    <AlertTriangle className="w-4 h-4 text-red-400" />
                    <span>Dispute Center</span>
                  </Link>
                </nav>
              </div>

              <div className="px-3 py-3 border-t border-slate-800 text-xs text-slate-400 flex items-center justify-between">
                <span className="flex items-center">
                  <Shield className="w-3.5 h-3.5 mr-1 text-green-400" /> Admin Secured
                </span>
                <span>v1.0.0</span>
              </div>
            </aside>

            {/* Main Content View */}
            <main className="flex-1 p-8 overflow-y-auto">
              {children}
            </main>
          </div>
        </AuthProvider>
      </body>
    </html>
  );
}
