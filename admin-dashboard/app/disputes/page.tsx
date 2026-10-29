"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import { AlertTriangle, ShieldCheck, CheckCircle2, TrendingUp } from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";

interface DisputeItem {
  id: string;
  jobId?: string;
  applicationId?: string;
  reporterId?: string;
  reportedId?: string;
  reason?: string;
  reasonLabel?: string;
  description?: string;
  photoUrls?: string[];
  status?: string;
  resolution?: string;
  createdAt?: any;
}

const disputeTrendMock = [
  { month: "Jan", open: 3, resolved: 12 },
  { month: "Feb", open: 2, resolved: 15 },
  { month: "Mar", open: 4, resolved: 18 },
  { month: "Apr", open: 1, resolved: 14 },
  { month: "May", open: 2, resolved: 22 },
  { month: "Jun", open: 0, resolved: 19 },
];

export default function DisputeCenterPage() {
  const [disputes, setDisputes] = useState<DisputeItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [resolvingId, setResolvingId] = useState<string | null>(null);
  const [resolutionNote, setResolutionNote] = useState<string>("");
  const [releasePayment, setReleasePayment] = useState<boolean>(true);

  useEffect(() => {
    const q = query(collection(db, "disputes"), orderBy("createdAt", "desc"));
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const list: DisputeItem[] = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setDisputes(list);
        setLoading(false);
      },
      () => {
        setDisputes([]);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  const handleResolveDispute = async (disputeId: string) => {
    if (!resolutionNote.trim()) {
      alert("Please enter a resolution summary note.");
      return;
    }
    setResolvingId(disputeId);
    try {
      const resolveFn = httpsCallable(functions, "resolveDispute");
      await resolveFn({
        disputeId,
        resolution: resolutionNote,
        releasePayment,
      });
      alert("Dispute successfully resolved!");
      setResolutionNote("");
    } catch (err: any) {
      alert(`Error resolving dispute: ${err.message || err}`);
    } finally {
      setResolvingId(null);
    }
  };

  return (
    <div className="space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800/80 pb-6">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase bg-rose-500/10 text-rose-400 border border-rose-500/20">
              Escrow Protection
            </span>
            <span className="text-xs text-slate-400 font-mono">Platform Dispute Center</span>
          </div>
          <h1 className="text-3xl font-black text-white tracking-tight">Dispute Resolution Center</h1>
          <p className="text-slate-400 text-xs mt-1">
            Review filed grievances, inspect frozen M-Pesa escrow payments & adjudicate resolutions
          </p>
        </div>
      </div>

      {/* Resolution Velocity Chart */}
      <div className="bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-bold text-white text-sm flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-rose-400" /> Dispute Filing vs Adjudication Resolution Rate
            </h3>
            <p className="text-xs text-slate-400">Monthly dispute resolution velocity</p>
          </div>
        </div>

        <div className="h-56 w-full pt-4">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={disputeTrendMock}>
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
              <Bar dataKey="resolved" fill="#10b981" radius={[6, 6, 0, 0]} name="Resolved Disputes" />
              <Bar dataKey="open" fill="#f43f5e" radius={[6, 6, 0, 0]} name="Open Grievances" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Disputes Queue */}
      <div className="space-y-4">
        {loading ? (
          <div className="p-12 text-center text-slate-500 bg-slate-900/60 rounded-2xl border border-slate-800/80 text-xs">
            Loading dispute queue...
          </div>
        ) : disputes.length === 0 ? (
          <div className="p-12 text-center text-slate-400 bg-slate-900/60 rounded-2xl border border-slate-800/80 text-xs space-y-2">
            <CheckCircle2 className="w-8 h-8 text-emerald-400 mx-auto" />
            <p className="font-bold text-white text-sm">Zero Open Disputes</p>
            <p className="text-slate-500 text-xs">All M-Pesa escrows and worker jobs are operating cleanly!</p>
          </div>
        ) : (
          disputes.map((dispute) => (
            <div
              key={dispute.id}
              className="bg-slate-900/60 backdrop-blur-md p-6 rounded-2xl border border-slate-800/80 space-y-4 shadow-lg"
            >
              <div className="flex items-center justify-between border-b border-slate-800/80 pb-4">
                <div className="flex items-center space-x-3">
                  <div className="p-2.5 bg-rose-500/10 text-rose-400 rounded-xl border border-rose-500/20">
                    <AlertTriangle className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="font-bold text-white text-sm">
                      {dispute.reasonLabel || dispute.reason || "Job Dispute"}
                    </h3>
                    <p className="text-xs text-slate-400 font-mono">
                      Dispute ID: {dispute.id} | Job ID: {dispute.jobId}
                    </p>
                  </div>
                </div>

                <span
                  className={`px-3 py-1 rounded-full text-xs font-semibold capitalize border ${
                    dispute.status === "open"
                      ? "bg-rose-500/10 text-rose-400 border-rose-500/20"
                      : "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
                  }`}
                >
                  {dispute.status || "open"}
                </span>
              </div>

              <div className="bg-slate-950/60 p-4 rounded-xl text-xs text-slate-300 border border-slate-800/80">
                <p className="font-bold text-slate-400 uppercase text-[10px] tracking-wider mb-1">
                  Filing Description:
                </p>
                {dispute.description || "No description provided."}
              </div>

              {dispute.status === "open" ? (
                <div className="border-t border-slate-800/80 pt-4 space-y-3">
                  <h4 className="text-xs font-bold text-white uppercase tracking-wider">
                    Admin Adjudication Panel
                  </h4>
                  <textarea
                    rows={3}
                    placeholder="Enter official resolution decision and details..."
                    value={resolutionNote}
                    onChange={(e) => setResolutionNote(e.target.value)}
                    className="w-full p-3 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500 transition-colors"
                  />

                  <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
                    <label className="flex items-center space-x-2 text-xs font-medium text-slate-300 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={releasePayment}
                        onChange={(e) => setReleasePayment(e.target.checked)}
                        className="rounded border-slate-700 bg-slate-950 text-emerald-500 focus:ring-emerald-500"
                      />
                      <span>Release escrowed funds to worker upon resolution</span>
                    </label>

                    <button
                      disabled={resolvingId === dispute.id}
                      onClick={() => handleResolveDispute(dispute.id)}
                      className="px-5 py-2.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold rounded-xl text-xs transition-all shadow-lg shadow-emerald-500/20 disabled:opacity-50"
                    >
                      {resolvingId === dispute.id ? "Resolving..." : "Finalize & Resolve Dispute"}
                    </button>
                  </div>
                </div>
              ) : (
                <div className="flex items-center space-x-2 text-xs text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 p-3 rounded-xl">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Resolved: {dispute.resolution || "Case adjudicated and closed."}</span>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
