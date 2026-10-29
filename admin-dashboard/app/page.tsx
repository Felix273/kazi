"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
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
  Layers,
} from "lucide-react";
import Link from "next/link";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
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

interface CategoryDistItem {
  name: string;
  value: number;
  color: string;
}

interface TrendItem {
  day: string;
  jobs: number;
  escrow: number;
}

const CATEGORY_COLORS = ["#059669", "#2563eb", "#d97706", "#7c3aed", "#e11d48", "#0891b2"];

export default function DashboardOverview() {
  const [metrics, setMetrics] = useState<MetricData>({
    activeJobs: 0,
    pendingKyc: 0,
    openDisputes: 0,
    totalEscrow: 0,
  });

  const [activities, setActivities] = useState<ActivityItem[]>([]);
  const [categoryDist, setCategoryDist] = useState<CategoryDistItem[]>([]);
  const [dailyTrend, setDailyTrend] = useState<TrendItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 1. Live Jobs Listener
    const unsubJobs = onSnapshot(collection(db, "jobs"), (snapshot) => {
      let activeCount = 0;
      let escrowSum = 0;
      const actList: ActivityItem[] = [];
      const catCounts: Record<string, number> = {};
      const dayCounts: Record<string, { jobs: number; escrow: number }> = {
        Mon: { jobs: 0, escrow: 0 },
        Tue: { jobs: 0, escrow: 0 },
        Wed: { jobs: 0, escrow: 0 },
        Thu: { jobs: 0, escrow: 0 },
        Fri: { jobs: 0, escrow: 0 },
        Sat: { jobs: 0, escrow: 0 },
        Sun: { jobs: 0, escrow: 0 },
      };

      const daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        const status = data.status || "open";
        const budget = typeof data.budget === "number" ? data.budget : 0;
        const cat = data.category || "General";

        if (status === "open" || status === "in_progress") {
          activeCount++;
          escrowSum += budget;
        }

        // Tally category
        catCounts[cat] = (catCounts[cat] || 0) + 1;

        // Tally day trend if createdAt exists
        if (data.createdAt) {
          const date = data.createdAt.toDate ? data.createdAt.toDate() : new Date(data.createdAt);
          const dayName = daysOfWeek[date.getDay()];
          if (dayCounts[dayName]) {
            dayCounts[dayName].jobs++;
            dayCounts[dayName].escrow += budget;
          }
        }

        actList.push({
          id: doc.id,
          title: data.title || "Untitled Task",
          category: cat,
          locationName: data.locationName || "Nairobi",
          budget,
          createdAt: data.createdAt,
          status,
        });
      });

      setMetrics((prev) => ({
        ...prev,
        activeJobs: activeCount,
        totalEscrow: escrowSum,
      }));

      setActivities(actList.slice(0, 5));

      // Calculate category distribution percentages directly from backend docs
      const totalDocs = snapshot.docs.length;
      if (totalDocs > 0) {
        const dist = Object.entries(catCounts).map(([name, count], index) => ({
          name,
          value: Math.round((count / totalDocs) * 100),
          color: CATEGORY_COLORS[index % CATEGORY_COLORS.length],
        }));
        setCategoryDist(dist);
      } else {
        setCategoryDist([]);
      }

      // Format weekly trend
      const trendArr = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) => ({
        day,
        jobs: dayCounts[day].jobs,
        escrow: dayCounts[day].escrow,
      }));
      setDailyTrend(trendArr);

      setLoading(false);
    });

    // 2. Live Disputes Listener
    const unsubDisputes = onSnapshot(collection(db, "disputes"), (snapshot) => {
      let disputeCount = 0;
      snapshot.docs.forEach((doc) => {
        if (doc.data().status === "open") {
          disputeCount++;
        }
      });
      setMetrics((prev) => ({ ...prev, openDisputes: disputeCount }));
    });

    // 3. Live KYC Queue Listener
    const unsubUsers = onSnapshot(collection(db, "users"), (snapshot) => {
      let kycCount = 0;
      snapshot.docs.forEach((doc) => {
        const d = doc.data();
        if (d.kycStatus === "pending" || d.kycStatus === "submitted") {
          kycCount++;
        }
      });
      setMetrics((prev) => ({ ...prev, pendingKyc: kycCount }));
    });

    return () => {
      unsubJobs();
      unsubDisputes();
      unsubUsers();
    };
  }, []);

  return (
    <div className="space-y-8">
      {/* Executive Light Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-200/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-emerald-100 text-emerald-800 border border-emerald-200">
              Live Operations Stream
            </span>
            <span className="text-xs text-slate-500 font-mono">100% Backend Live Sync</span>
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">Executive Dashboard</h1>
          <p className="text-slate-500 text-xs mt-1">
            Real-time operations monitoring, M-Pesa escrow balance, worker wage benchmarks & spatial analytics
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Link
            href="/pricing"
            className="flex items-center gap-2 px-4 py-2 bg-white hover:bg-slate-50 text-slate-700 border border-slate-300 rounded-xl text-xs font-semibold transition-all shadow-sm"
          >
            <Sparkles className="w-3.5 h-3.5 text-purple-600" />
            <span>Pricing Engine</span>
          </Link>
          <Link
            href="/finance"
            className="flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white font-bold rounded-xl text-xs transition-all shadow-md shadow-slate-900/10"
          >
            <TrendingUp className="w-3.5 h-3.5 text-emerald-400" />
            <span>Escrow Ledger</span>
          </Link>
        </div>
      </div>

      {/* Top Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Active Jobs */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 hover:shadow-md transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Active Jobs</span>
            <div className="p-2 bg-emerald-50 text-emerald-700 rounded-xl border border-emerald-100">
              <Briefcase className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-3xl font-black text-slate-900 font-mono">{metrics.activeJobs}</span>
            <span className="text-[11px] font-bold text-emerald-600 flex items-center gap-0.5">
              <ArrowUpRight className="w-3 h-3" /> Live
            </span>
          </div>
          <p className="text-[11px] text-slate-500">Open & in-progress postings</p>
          <div className="h-10 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dailyTrend}>
                <Area type="monotone" dataKey="jobs" stroke="#059669" fill="#d1fae5" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Pending KYC Queue */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 hover:shadow-md transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">KYC Queue</span>
            <div className="p-2 bg-amber-50 text-amber-700 rounded-xl border border-amber-100">
              <ShieldCheck className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-3xl font-black text-slate-900 font-mono">{metrics.pendingKyc}</span>
            <span className="text-[11px] font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200">
              Review Required
            </span>
          </div>
          <p className="text-[11px] text-slate-500">Smile Identity verification queue</p>
          <div className="h-10 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dailyTrend}>
                <Area type="monotone" dataKey="jobs" stroke="#d97706" fill="#fef3c7" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Open Disputes */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 hover:shadow-md transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Open Disputes</span>
            <div className="p-2 bg-rose-50 text-rose-700 rounded-xl border border-rose-100">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-3xl font-black text-slate-900 font-mono">{metrics.openDisputes}</span>
            <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
              {metrics.openDisputes === 0 ? "100% Healthy" : "Action Needed"}
            </span>
          </div>
          <p className="text-[11px] text-slate-500">Adjudication & frozen funds</p>
          <div className="h-10 w-full pt-2 flex items-center">
            <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden border border-slate-200/60">
              <div
                className={`h-full ${metrics.openDisputes === 0 ? "bg-emerald-500 w-full" : "bg-rose-500 w-1/2"}`}
              />
            </div>
          </div>
        </div>

        {/* Total Escrow Volume */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 hover:shadow-md transition-all space-y-3 relative overflow-hidden group">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Total Escrow</span>
            <div className="p-2 bg-blue-50 text-blue-700 rounded-xl border border-blue-100">
              <Wallet className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-2xl font-black text-slate-900 font-mono">
              KES {metrics.totalEscrow.toLocaleString()}
            </span>
            <span className="text-[11px] font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded-full border border-blue-200">
              M-Pesa Lock
            </span>
          </div>
          <p className="text-[11px] text-slate-500">Locked platform payment balance</p>
          <div className="h-10 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dailyTrend}>
                <Area type="monotone" dataKey="escrow" stroke="#2563eb" fill="#dbeafe" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Main Charts & Analytics Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Escrow & Job Velocity Chart */}
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                <Activity className="w-4 h-4 text-emerald-600" /> Marketplace Escrow & Work Velocity
              </h2>
              <p className="text-xs text-slate-500">Live Backend document timeline analysis</p>
            </div>
            <div className="flex items-center gap-2 text-xs font-semibold">
              <span className="flex items-center gap-1.5 text-slate-700">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-600" /> Escrow (KES)
              </span>
              <span className="flex items-center gap-1.5 text-slate-700 ml-3">
                <span className="w-2.5 h-2.5 rounded-full bg-blue-600" /> Job Count
              </span>
            </div>
          </div>

          <div className="h-72 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dailyTrend}>
                <defs>
                  <linearGradient id="escrowLightGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#059669" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#059669" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="jobsLightGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2563eb" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#2563eb" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="day" stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "#ffffff",
                    borderColor: "#e2e8f0",
                    borderRadius: "12px",
                    color: "#0f172a",
                    boxShadow: "0 10px 15px -3px rgba(0, 0, 0, 0.1)",
                    fontSize: "12px",
                    fontWeight: "600",
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="escrow"
                  stroke="#059669"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#escrowLightGrad)"
                />
                <Area
                  type="monotone"
                  dataKey="jobs"
                  stroke="#2563eb"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#jobsLightGrad)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Category Share Pie Chart */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-4 flex flex-col justify-between">
          <div className="border-b border-slate-100 pb-4">
            <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <Layers className="w-4 h-4 text-purple-600" /> Work Category Distribution
            </h2>
            <p className="text-xs text-slate-500">Live category breakdown from Firestore</p>
          </div>

          <div className="h-48 w-full relative flex items-center justify-center">
            {categoryDist.length === 0 ? (
              <div className="text-xs text-slate-400">No category documents found</div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={categoryDist}
                    innerRadius={55}
                    outerRadius={75}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {categoryDist.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "#ffffff",
                      borderColor: "#e2e8f0",
                      borderRadius: "10px",
                      color: "#0f172a",
                      fontSize: "12px",
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            )}
            {categoryDist.length > 0 && (
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-xl font-black text-slate-900 font-mono">100%</span>
                <span className="text-[10px] text-slate-400 uppercase font-semibold">Live Data</span>
              </div>
            )}
          </div>

          <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-100">
            {categoryDist.map((item) => (
              <div key={item.name} className="flex items-center justify-between p-2 rounded-lg bg-slate-50">
                <span className="flex items-center gap-1.5 text-xs text-slate-700 font-medium">
                  <span className="w-2 h-2 rounded-full" style={{ backgroundColor: item.color }} />
                  {item.name}
                </span>
                <span className="text-xs font-bold font-mono text-slate-900">{item.value}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Live Activity Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div className="flex items-center gap-2">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
              </span>
              <h3 className="font-bold text-slate-900 text-sm">Live Job & Escrow Event Feed</h3>
            </div>
            <span className="text-[11px] text-slate-500 font-mono">Real-time Firestore Sync</span>
          </div>

          <div className="space-y-3">
            {loading ? (
              <div className="p-8 text-center text-xs text-slate-400">Loading live activity feed...</div>
            ) : activities.length === 0 ? (
              <div className="p-8 text-center text-xs text-slate-400">No recent activities recorded in database</div>
            ) : (
              activities.map((act) => (
                <div
                  key={act.id}
                  className="flex items-center justify-between p-3.5 bg-slate-50 hover:bg-slate-100/80 rounded-xl border border-slate-200/60 transition-all group"
                >
                  <div className="flex items-center space-x-3">
                    <div className="p-2 bg-emerald-100 text-emerald-800 rounded-lg group-hover:bg-emerald-600 group-hover:text-white transition-colors">
                      <Briefcase className="w-4 h-4" />
                    </div>
                    <div>
                      <h4 className="font-bold text-xs text-slate-900 group-hover:text-emerald-700 transition-colors">
                        {act.title}
                      </h4>
                      <p className="text-[11px] text-slate-500 flex items-center gap-2 mt-0.5">
                        <span className="flex items-center gap-1 text-slate-600 font-medium">
                          <MapPin className="w-3 h-3 text-blue-600" /> {act.locationName}
                        </span>
                        <span>•</span>
                        <span className="font-bold text-emerald-700">
                          KES {act.budget.toLocaleString()}
                        </span>
                      </p>
                    </div>
                  </div>

                  <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 border border-emerald-200 capitalize">
                    {act.status}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Management Controls */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-4">
          <h3 className="font-bold text-slate-900 text-sm border-b border-slate-100 pb-3">Management Controls</h3>
          <div className="space-y-3">
            <Link
              href="/pricing"
              className="p-4 bg-slate-50 hover:bg-slate-100 rounded-xl border border-slate-200/60 hover:border-purple-300 flex items-center justify-between transition-all group"
            >
              <div>
                <h4 className="font-bold text-xs text-slate-900 group-hover:text-purple-700 transition-colors">
                  Category Pricing Manager
                </h4>
                <p className="text-[11px] text-slate-500 mt-0.5">Configure Nairobi benchmark hourly rates</p>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-purple-700 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
            </Link>

            <Link
              href="/finance"
              className="p-4 bg-slate-50 hover:bg-slate-100 rounded-xl border border-slate-200/60 hover:border-emerald-300 flex items-center justify-between transition-all group"
            >
              <div>
                <h4 className="font-bold text-xs text-slate-900 group-hover:text-emerald-700 transition-colors">
                  Financial Escrow Audit
                </h4>
                <p className="text-[11px] text-slate-500 mt-0.5">Track 15% platform commission & payouts</p>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-emerald-700 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
            </Link>

            <Link
              href="/neighborhoods"
              className="p-4 bg-slate-50 hover:bg-slate-100 rounded-xl border border-slate-200/60 hover:border-blue-300 flex items-center justify-between transition-all group"
            >
              <div>
                <h4 className="font-bold text-xs text-slate-900 group-hover:text-blue-700 transition-colors">
                  Nairobi Spatial Analytics
                </h4>
                <p className="text-[11px] text-slate-500 mt-0.5">Job density by Westlands, Kilimani, Karen</p>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-blue-700 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
