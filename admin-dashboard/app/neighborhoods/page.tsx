"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { MapPin, Navigation, AlertCircle } from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from "recharts";

interface NeighborhoodStat {
  name: string;
  activeJobs: number;
  completedJobs: number;
  avgBudget: number;
}

export default function NeighborhoodsPage() {
  const [data, setData] = useState<NeighborhoodStat[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, "jobs"), (snapshot) => {
      const counts: Record<string, { active: number; completed: number; budgetSum: number; count: number }> = {};

      snapshot.docs.forEach((doc) => {
        const d = doc.data();
        const loc = d.locationName || "Unassigned";
        if (!counts[loc]) {
          counts[loc] = { active: 0, completed: 0, budgetSum: 0, count: 0 };
        }
        if (d.status === "open" || d.status === "in_progress") {
          counts[loc].active++;
        } else if (d.status === "completed") {
          counts[loc].completed++;
        }
        if (d.budget && typeof d.budget === "number") {
          counts[loc].budgetSum += d.budget;
          counts[loc].count++;
        }
      });

      const items: NeighborhoodStat[] = Object.entries(counts).map(([name, stat]) => ({
        name,
        activeJobs: stat.active,
        completedJobs: stat.completed,
        avgBudget: stat.count > 0 ? Math.round(stat.budgetSum / stat.count) : 0,
      }));

      setData(items);
      setLoading(false);
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
            <span className="text-xs text-slate-500 font-mono">Real Backend Aggregations</span>
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">Neighborhood Work Analytics</h1>
          <p className="text-slate-500 text-xs mt-1">
            Real live job density, active workers & average budget rates calculated directly from Firestore documents
          </p>
        </div>
      </div>

      {loading ? (
        <div className="p-12 text-center text-xs text-slate-400 bg-white rounded-2xl border border-slate-200/80">
          Loading live spatial analytics...
        </div>
      ) : data.length === 0 ? (
        <div className="p-12 text-center bg-white rounded-2xl border border-slate-200/80 text-xs text-slate-500 space-y-2">
          <AlertCircle className="w-8 h-8 text-blue-500 mx-auto" />
          <p className="font-bold text-slate-900 text-sm">No Location Documents Found</p>
          <p className="text-slate-500 text-xs">When users post jobs with locations in the mobile app, they will automatically appear here!</p>
        </div>
      ) : (
        <>
          {/* Visual Density Chart */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <div>
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Navigation className="w-4 h-4 text-blue-600" /> Active Job Volume by Neighborhood Zone
                </h3>
                <p className="text-xs text-slate-500">Live distribution calculated from Firestore location records</p>
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
                    Live Zone
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
        </>
      )}
    </div>
  );
}
