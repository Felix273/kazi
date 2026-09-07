"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { Briefcase, DollarSign, MapPin, Search } from "lucide-react";

interface JobItem {
  id: string;
  title?: string;
  category?: string;
  employerName?: string;
  salaryKES?: number;
  employerPaysKES?: number;
  workerEarnsKES?: number;
  platformFeeKES?: number;
  status?: string;
  paymentStatus?: string;
  neighborhood?: string;
  createdAt?: any;
}

export default function JobsPage() {
  const [jobs, setJobs] = useState<JobItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  useEffect(() => {
    const q = query(collection(db, "jobs"), orderBy("createdAt", "desc"));
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const list: JobItem[] = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setJobs(list);
        setLoading(false);
      },
      () => {
        // Mock fallback data
        setJobs([
          {
            id: "job_001",
            title: "Plumbing Repair & Pipe Replacement",
            category: "Plumbing",
            employerName: "Kileleshwa Estates",
            salaryKES: 3500,
            employerPaysKES: 3850,
            workerEarnsKES: 3325,
            platformFeeKES: 525,
            status: "hired",
            paymentStatus: "escrowed",
            neighborhood: "Kileleshwa",
          },
          {
            id: "job_002",
            title: "House Deep Cleaning (3 Bedrooms)",
            category: "Cleaning",
            employerName: "Jane Doe",
            salaryKES: 2500,
            employerPaysKES: 2750,
            workerEarnsKES: 2375,
            platformFeeKES: 375,
            status: "open",
            paymentStatus: "not_started",
            neighborhood: "Westlands",
          },
        ]);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  const filteredJobs = jobs.filter((j) => {
    const matchesSearch =
      (j.title || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
      (j.employerName || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
      (j.neighborhood || "").toLowerCase().includes(searchTerm.toLowerCase());

    if (statusFilter === "open") return matchesSearch && j.status === "open";
    if (statusFilter === "hired") return matchesSearch && j.status === "hired";
    if (statusFilter === "completed") return matchesSearch && j.status === "completed";
    return matchesSearch;
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Job Lifecycle & Escrow Monitor</h1>
        <p className="text-gray-500 text-sm mt-1">
          Track posted jobs, M-Pesa escrow statuses, and platform fee distributions across Nairobi
        </p>
      </div>

      {/* Filters and Search */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-white p-4 rounded-xl border border-gray-100 shadow-sm">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
          <input
            type="text"
            placeholder="Search job title, employer or location..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:border-green-600"
          />
        </div>

        <div className="flex items-center space-x-2 w-full sm:w-auto">
          <button
            onClick={() => setStatusFilter("all")}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold ${
              statusFilter === "all"
                ? "bg-slate-900 text-white"
                : "bg-gray-100 text-gray-600 hover:bg-gray-200"
            }`}
          >
            All Jobs
          </button>
          <button
            onClick={() => setStatusFilter("open")}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold ${
              statusFilter === "open"
                ? "bg-green-700 text-white"
                : "bg-green-50 text-green-700 hover:bg-green-100"
            }`}
          >
            Open
          </button>
          <button
            onClick={() => setStatusFilter("hired")}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold ${
              statusFilter === "hired"
                ? "bg-blue-700 text-white"
                : "bg-blue-50 text-blue-700 hover:bg-blue-100"
            }`}
          >
            Hired / Escrow Held
          </button>
        </div>
      </div>

      {/* Jobs Table */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-gray-400 text-sm">Loading job records...</div>
        ) : filteredJobs.length === 0 ? (
          <div className="p-12 text-center text-gray-400 text-sm">No jobs match your search.</div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                <th className="py-3 px-4">Job Details</th>
                <th className="py-3 px-4">Employer</th>
                <th className="py-3 px-4">Financials (KES)</th>
                <th className="py-3 px-4">Job Status</th>
                <th className="py-3 px-4">Escrow Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {filteredJobs.map((job) => (
                <tr key={job.id} className="hover:bg-gray-50/50">
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-gray-900">{job.title || "Untitled Job"}</div>
                    <div className="text-xs text-gray-400 flex items-center mt-0.5">
                      <MapPin className="w-3 h-3 mr-1" /> {job.neighborhood || "Nairobi"}
                    </div>
                  </td>
                  <td className="py-3.5 px-4 text-xs font-medium text-gray-700">
                    {job.employerName || "Employer"}
                  </td>
                  <td className="py-3.5 px-4 text-xs">
                    <div className="font-semibold text-gray-900">
                      Total: KES {job.employerPaysKES || job.salaryKES || 0}
                    </div>
                    <div className="text-emerald-600">
                      Worker Earns: KES {job.workerEarnsKES || 0}
                    </div>
                    <div className="text-gray-400">
                      Fee: KES {job.platformFeeKES || 0}
                    </div>
                  </td>
                  <td className="py-3.5 px-4">
                    <span
                      className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold capitalize ${
                        job.status === "open"
                          ? "bg-green-100 text-green-800"
                          : job.status === "hired"
                          ? "bg-blue-100 text-blue-800"
                          : "bg-gray-100 text-gray-700"
                      }`}
                    >
                      {job.status || "open"}
                    </span>
                  </td>
                  <td className="py-3.5 px-4">
                    <span
                      className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                        job.paymentStatus === "escrowed"
                          ? "bg-emerald-100 text-emerald-800"
                          : job.paymentStatus === "released"
                          ? "bg-blue-100 text-blue-800"
                          : "bg-gray-100 text-gray-600"
                      }`}
                    >
                      {job.paymentStatus || "not_started"}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
