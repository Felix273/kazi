"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import { AlertTriangle, ShieldCheck, CheckCircle2 } from "lucide-react";

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
        // Mock fallback data
        setDisputes([
          {
            id: "dispute_001",
            jobId: "job_001",
            applicationId: "job_001_worker_123",
            reporterId: "employer_456",
            reportedId: "worker_123",
            reason: "incomplete_work",
            reasonLabel: "Incomplete Job Execution",
            description: "Worker left plumbing pipes unfinished without proper sealing.",
            photoUrls: [],
            status: "open",
          },
        ]);
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
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dispute Resolution Center</h1>
        <p className="text-gray-500 text-sm mt-1">
          Review filed grievances, inspect frozen escrow payments, and adjudicate resolutions
        </p>
      </div>

      {/* Disputes Queue */}
      <div className="space-y-4">
        {loading ? (
          <div className="p-12 text-center text-gray-400 bg-white rounded-xl border border-gray-100 text-sm">
            Loading dispute queue...
          </div>
        ) : disputes.length === 0 ? (
          <div className="p-12 text-center text-gray-400 bg-white rounded-xl border border-gray-100 text-sm">
            No active disputes found.
          </div>
        ) : (
          disputes.map((dispute) => (
            <div
              key={dispute.id}
              className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm space-y-4"
            >
              <div className="flex items-center justify-between border-b border-gray-100 pb-4">
                <div className="flex items-center space-x-3">
                  <div className="p-2 bg-red-50 text-red-700 rounded-lg">
                    <AlertTriangle className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="font-bold text-gray-900">
                      {dispute.reasonLabel || dispute.reason || "Job Dispute"}
                    </h3>
                    <p className="text-xs text-gray-400">
                      Dispute ID: {dispute.id} | Job ID: {dispute.jobId}
                    </p>
                  </div>
                </div>

                <span
                  className={`px-3 py-1 rounded-full text-xs font-semibold capitalize ${
                    dispute.status === "open"
                      ? "bg-red-100 text-red-800"
                      : "bg-green-100 text-green-800"
                  }`}
                >
                  {dispute.status || "open"}
                </span>
              </div>

              {/* Description */}
              <div className="bg-gray-50 p-4 rounded-lg text-sm text-gray-700">
                <p className="font-medium text-xs text-gray-500 mb-1">Filing Description:</p>
                {dispute.description || "No description provided."}
              </div>

              {/* Adjudication Panel (If Open) */}
              {dispute.status === "open" ? (
                <div className="border-t border-gray-100 pt-4 space-y-3">
                  <h4 className="text-xs font-bold text-gray-900 uppercase tracking-wider">
                    Admin Adjudication
                  </h4>
                  <textarea
                    rows={3}
                    placeholder="Enter official resolution decision and details..."
                    value={resolutionNote}
                    onChange={(e) => setResolutionNote(e.target.value)}
                    className="w-full p-3 border border-gray-200 rounded-lg text-sm focus:outline-none focus:border-green-600"
                  />

                  <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
                    <label className="flex items-center space-x-2 text-xs font-medium text-gray-700 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={releasePayment}
                        onChange={(e) => setReleasePayment(e.target.checked)}
                        className="rounded border-gray-300 text-green-700 focus:ring-green-600"
                      />
                      <span>Release escrowed funds upon resolution</span>
                    </label>

                    <button
                      disabled={resolvingId === dispute.id}
                      onClick={() => handleResolveDispute(dispute.id)}
                      className="px-4 py-2 bg-slate-900 text-white rounded-lg text-xs font-semibold hover:bg-slate-800 disabled:opacity-50"
                    >
                      {resolvingId === dispute.id ? "Resolving..." : "Finalize & Resolve Dispute"}
                    </button>
                  </div>
                </div>
              ) : (
                <div className="flex items-center space-x-2 text-xs text-green-700 bg-green-50 p-3 rounded-lg">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>
                    Resolved: {dispute.resolution || "Case adjudicated and closed."}
                  </span>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
