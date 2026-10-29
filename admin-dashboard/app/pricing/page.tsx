"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, doc, setDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Calculator, Save, AlertCircle, Sparkles, TrendingUp, DollarSign } from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from "recharts";

interface CategoryRate {
  category: string;
  baseHourlyRate: number;
  label: string;
}

const defaultCategoryRates: CategoryRate[] = [
  { category: "Cleaning", baseHourlyRate: 350, label: "Cleaning & Housekeeping" },
  { category: "Plumbing", baseHourlyRate: 500, label: "Plumbing & Piping" },
  { category: "Electrical", baseHourlyRate: 550, label: "Electrical Installation & Repair" },
  { category: "Gardening", baseHourlyRate: 300, label: "Gardening & Compound Care" },
  { category: "Carpentry", baseHourlyRate: 450, label: "Carpentry & Furniture Works" },
  { category: "Painting", baseHourlyRate: 400, label: "Interior & Exterior Painting" },
  { category: "Childcare", baseHourlyRate: 300, label: "Nanny & Childcare Services" },
];

export default function CategoryPricingPage() {
  const [rates, setRates] = useState<CategoryRate[]>(defaultCategoryRates);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, "settings"), (snapshot) => {
      const categoryDoc = snapshot.docs.find((d) => d.id === "category_rates");
      if (categoryDoc && categoryDoc.exists()) {
        const data = categoryDoc.data();
        if (data.rates && Array.isArray(data.rates)) {
          setRates(data.rates);
        }
      }
    });

    return () => unsub();
  }, []);

  const handleRateChange = (index: number, newRate: number) => {
    const updated = [...rates];
    updated[index].baseHourlyRate = newRate;
    setRates(updated);
  };

  const handleSaveRates = async () => {
    setSaving(true);
    setSaveSuccess(false);
    try {
      await setDoc(doc(db, "settings", "category_rates"), {
        rates,
        updatedAt: new Date(),
      });
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
    } catch (err: any) {
      alert(`Failed to save rates: ${err.message || err}`);
    } finally {
      setSaving(false);
    }
  };

  const chartData = rates.map((r) => ({
    name: r.category,
    rate: r.baseHourlyRate,
  }));

  return (
    <div className="space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-purple-500/10 text-purple-400 border border-purple-500/20">
              Pricing Engine
            </span>
            <span className="text-xs text-slate-400 font-mono">Nairobi Hourly Benchmarks</span>
          </div>
          <h1 className="text-3xl font-black text-white tracking-tight">Category Benchmark Rates</h1>
          <p className="text-slate-400 text-xs mt-1">
            Configure standard Nairobi hourly wage baselines used by the Smart Pricing Calculator
          </p>
        </div>

        <button
          onClick={handleSaveRates}
          disabled={saving}
          className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold rounded-xl text-xs transition-all shadow-lg shadow-emerald-500/20 disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          <span>{saving ? "Saving Changes..." : "Publish Benchmark Rates"}</span>
        </button>
      </div>

      {saveSuccess && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400 text-xs font-semibold flex items-center gap-2">
          <Sparkles className="w-4 h-4" />
          <span>Category hourly benchmark rates successfully published to Firestore!</span>
        </div>
      )}

      {/* Visual Rate Comparison Graph (Inspired by bklit.com) */}
      <div className="bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-bold text-white text-sm flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-purple-400" /> Hourly Base Rate Comparison (KES/hour)
            </h3>
            <p className="text-xs text-slate-400">Visual comparison across Nairobi job categories</p>
          </div>
        </div>

        <div className="h-64 w-full pt-4">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
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
              <Bar dataKey="rate" radius={[8, 8, 0, 0]}>
                {chartData.map((entry, index) => (
                  <Cell
                    key={`cell-${index}`}
                    fill={index % 2 === 0 ? "#8b5cf6" : "#10b981"}
                  />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Interactive Rate Configurator Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {rates.map((item, index) => (
          <div
            key={item.category}
            className="bg-slate-900/60 backdrop-blur-md p-5 rounded-2xl border border-slate-800/80 space-y-3 hover:border-slate-700/80 transition-all"
          >
            <div className="flex items-center justify-between">
              <span className="font-bold text-sm text-white">{item.label}</span>
              <span className="p-1.5 bg-purple-500/10 text-purple-400 rounded-lg text-xs font-mono border border-purple-500/20">
                {item.category}
              </span>
            </div>

            <div>
              <label className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-1">
                Base Hourly Rate (KES)
              </label>
              <div className="relative flex items-center">
                <span className="absolute left-3 text-slate-500 text-xs font-bold">KES</span>
                <input
                  type="number"
                  value={item.baseHourlyRate}
                  onChange={(e) => handleRateChange(index, Number(e.target.value))}
                  className="w-full bg-slate-950 border border-slate-800 focus:border-purple-500 rounded-xl py-2 pl-12 pr-4 text-white text-sm font-mono font-bold focus:outline-none transition-colors"
                />
              </div>
            </div>

            <div className="pt-2 border-t border-slate-800/80 text-[11px] text-slate-400 flex justify-between">
              <span>8-hour Day Benchmark:</span>
              <span className="font-bold text-emerald-400 font-mono">
                KES {(item.baseHourlyRate * 8).toLocaleString()}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
