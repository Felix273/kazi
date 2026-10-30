"use client";

import React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext";
import {
  LayoutDashboard,
  Users,
  Briefcase,
  AlertTriangle,
  Calculator,
  DollarSign,
  MapPin,
  Shield,
  CheckCircle2,
  LogOut,
  LogIn,
  UserCheck,
} from "lucide-react";

export default function SidebarNav() {
  const { user } = useAuth();
  const router = useRouter();

  const handleSignOut = async () => {
    try {
      await signOut(auth);
      router.push("/login");
    } catch (err: any) {
      alert(`Error signing out: ${err.message || err}`);
    }
  };

  return (
    <aside className="w-64 bg-slate-900 text-slate-200 flex flex-col justify-between p-4 sticky top-0 h-screen shadow-xl">
      <div>
        {/* Brand Header */}
        <div className="flex items-center space-x-3 px-3 py-3.5 border-b border-slate-800/90 mb-6">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-emerald-600 via-emerald-500 to-teal-400 flex items-center justify-center font-black text-xl text-slate-950 shadow-md">
            K
          </div>
          <div>
            <h2 className="font-extrabold text-base tracking-tight text-white flex items-center gap-1.5">
              KAZI <span className="text-[10px] font-bold uppercase tracking-widest px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">ADMIN</span>
            </h2>
            <p className="text-[11px] text-slate-400 font-medium">Nairobi Marketplace</p>
          </div>
        </div>

        {/* Main Nav Links */}
        <div className="space-y-6">
          <div>
            <p className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2">
              Core Operations
            </p>
            <nav className="space-y-1">
              <Link
                href="/"
                className="flex items-center space-x-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-white transition-all group"
              >
                <LayoutDashboard className="w-4 h-4 text-emerald-400 group-hover:scale-110 transition-transform" />
                <span>Overview</span>
              </Link>

              <Link
                href="/users"
                className="flex items-center space-x-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-white transition-all group"
              >
                <Users className="w-4 h-4 text-blue-400 group-hover:scale-110 transition-transform" />
                <span>User & Verification</span>
              </Link>

              <Link
                href="/jobs"
                className="flex items-center space-x-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-white transition-all group"
              >
                <Briefcase className="w-4 h-4 text-amber-400 group-hover:scale-110 transition-transform" />
                <span>Jobs & Escrow</span>
              </Link>

              <Link
                href="/disputes"
                className="flex items-center space-x-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-white transition-all group"
              >
                <AlertTriangle className="w-4 h-4 text-rose-400 group-hover:scale-110 transition-transform" />
                <span>Dispute Center</span>
              </Link>
            </nav>
          </div>

          <div>
            <p className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-2">
              Marketplace Engine
            </p>
            <nav className="space-y-1">
              <Link
                href="/pricing"
                className="flex items-center space-x-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-white transition-all group"
              >
                <Calculator className="w-4 h-4 text-purple-400 group-hover:scale-110 transition-transform" />
                <span>Category Pricing</span>
              </Link>

              <Link
                href="/finance"
                className="flex items-center space-x-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-white transition-all group"
              >
                <DollarSign className="w-4 h-4 text-emerald-400 group-hover:scale-110 transition-transform" />
                <span>Financial Analytics</span>
              </Link>

              <Link
                href="/neighborhoods"
                className="flex items-center space-x-3 px-3 py-2.5 rounded-xl text-xs font-semibold text-slate-300 hover:bg-slate-800 hover:text-white transition-all group"
              >
                <MapPin className="w-4 h-4 text-cyan-400 group-hover:scale-110 transition-transform" />
                <span>Nairobi Density</span>
              </Link>
            </nav>
          </div>
        </div>
      </div>

      {/* Footer User Auth & Logout Controls */}
      <div className="pt-4 border-t border-slate-800/90 space-y-3">
        {user ? (
          <div className="space-y-2">
            <div className="bg-slate-950/80 p-2.5 rounded-xl border border-slate-800 text-[11px] text-slate-300 space-y-1">
              <div className="flex items-center justify-between text-slate-400">
                <span className="flex items-center gap-1">
                  <UserCheck className="w-3.5 h-3.5 text-emerald-400" /> Admin Session
                </span>
                <span className="font-mono text-[10px] text-emerald-400 font-bold">Active</span>
              </div>
              <p className="font-mono text-xs text-white truncate">{user.email}</p>
            </div>

            <button
              onClick={handleSignOut}
              className="w-full flex items-center justify-center space-x-2 px-3 py-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 rounded-xl text-xs font-bold transition-all"
            >
              <LogOut className="w-3.5 h-3.5" />
              <span>Log Out Admin</span>
            </button>
          </div>
        ) : (
          <Link
            href="/login"
            className="w-full flex items-center justify-center space-x-2 px-3 py-2.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold rounded-xl text-xs transition-all shadow-md shadow-emerald-500/20"
          >
            <LogIn className="w-3.5 h-3.5" />
            <span>Sign In to Admin</span>
          </Link>
        )}

        <div className="flex items-center justify-between text-[10px] text-slate-500 px-1 pt-1 border-t border-slate-800/50">
          <span className="flex items-center gap-1 text-slate-400 font-medium">
            <Shield className="w-3 h-3 text-slate-400" /> Secure Operating System
          </span>
          <span className="font-mono">v1.3.5</span>
        </div>
      </div>
    </aside>
  );
}
