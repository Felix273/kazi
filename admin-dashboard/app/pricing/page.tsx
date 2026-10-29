"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, doc, setDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Calculator, Save, Sparkles, TrendingUp } from "lucide-react";
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
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-200/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-purple-100 text-purple-800 border border-purple-200">
              Pricing Engine
            </span>
            <span className="text-xs text-slate-500 font-mono">Nairobi Hourly Benchmarks</span>
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">Category Benchmark Rates</h1>
          <p className="text-slate-500 text-xs mt-1">
            Configure standard Nairobi hourly wage baselines used by the Smart Pricing Calculator
          </p>
        </div>

        <button
          onClick={handleSaveRates}
          disabled={saving}
          className="flex items-center gap-2 px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white font-bold rounded-xl text-xs transition-all shadow-md shadow-emerald-600/20 disabled:opacity-50"
        >
          <Save className="w-4 h-4" />
          <span>{saving ? "Saving Changes..." : "Publish Benchmark Rates"}</span>
        </button>
      </div>

      {saveSuccess && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800 text-xs font-semibold flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-emerald-600" />
          <span>Category hourly benchmark rates successfully published to Firestore!</span>
        </div>
      )}

      {/* Visual Rate Comparison Graph */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-4">
        <div className="flex items-center justify-between border-b border-slate-100 pb-4">
          <div>
            <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-purple-600" /> Hourly Base Rate Comparison (KES/hour)
            </h3>
            <p className="text-xs text-slate-500">Visual benchmark comparison across Nairobi job categories</p>
          </div>
        </div>

        <div className="h-64 w-full pt-2">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
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
              <Bar dataKey="rate" radius={[8, 8, 0, 0]}>
                {chartData.map((entry, index) => (
                  <Cell
                    key={`cell-${index}`}
                    fill={index % 2 === 0 ? "#7c3aed" : "#059669"}
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
            className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-100 space-y-3 hover:shadow-md transition-all"
          >
            <div className="flex items-center justify-between">
              <span className="font-bold text-sm text-slate-900">{item.label}</span>
              <span className="p-1.5 bg-purple-50 text-purple-700 rounded-lg text-xs font-mono font-bold border border-purple-100">
                {item.category}
              </span>
            </div>

            <div>
              <label className="text-[11px] font-bold text-slate-500 uppercase tracking-wider block mb-1">
                Base Hourly Rate (KES)
              </label>
              <div className="relative flex items-center">
                <span className="absolute left-3 text-slate-400 text-xs font-bold">KES</span>
                <input
                  type="number"
                  value={item.baseHourlyRate}
                  onChange={(e) => handleRateChange(index, Number(e.target.value))}
                  className="w-full bg-slate-50 border border-slate-200 focus:border-purple-600 focus:bg-white rounded-xl py-2 pl-12 pr-4 text-slate-900 text-sm font-mono font-bold focus:outline-none transition-all"
                />
              </div>
            </div>

            <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-500 flex justify-between">
              <span>8-hour Day Benchmark:</span>
              <span className="font-bold text-emerald-700 font-mono">
                KES {(item.baseHourlyRate * 8).toLocaleString()}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
