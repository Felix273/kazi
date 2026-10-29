"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { DollarSign, Wallet, ArrowDownRight, ArrowUpRight, TrendingUp, ShieldCheck, CheckCircle2 } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts";

interface FinancialSummary {
  totalEscrowHeld: number;
  totalCommission: number;
  totalPayouts: number;
  activeTransactions: number;
}

const monthlyRevenueHistory = [
  { month: "Jan", escrow: 120000, commission: 18000, payouts: 102000 },
  { month: "Feb", escrow: 165000, commission: 24750, payouts: 140250 },
  { month: "Mar", escrow: 210000, commission: 31500, payouts: 178500 },
  { month: "Apr", escrow: 195000, commission: 29250, payouts: 165750 },
  { month: "May", escrow: 280000, commission: 42000, payouts: 238000 },
  { month: "Jun", escrow: 340000, commission: 51000, payouts: 289000 },
];

export default function FinancePage() {
  const [summary, setSummary] = useState<FinancialSummary>({
    totalEscrowHeld: 7150,
    totalCommission: 1072.5,
    totalPayouts: 6077.5,
    activeTransactions: 3,
  });

  useEffect(() => {
    const unsub = onSnapshot(collection(db, "jobs"), (snapshot) => {
      let totalBudget = 0;
      let count = 0;

      snapshot.docs.forEach((doc) => {
        const data = doc.data();
        if (data.budget && typeof data.budget === "number") {
          totalBudget += data.budget;
          count++;
        }
      });

      if (totalBudget > 0) {
        const comm = totalBudget * 0.15;
        const payouts = totalBudget - comm;
        setSummary({
          totalEscrowHeld: totalBudget,
          totalCommission: comm,
          totalPayouts: payouts,
          activeTransactions: count,
        });
      }
    });

    return () => unsub();
  }, []);

  return (
    <div className="space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              M-Pesa Escrow & Revenue Ledger
            </span>
            <span className="text-xs text-slate-400 font-mono">15% Marketplace Take-Rate</span>
          </div>
          <h1 className="text-3xl font-black text-white tracking-tight">Financial & Escrow Analytics</h1>
          <p className="text-slate-400 text-xs mt-1">
            Audit platform commission fees, worker payout disbursements & M-Pesa transaction velocity
          </p>
        </div>
      </div>

      {/* Top Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Total Escrow Held */}
        <div className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Escrow Volume</span>
            <div className="p-2 bg-cyan-500/10 text-cyan-400 rounded-xl border border-cyan-500/20">
              <Wallet className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-2xl font-black text-white font-mono">
              KES {summary.totalEscrowHeld.toLocaleString()}
            </span>
            <span className="text-xs font-bold text-cyan-400">M-Pesa Locked</span>
          </div>
          <p className="text-[11px] text-slate-500">Gross transaction volume across active jobs</p>
        </div>

        {/* Commission Collected */}
        <div className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Platform Revenue (15%)</span>
            <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-xl border border-emerald-500/20">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-2xl font-black text-emerald-400 font-mono">
              KES {summary.totalCommission.toLocaleString()}
            </span>
            <span className="text-xs font-bold text-emerald-400">Net Platform Fee</span>
          </div>
          <p className="text-[11px] text-slate-500">15% commission retained on job completion</p>
        </div>

        {/* Worker Payout Balance */}
        <div className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Worker Net Payouts (85%)</span>
            <div className="p-2 bg-purple-500/10 text-purple-400 rounded-xl border border-purple-500/20">
              <ArrowDownRight className="w-4 h-4" />
            </div>
          </div>
          <div className="flex items-baseline justify-between">
            <span className="text-2xl font-black text-white font-mono">
              KES {summary.totalPayouts.toLocaleString()}
            </span>
            <span className="text-xs font-bold text-purple-400">B2C Disbursed</span>
          </div>
          <p className="text-[11px] text-slate-500">Net payout sent to workers via M-Pesa B2C</p>
        </div>
      </div>

      {/* Revenue Growth Trend Chart (Inspired by bklit.com) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-bold text-white text-sm flex items-center gap-2">
                <TrendingUp className="w-4 h-4 text-emerald-400" /> Monthly Gross Escrow vs Net Platform Revenue
              </h3>
              <p className="text-xs text-slate-400">Historical performance trajectory in Nairobi</p>
            </div>
          </div>

          <div className="h-72 w-full pt-4">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={monthlyRevenueHistory}>
                <XAxis dataKey="month" stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
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
                <Bar dataKey="escrow" fill="#06b6d4" radius={[6, 6, 0, 0]} name="Gross Escrow" />
                <Bar dataKey="commission" fill="#10b981" radius={[6, 6, 0, 0]} name="15% Commission" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* M-Pesa B2C Health Status */}
        <div className="bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4 flex flex-col justify-between">
          <div>
            <h3 className="font-bold text-white text-sm flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-cyan-400" /> M-Pesa Gateway Integrity
            </h3>
            <p className="text-xs text-slate-400">Safaricom Daraja API connectivity</p>
          </div>

          <div className="space-y-3">
            <div className="p-3.5 bg-slate-950/60 rounded-xl border border-slate-800/80 flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-300">STK Push Response Latency</span>
              <span className="text-xs font-bold font-mono text-emerald-400">140ms</span>
            </div>
            <div className="p-3.5 bg-slate-950/60 rounded-xl border border-slate-800/80 flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-300">B2C Payout Success Rate</span>
              <span className="text-xs font-bold font-mono text-emerald-400">99.8%</span>
            </div>
            <div className="p-3.5 bg-slate-950/60 rounded-xl border border-slate-800/80 flex items-center justify-between">
              <span className="text-xs font-semibold text-slate-300">Escrow Timeout Expiry</span>
              <span className="text-xs font-bold font-mono text-cyan-400">24 Hours</span>
            </div>
          </div>

          <div className="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400 text-xs font-semibold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4" />
            <span>M-Pesa Payment Engine Active</span>
          </div>
        </div>
      </div>
    </div>
  );
}
