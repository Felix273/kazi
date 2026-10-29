"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { MapPin, Briefcase, Users, TrendingUp, Sparkles, Navigation } from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from "recharts";

interface NeighborhoodStat {
  name: string;
  activeJobs: number;
  completedJobs: number;
  avgBudget: number;
}

const initialNeighborhoods: NeighborhoodStat[] = [
  { name: "Kilimani", activeJobs: 14, completedJobs: 82, avgBudget: 3500 },
  { name: "Westlands", activeJobs: 18, completedJobs: 104, avgBudget: 4200 },
  { name: "Karen", activeJobs: 8, completedJobs: 45, avgBudget: 5500 },
  { name: "Kasarani", activeJobs: 12, completedJobs: 64, avgBudget: 2200 },
  { name: "Parklands", activeJobs: 9, completedJobs: 51, avgBudget: 3800 },
  { name: "Nairobi CBD", activeJobs: 15, completedJobs: 90, avgBudget: 2800 },
];

export default function NeighborhoodsPage() {
  const [data, setData] = useState<NeighborhoodStat[]>(initialNeighborhoods);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, "jobs"), (snapshot) => {
      const counts: Record<string, { active: number; budgetSum: number; count: number }> = {};

      snapshot.docs.forEach((doc) => {
        const d = doc.data();
        const loc = d.locationName || "Kilimani";
        if (!counts[loc]) {
          counts[loc] = { active: 0, budgetSum: 0, count: 0 };
        }
        if (d.status === "open" || d.status === "in_progress") {
          counts[loc].active++;
        }
        if (d.budget && typeof d.budget === "number") {
          counts[loc].budgetSum += d.budget;
          counts[loc].count++;
        }
      });

      const updated = initialNeighborhoods.map((n) => {
        const live = counts[n.name];
        if (live) {
          return {
            ...n,
            activeJobs: live.active > 0 ? live.active : n.activeJobs,
            avgBudget: live.count > 0 ? Math.round(live.budgetSum / live.count) : n.avgBudget,
          };
        }
        return n;
      });

      setData(updated);
    });

    return () => unsub();
  }, []);

  return (
    <div className="space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
              Spatial Intelligence
            </span>
            <span className="text-xs text-slate-400 font-mono">Nairobi Geographic Heatmap</span>
          </div>
          <h1 className="text-3xl font-black text-white tracking-tight">Neighborhood Work Analytics</h1>
          <p className="text-slate-400 text-xs mt-1">
            Job posting density, worker activity & average budget rates across key Nairobi zones
          </p>
        </div>
      </div>

      {/* Visual Density Chart */}
      <div className="bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-bold text-white text-sm flex items-center gap-2">
              <Navigation className="w-4 h-4 text-cyan-400" /> Active Job Volume by Neighborhood Zone
            </h3>
            <p className="text-xs text-slate-400">Distribution of live gig requests across Nairobi</p>
          </div>
        </div>

        <div className="h-64 w-full pt-4">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data}>
              <XAxis dataKey="name" stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
              <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#0f172a",
                  borderColor: "#334155",
                  borderRadius: "10px",
                  color: "#fff",
                  fontSize: "12px",
                }}
              />
              <Bar dataKey="activeJobs" radius={[8, 8, 0, 0]}>
                {data.map((entry, index) => (
                  <Cell
                    key={`cell-${index}`}
                    fill={index % 2 === 0 ? "#06b6d4" : "#3b82f6"}
                  />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Neighborhood Grid Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {data.map((item) => (
          <div
            key={item.name}
            className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 space-y-3 hover:border-slate-700/80 transition-all"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="p-2 bg-cyan-500/10 text-cyan-400 rounded-lg">
                  <MapPin className="w-4 h-4" />
                </div>
                <h3 className="font-bold text-white text-sm">{item.name}</h3>
              </div>
              <span className="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[10px] font-bold rounded-full">
                Active Zone
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-800/80">
              <div className="p-2.5 bg-slate-950/40 rounded-xl">
                <span className="text-[10px] text-slate-400 font-semibold uppercase block">Active Jobs</span>
                <span className="text-lg font-black font-mono text-white">{item.activeJobs}</span>
              </div>
              <div className="p-2.5 bg-slate-950/40 rounded-xl">
                <span className="text-[10px] text-slate-400 font-semibold uppercase block">Avg Budget</span>
                <span className="text-lg font-black font-mono text-emerald-400">
                  KES {item.avgBudget.toLocaleString()}
                </span>
              </div>
            </div>

            <div className="text-[11px] text-slate-400 flex justify-between pt-1">
              <span>Completed Work Volume:</span>
              <span className="font-bold text-slate-200 font-mono">{item.completedJobs} jobs</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
