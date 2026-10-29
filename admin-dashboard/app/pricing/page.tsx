"use client";

import React, { useEffect, useState } from "react";
import { doc, getDoc, setDoc, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Calculator, Save, CheckCircle2, DollarSign, Info } from "lucide-react";

interface CategoryRate {
  category: string;
  baseHourlyRateKES: number;
}

const defaultRates: CategoryRate[] = [
  { category: "Cleaning", baseHourlyRateKES: 250 },
  { category: "Plumbing", baseHourlyRateKES: 500 },
  { category: "Electrical", baseHourlyRateKES: 500 },
  { category: "Delivery", baseHourlyRateKES: 250 },
  { category: "Security", baseHourlyRateKES: 300 },
  { category: "Cooking", baseHourlyRateKES: 300 },
  { category: "Childcare", baseHourlyRateKES: 250 },
  { category: "Painting", baseHourlyRateKES: 400 },
  { category: "Carpentry", baseHourlyRateKES: 400 },
  { category: "Gardening", baseHourlyRateKES: 200 },
  { category: "Driving", baseHourlyRateKES: 300 },
  { category: "Events", baseHourlyRateKES: 400 },
  { category: "Casual Labour", baseHourlyRateKES: 200 },
];

export default function PricingConfiguratorPage() {
  const [rates, setRates] = useState<CategoryRate[]>(defaultRates);
  const [saving, setSaving] = useState(false);
  const [savedSuccess, setSavedSuccess] = useState(false);

  useEffect(() => {
    const rateRef = doc(db, "settings", "category_rates");
    const unsub = onSnapshot(
      rateRef,
      (docSnap) => {
        if (docSnap.exists() && docSnap.data().rates) {
          setRates(docSnap.data().rates);
        }
      },
      () => {
        // Fallback to defaults if doc doesn't exist yet
        setRates(defaultRates);
      }
    );

    return () => unsub();
  }, []);

  const handleRateChange = (index: number, newRate: number) => {
    const updated = [...rates];
    updated[index].baseHourlyRateKES = newRate;
    setRates(updated);
  };

  const handleSave = async () => {
    setSaving(true);
    setSavedSuccess(false);

    try {
      const rateRef = doc(db, "settings", "category_rates");
      await setDoc(rateRef, {
        rates,
        updatedAt: new Date().toISOString(),
      });
      setSavedSuccess(true);
      setTimeout(() => setSavedSuccess(false), 4000);
    } catch (err) {
      console.error("Failed to save rates", err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center space-x-2">
            <Calculator className="w-6 h-6 text-green-700" />
            <span>Category Benchmark Rate Manager</span>
          </h1>
          <p className="text-gray-500 text-sm mt-1">
            Configure standard market hourly rates (in KES) for Nairobi that power the Smart Pricing Calculator
          </p>
        </div>

        <button
          onClick={handleSave}
          disabled={saving}
          className="inline-flex items-center justify-center space-x-2 px-5 py-2.5 bg-green-700 text-white text-sm font-semibold rounded-lg hover:bg-green-800 disabled:opacity-50 transition-colors shadow-sm"
        >
          {saving ? (
            <span>Saving changes...</span>
          ) : savedSuccess ? (
            <>
              <CheckCircle2 className="w-4 h-4 text-white" />
              <span>Saved Successfully!</span>
            </>
          ) : (
            <>
              <Save className="w-4 h-4" />
              <span>Save Category Rates</span>
            </>
          )}
        </button>
      </div>

      {/* Guidance Alert Banner */}
      <div className="bg-blue-50 border border-blue-100 p-4 rounded-xl text-xs text-blue-800 flex items-start space-x-3">
        <Info className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
        <div>
          <p className="font-semibold text-sm">How Category Benchmark Rates Work:</p>
          <p className="mt-0.5">
            When employers create a job on the mobile app, the Smart Pricing Calculator multiplies these category base hourly rates by estimated work hours, worker count, and task complexity multipliers (<span className="font-semibold">Simple: 1.0x, Moderate: 1.3x, Complex: 1.6x</span>).
          </p>
        </div>
      </div>

      {/* Category Rates Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {rates.map((item, idx) => (
          <div
            key={item.category}
            className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm space-y-3"
          >
            <div className="flex items-center justify-between">
              <span className="font-semibold text-gray-900 text-base">{item.category}</span>
              <span className="text-xs bg-gray-100 text-gray-600 font-medium px-2.5 py-1 rounded-full">
                Base Rate
              </span>
            </div>

            <div className="space-y-1">
              <label className="text-xs font-medium text-gray-500">Benchmark Hourly Rate (KES/hr)</label>
              <div className="relative">
                <span className="absolute left-3 top-2.5 text-xs font-semibold text-gray-400">KES</span>
                <input
                  type="number"
                  value={item.baseHourlyRateKES}
                  onChange={(e) => handleRateChange(idx, Number(e.target.value) || 0)}
                  className="w-full pl-12 pr-4 py-2 border border-gray-200 rounded-lg text-sm font-semibold text-gray-900 focus:outline-none focus:border-green-600"
                />
              </div>
            </div>

            <div className="text-xs text-gray-400 flex justify-between pt-1">
              <span>Standard 4-hr Job:</span>
              <span className="font-semibold text-green-700">
                KES {(item.baseHourlyRateKES * 4).toLocaleString()}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
