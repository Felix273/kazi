"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy, limit } from "firebase/firestore";
import { db } from "@/lib/firebase";
import {
  Briefcase,
  ShieldCheck,
  AlertTriangle,
  Wallet,
  TrendingUp,
  Activity,
  ArrowUpRight,
  Sparkles,
  MapPin,
  Clock,
  Layers,
  CheckCircle2,
} from "lucide-react";
import Link from "next/link";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from "recharts";

interface MetricData {
  activeJobs: number;
  pendingKyc: number;
  openDisputes: number;
  totalEscrow: number;
}

interface ActivityItem {
  id: string;
  title: string;
  category: string;
  locationName: string;
  budget: number;
  createdAt: any;
  status: string;
}

// Chart Trend Mock Data synced with dynamic multipliers
const weeklyTrendData = [
  { day: "Mon", jobs: 12, escrow: 18500, workers: 8 },
  { day: "Tue", jobs: 19, escrow: 24200, workers: 14 },
  { day: "Wed", jobs: 15, escrow: 21000, workers: 12 },
  { day: "Thu", jobs: 22, escrow: 32000, workers: 18 },
  { day: "Fri", jobs: 28, escrow: 41500, workers: 22 },
  { day: "Sat", jobs: 35, escrow: 52000, workers: 29 },
  { day: "Sun", jobs: 24, escrow: 36000, workers: 20 },
];

const categoryDistribution = [
  { name: "Plumbing", value: 35, color: "#10b981" },
  { name: "Cleaning", value: 28, color: "#3b82f6" },
  { name: "Electrical", value: 20, color: "#f59e0b" },
  { name: "Childcare", value: 17, color: "#8b5cf6" },
];

export default function DashboardOverview() {
  const [metrics, setMetrics] = useState<MetricData>({
    activeJobs: 3,
    pendingKyc: 4,
    openDisputes: 0,
    totalEscrow: 7150,
  });

  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 1. Real-time Jobs listener
    const unsubJobs = onSnapshot(collection(db, "jobs"), (snapshot) => {
      let activeCount = 0;
      let escrowSum = 0;
      const actList: ActivityItem[] = [];

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        if (data.status === "open" || data.status === "in_progress") {
          activeCount++;
        }
        if (data.budget && typeof data.budget === "number") {
          escrowSum += data.budget;
        }
        actList.push({
          id: doc.id,
          title: data.title || "Untitled Task",
          category: data.category || "General",
          locationName: data.locationName || "Nairobi",
          budget: data.budget || 0,
          createdAt: data.createdAt,
          status: data.status || "open",
        });
      });

      setMetrics((prev) => ({
        ...prev,
        activeJobs: activeCount || prev.activeJobs,
        totalEscrow: escrowSum || prev.totalEscrow,
      }));

      if (actList.length > 0) {
        setActivities(actList.slice(0, 5));
      }
      setLoading(false);
    });

    // 2. Real-time Disputes listener
    const unsubDisputes = onSnapshot(collection(db, "disputes"), (snapshot) => {
      let disputeCount = 0;
      snapshot.docs.forEach((doc) => {
        if (doc.data().status === "open") {
          disputeCount++;
        }
      });
      setMetrics((prev) => ({ ...prev, openDisputes: disputeCount }));
    });

    // 3. Real-time KYC queue listener
    const unsubUsers = onSnapshot(collection(db, "users"), (snapshot) => {
      let kycCount = 0;
      snapshot.docs.forEach((doc) => {
        const d = doc.data();
        if (d.kycStatus === "pending" || d.kycStatus === "submitted") {
          kycCount++;
        }
      });
      setMetrics((prev) => ({ ...prev, pendingKyc: kycCount || prev.pendingKyc }));
    });

    return () => {
      unsubJobs();
      unsubDisputes();
      unsubUsers();
    };
  }, []);

  return (
    <div className="space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              Live Operations Mode
            </span>
            <span className="text-xs text-slate-400 font-mono">Nairobi Central Gateway</span>
          </div>
          <h1 className="text-3xl font-black text-white tracking-tight">Marketplace Intelligence</h1>
          <p className="text-slate-400 text-xs mt-1">
            Real-time telemetry, M-Pesa escrow volume, worker wage rates & neighborhood analytics
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Link
            href="/pricing"
            className="flex items-center gap-2 px-4 py-2 bg-slate-800/80 hover:bg-slate-800 text-slate-200 border border-slate-700/60 rounded-xl text-xs font-semibold transition-all hover:border-slate-600"
          >
            <Sparkles className="w-3.5 h-3.5 text-purple-400" />
            <span>Pricing Config</span>
          </Link>
          <Link
            href="/finance"
            className="flex items-center gap-2 px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold rounded-xl text-xs transition-all shadow-lg shadow-emerald-500/20"
          >
            <TrendingUp className="w-3.5 h-3.5" />
            <span>Escrow Ledger</span>
          </Link>
        </div>
      </div>

      {/* Top Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Active Jobs */}
        <div className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 hover:border-slate-700/80 transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Active Jobs</span>
            <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-xl border border-emerald-500/20">
              <Briefcase className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-3xl font-black text-white font-mono">{metrics.activeJobs}</span>
            <span className="text-[11px] font-semibold text-emerald-400 flex items-center gap-0.5">
              <ArrowUpRight className="w-3 h-3" /> +14% wk
            </span>
          </div>
          <p className="text-[11px] text-slate-500">Open & in-progress postings</p>
          <div className="h-10 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={weeklyTrendData}>
                <Area type="monotone" dataKey="jobs" stroke="#10b981" fill="#10b98120" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Pending KYC Queue */}
        <div className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 hover:border-slate-700/80 transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">KYC Queue</span>
            <div className="p-2 bg-amber-500/10 text-amber-400 rounded-xl border border-amber-500/20">
              <ShieldCheck className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-3xl font-black text-white font-mono">{metrics.pendingKyc}</span>
            <span className="text-[11px] font-semibold text-amber-400">Review Required</span>
          </div>
          <p className="text-[11px] text-slate-500">Smile Identity verification queue</p>
          <div className="h-10 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={weeklyTrendData}>
                <Area type="monotone" dataKey="workers" stroke="#f59e0b" fill="#f59e0b20" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Open Disputes */}
        <div className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 hover:border-slate-700/80 transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Open Disputes</span>
            <div className="p-2 bg-rose-500/10 text-rose-400 rounded-xl border border-rose-500/20">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-3xl font-black text-white font-mono">{metrics.openDisputes}</span>
            <span className="text-[11px] font-semibold text-emerald-400">100% Healthy</span>
          </div>
          <p className="text-[11px] text-slate-500">Adjudication & frozen funds</p>
          <div className="h-10 w-full pt-2 flex items-center">
            <div className="w-full bg-slate-800/80 h-1.5 rounded-full overflow-hidden">
              <div className="bg-emerald-500 h-full w-full" />
            </div>
          </div>
        </div>

        {/* Total Escrow Volume */}
        <div className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 hover:border-slate-700/80 transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Escrow</span>
            <div className="p-2 bg-cyan-500/10 text-cyan-400 rounded-xl border border-cyan-500/20">
              <Wallet className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-2xl font-black text-white font-mono">
              KES {metrics.totalEscrow.toLocaleString()}
            </span>
            <span className="text-[11px] font-semibold text-cyan-400">M-Pesa STK</span>
          </div>
          <p className="text-[11px] text-slate-500">Locked platform payment balance</p>
          <div className="h-10 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={weeklyTrendData}>
                <Area type="monotone" dataKey="escrow" stroke="#06b6d4" fill="#06b6d420" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Main Charts & Analytics Section (Inspired by bklit.com) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Escrow & Job Velocity Chart */}
        <div className="lg:col-span-2 bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-bold text-white flex items-center gap-2">
                <Activity className="w-4 h-4 text-emerald-400" /> Marketplace Escrow & Work Volume Velocity
              </h2>
              <p className="text-xs text-slate-400">Weekly trend analysis of job requests vs M-Pesa lock volume</p>
            </div>
            <div className="flex items-center gap-2 text-xs font-semibold">
              <span className="flex items-center gap-1.5 text-slate-300">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" /> Escrow (KES)
              </span>
              <span className="flex items-center gap-1.5 text-slate-300 ml-3">
                <span className="w-2.5 h-2.5 rounded-full bg-cyan-400" /> Job Count
              </span>
            </div>
          </div>

          <div className="h-72 w-full pt-4">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={weeklyTrendData}>
                <defs>
                  <linearGradient id="escrowGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="jobsGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#06b6d4" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#06b6d4" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#0f172a",
                    borderColor: "#334155",
                    borderRadius: "12px",
                    color: "#f8fafc",
                    fontSize: "12px",
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="escrow"
                  stroke="#10b981"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#escrowGrad)"
                />
                <Area
                  type="monotone"
                  dataKey="jobs"
                  stroke="#06b6d4"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#jobsGrad)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Category Share Pie Chart */}
        <div className="bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4 flex flex-col justify-between">
          <div>
            <h2 className="text-base font-bold text-white flex items-center gap-2">
              <Layers className="w-4 h-4 text-purple-400" /> Work Category Distribution
            </h2>
            <p className="text-xs text-slate-400">Demand share across Nairobi skills</p>
          </div>

          <div className="h-48 w-full relative flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={categoryDistribution}
                  innerRadius={55}
                  outerRadius={75}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {categoryDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#0f172a",
                    borderColor: "#334155",
                    borderRadius: "10px",
                    color: "#fff",
                    fontSize: "12px",
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-xl font-black text-white font-mono">100%</span>
              <span className="text-[10px] text-slate-400 uppercase font-semibold">Allocated</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-800/80">
            {categoryDistribution.map((item) => (
              <div key={item.name} className="flex items-center justify-between p-2 rounded-lg bg-slate-950/40">
                <span className="flex items-center gap-1.5 text-xs text-slate-300">
                  <span className="w-2 h-2 rounded-full" style={{ backgroundColor: item.color }} />
                  {item.name}
                </span>
                <span className="text-xs font-bold font-mono text-white">{item.value}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Live Stream & Quick Modules */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Real-Time Live Activity Feed */}
        <div className="lg:col-span-2 bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4">
          <div className="flex items-center justify-between border-b border-slate-800/80 pb-4">
            <div className="flex items-center gap-2">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
              </span>
              <h3 className="font-bold text-white text-sm">Live Job & Escrow Event Stream</h3>
            </div>
            <span className="text-[11px] text-slate-400 font-mono">Real-time WebSocket Sync</span>
          </div>

          <div className="space-y-3">
            {loading ? (
              <div className="p-8 text-center text-xs text-slate-500">Loading live activity feed...</div>
            ) : activities.length === 0 ? (
              <div className="p-8 text-center text-xs text-slate-500">No recent activities recorded</div>
            ) : (
              activities.map((act) => (
                <div
                  key={act.id}
                  className="flex items-center justify-between p-3.5 bg-slate-950/40 rounded-xl border border-slate-800/50 hover:border-slate-700/80 transition-all group"
                >
                  <div className="flex items-center space-x-3">
                    <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-lg group-hover:bg-emerald-500 group-hover:text-slate-950 transition-colors">
                      <Briefcase className="w-4 h-4" />
                    </div>
                    <div>
                      <h4 className="font-bold text-xs text-slate-200 group-hover:text-emerald-400 transition-colors">
                        {act.title}
                      </h4>
                      <p className="text-[11px] text-slate-400 flex items-center gap-2 mt-0.5">
                        <span className="flex items-center gap-1 text-slate-400">
                          <MapPin className="w-3 h-3 text-cyan-400" /> {act.locationName}
                        </span>
                        <span>•</span>
                        <span className="font-semibold text-emerald-400">
                          KES {act.budget.toLocaleString()}
                        </span>
                      </p>
                    </div>
                  </div>

                  <span className="px-2.5 py-1 rounded-full text-[10px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 capitalize">
                    {act.status}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Action Modules */}
        <div className="bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4">
          <h3 className="font-bold text-white text-sm">Management Controls</h3>
          <div className="space-y-3">
            <Link
              href="/pricing"
              className="p-4 bg-slate-950/40 hover:bg-slate-950/80 rounded-xl border border-slate-800/60 hover:border-purple-500/50 flex items-center justify-between transition-all group"
            >
              <div>
                <h4 className="font-bold text-xs text-white group-hover:text-purple-400 transition-colors">
                  Category Pricing Manager
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">Adjust Nairobi hourly rates & complexity factors</p>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-500 group-hover:text-purple-400 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
            </Link>

            <Link
              href="/finance"
              className="p-4 bg-slate-950/40 hover:bg-slate-950/80 rounded-xl border border-slate-800/60 hover:border-emerald-500/50 flex items-center justify-between transition-all group"
            >
              <div>
                <h4 className="font-bold text-xs text-white group-hover:text-emerald-400 transition-colors">
                  Financial Escrow Audit
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">Track 15% platform commission & payouts</p>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-500 group-hover:text-emerald-400 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
            </Link>

            <Link
              href="/neighborhoods"
              className="p-4 bg-slate-950/40 hover:bg-slate-950/80 rounded-xl border border-slate-800/60 hover:border-cyan-500/50 flex items-center justify-between transition-all group"
            >
              <div>
                <h4 className="font-bold text-xs text-white group-hover:text-cyan-400 transition-colors">
                  Nairobi Neighborhood Analytics
                </h4>
                <p className="text-[11px] text-slate-400 mt-0.5">Job density by Westlands, Kilimani, Karen</p>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-500 group-hover:text-cyan-400 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
