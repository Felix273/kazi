import "@/app/globals.css";
import React from "react";
import Link from "next/link";
import { AuthProvider } from "@/context/AuthContext";
import {
  LayoutDashboard,
  Users,
  Briefcase,
  AlertTriangle,
  Calculator,
  DollarSign,
  MapPin,
  Shield,
  Zap,
} from "lucide-react";

export const metadata = {
  title: "Kazi Admin Dashboard | Operating System",
  description: "Operations, pricing, analytics and monitoring dashboard for Kazi marketplace",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-slate-950 text-slate-100 font-sans antialiased selection:bg-emerald-500 selection:text-slate-950">
        <AuthProvider>
          <div className="min-h-screen flex">
            {/* Sidebar Navigation */}
            <aside className="w-64 bg-slate-900/90 backdrop-blur-xl text-slate-200 flex flex-col justify-between p-4 border-r border-slate-800/80 sticky top-0 h-screen">
              <div>
                {/* Brand Header */}
                <div className="flex items-center space-x-3 px-3 py-3.5 border-b border-slate-800/80 mb-6">
                  <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-emerald-600 via-emerald-500 to-teal-400 flex items-center justify-center font-extrabold text-xl text-slate-950 shadow-lg shadow-emerald-500/20">
                    K
                  </div>
                  <div>
                    <h2 className="font-black text-base tracking-tight text-white flex items-center gap-1.5">
                      KAZI <span className="text-[10px] font-bold uppercase tracking-widest px-1.5 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">OS</span>
                    </h2>
                    <p className="text-[11px] text-slate-400 font-medium">Nairobi Marketplace</p>
                  </div>
                </div>

                {/* Main Nav */}
                <div className="space-y-6">
                  <div>
                    <p className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-2">
                      Core Operations
                    </p>
                    <nav className="space-y-1">
                      <Link
                        href="/"
                        className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all group"
                      >
                        <LayoutDashboard className="w-4 h-4 text-emerald-400 group-hover:scale-110 transition-transform" />
                        <span>Overview</span>
                      </Link>

                      <Link
                        href="/users"
                        className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all group"
                      >
                        <Users className="w-4 h-4 text-blue-400 group-hover:scale-110 transition-transform" />
                        <span>User & Verification</span>
                      </Link>

                      <Link
                        href="/jobs"
                        className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all group"
                      >
                        <Briefcase className="w-4 h-4 text-amber-400 group-hover:scale-110 transition-transform" />
                        <span>Jobs & Escrow</span>
                      </Link>

                      <Link
                        href="/disputes"
                        className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all group"
                      >
                        <AlertTriangle className="w-4 h-4 text-rose-400 group-hover:scale-110 transition-transform" />
                        <span>Dispute Center</span>
                      </Link>
                    </nav>
                  </div>

                  <div>
                    <p className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-2">
                      Marketplace Engine
                    </p>
                    <nav className="space-y-1">
                      <Link
                        href="/pricing"
                        className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all group"
                      >
                        <Calculator className="w-4 h-4 text-purple-400 group-hover:scale-110 transition-transform" />
                        <span>Category Pricing</span>
                      </Link>

                      <Link
                        href="/finance"
                        className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all group"
                      >
                        <DollarSign className="w-4 h-4 text-emerald-400 group-hover:scale-110 transition-transform" />
                        <span>Financial Analytics</span>
                      </Link>

                      <Link
                        href="/neighborhoods"
                        className="flex items-center space-x-3 px-3 py-2.5 rounded-lg text-xs font-semibold text-slate-300 hover:bg-slate-800/80 hover:text-white transition-all group"
                      >
                        <MapPin className="w-4 h-4 text-cyan-400 group-hover:scale-110 transition-transform" />
                        <span>Nairobi Density</span>
                      </Link>
                    </nav>
                  </div>
                </div>
              </div>

              {/* Footer status */}
              <div className="pt-4 border-t border-slate-800/80 space-y-2">
                <div className="flex items-center justify-between text-[11px] text-slate-400 px-1">
                  <span className="flex items-center gap-1.5 font-medium text-emerald-400">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Live Stream
                  </span>
                  <span className="font-mono text-slate-500 text-[10px]">v1.2.0</span>
                </div>
                <div className="bg-slate-950/60 p-2.5 rounded-lg border border-slate-800/60 text-[11px] text-slate-400 flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <Shield className="w-3.5 h-3.5 text-slate-400" /> Security Token
                  </span>
                  <span className="font-mono text-xs text-emerald-400">Verified</span>
                </div>
              </div>
            </aside>

            {/* Main Content Area */}
            <main className="flex-1 p-8 overflow-y-auto bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950">
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
