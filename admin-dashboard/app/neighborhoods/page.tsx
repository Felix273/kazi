"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { MapPin, Navigation } from "lucide-react";
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
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-200/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-blue-100 text-blue-800 border border-blue-200">
              Spatial Intelligence
            </span>
            <span className="text-xs text-slate-500 font-mono">Nairobi Geographic Heatmap</span>
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">Neighborhood Work Analytics</h1>
          <p className="text-slate-500 text-xs mt-1">
            Job posting density, worker activity & average budget rates across key Nairobi zones
          </p>
        </div>
      </div>

      {/* Visual Density Chart */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-4">
        <div className="flex items-center justify-between border-b border-slate-100 pb-4">
          <div>
            <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
              <Navigation className="w-4 h-4 text-blue-600" /> Active Job Volume by Neighborhood Zone
            </h3>
            <p className="text-xs text-slate-500">Distribution of live gig requests across Nairobi</p>
          </div>
        </div>

        <div className="h-64 w-full pt-2">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data}>
              <XAxis dataKey="name" stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
              <YAxis stroke="#94a3b8" fontSize={11} tickLine={false} axisLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#ffffff",
                  borderColor: "#e2e8f0",
                  borderRadius: "10px",
                  color: "#0f172a",
                  fontSize: "12px",
                  fontWeight: "600",
                }}
              />
              <Bar dataKey="activeJobs" radius={[8, 8, 0, 0]}>
                {data.map((entry, index) => (
                  <Cell
                    key={`cell-${index}`}
                    fill={index % 2 === 0 ? "#2563eb" : "#059669"}
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
            className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-3 hover:shadow-md transition-all"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="p-2 bg-blue-50 text-blue-700 rounded-lg">
                  <MapPin className="w-4 h-4" />
                </div>
                <h3 className="font-bold text-slate-900 text-sm">{item.name}</h3>
              </div>
              <span className="px-2 py-0.5 bg-emerald-50 text-emerald-800 border border-emerald-200 text-[10px] font-bold rounded-full">
                Active Zone
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-100">
              <div className="p-2.5 bg-slate-50 rounded-xl">
                <span className="text-[10px] text-slate-500 font-bold uppercase block">Active Jobs</span>
                <span className="text-lg font-black font-mono text-slate-900">{item.activeJobs}</span>
              </div>
              <div className="p-2.5 bg-slate-50 rounded-xl">
                <span className="text-[10px] text-slate-500 font-bold uppercase block">Avg Budget</span>
                <span className="text-lg font-black font-mono text-emerald-700">
                  KES {item.avgBudget.toLocaleString()}
                </span>
              </div>
            </div>

            <div className="text-[11px] text-slate-500 flex justify-between pt-1">
              <span>Completed Work Volume:</span>
              <span className="font-bold text-slate-800 font-mono">{item.completedJobs} jobs</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
