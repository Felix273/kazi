"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { MapPin, Briefcase, Search, Activity, Building2 } from "lucide-react";

interface NeighborhoodStats {
  neighborhood: string;
  jobCount: number;
  activeCount: number;
  totalVolumeKES: number;
  avgSalaryKES: number;
}

const nairobiNeighborhoodsList = [
  "Westlands",
  "CBD",
  "Kilimani",
  "Karen",
  "Eastlands",
  "Kasarani",
  "Lavington",
  "Parklands",
  "Thika Rd",
  "Kileleshwa",
  "Langata",
  "Hurlingham",
  "Kensington",
  "Spring Valley",
  "Muthaiga",
  "Runda",
  "Gigiri",
  "Loresho",
  "Kitisuru",
];

export default function NeighborhoodsPage() {
  const [stats, setStats] = useState<NeighborhoodStats[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, "jobs"),
      (snapshot) => {
        const map = new Map<string, { jobCount: number; activeCount: number; totalVolume: number }>();

        // Initialize known neighborhoods
        nairobiNeighborhoodsList.forEach((n) => {
          map.set(n, { jobCount: 0, activeCount: 0, totalVolume: 0 });
        });

        snapshot.docs.forEach((doc) => {
          const data = doc.data();
          const hood = data.neighborhood || "Westlands";
          const salary = Number(data.salaryKES || 0);
          const status = data.status || "open";

          const current = map.get(hood) || { jobCount: 0, activeCount: 0, totalVolume: 0 };
          current.jobCount += 1;
          if (status === "open" || status === "hired") {
            current.activeCount += 1;
          }
          current.totalVolume += salary;
          map.set(hood, current);
        });

        const list: NeighborhoodStats[] = Array.from(map.entries()).map(([hood, val]) => ({
          neighborhood: hood,
          jobCount: val.jobCount,
          activeCount: val.activeCount,
          totalVolumeKES: val.totalVolume,
          avgSalaryKES: val.jobCount > 0 ? Math.round(val.totalVolume / val.jobCount) : 0,
        }));

        setStats(list);
        setLoading(false);
      },
      () => {
        setStats(getMockNeighborhoodStats());
        setLoading(false);
      }
    );

    return () => unsub();
  }, []);

  const filtered = stats.filter((s) =>
    s.neighborhood.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 flex items-center space-x-2">
          <MapPin className="w-6 h-6 text-green-700" />
          <span>Nairobi Neighborhood Activity Breakdown</span>
        </h1>
        <p className="text-gray-500 text-sm mt-1">
          Monitor job density, work distribution, and average salary levels across Nairobi locations
        </p>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-100 shadow-sm flex items-center">
        <div className="relative w-full max-w-md">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
          <input
            type="text"
            placeholder="Search neighborhood (e.g. Westlands, Kilimani, Karen)..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:border-green-600"
          />
        </div>
      </div>

      {/* Neighborhood Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map((item) => (
          <div key={item.neighborhood} className="bg-white p-5 rounded-xl border border-gray-100 shadow-sm space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Building2 className="w-4 h-4 text-green-700" />
                <span className="font-semibold text-gray-900 text-base">{item.neighborhood}</span>
              </div>
              <span className="text-xs bg-green-50 text-green-700 font-semibold px-2.5 py-0.5 rounded-full">
                {item.activeCount} Active
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2 text-xs pt-1">
              <div className="bg-gray-50 p-2.5 rounded-lg">
                <span className="text-gray-500 block">Total Jobs</span>
                <span className="font-bold text-gray-900 text-sm">{item.jobCount}</span>
              </div>
              <div className="bg-gray-50 p-2.5 rounded-lg">
                <span className="text-gray-500 block">Avg Salary</span>
                <span className="font-bold text-green-700 text-sm">
                  KES {item.avgSalaryKES > 0 ? item.avgSalaryKES.toLocaleString() : "2,500"}
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function getMockNeighborhoodStats(): NeighborhoodStats[] {
  return nairobiNeighborhoodsList.map((n, idx) => ({
    neighborhood: n,
    jobCount: 12 + (idx % 5) * 3,
    activeCount: 4 + (idx % 3) * 2,
    totalVolumeKES: 35000 + idx * 2500,
    avgSalaryKES: 2500 + (idx % 4) * 300,
  }));
}
