"use client";

import React, { useEffect, useState } from "react";
import { collection, onSnapshot, query, orderBy } from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import { Users, CheckCircle, XCircle, Clock, ShieldCheck, Search } from "lucide-react";

interface UserItem {
  id: string;
  name?: string;
  phone?: string;
  email?: string;
  role?: string;
  verificationStatus?: string;
  isVerified?: boolean;
  averageRating?: number;
  totalJobsCompleted?: number;
}

export default function UserManagementPage() {
  const [users, setUsers] = useState<UserItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => {
    const q = query(collection(db, "users"), orderBy("createdAt", "desc"));
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const list: UserItem[] = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setUsers(list);
        setLoading(false);
      },
      () => {
        // Fallback mock data if Firestore connection is empty
        setUsers([
          {
            id: "user_001",
            name: "John Kamau",
            phone: "+254712345678",
            email: "john.kamau@example.com",
            role: "jobseeker",
            verificationStatus: "pending",
            isVerified: false,
            averageRating: 4.8,
            totalJobsCompleted: 12,
          },
          {
            id: "user_002",
            name: "Mary Wambui",
            phone: "+254722987654",
            email: "mary.wambui@example.com",
            role: "employer",
            verificationStatus: "verified",
            isVerified: true,
            averageRating: 5.0,
            totalJobsCompleted: 4,
          },
        ]);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  const handleReviewVerification = async (
    userId: string,
    approved: boolean
  ) => {
    setProcessingId(userId);
    try {
      const reviewFn = httpsCallable(functions, "reviewUserVerification");
      await reviewFn({
        userId,
        approved,
        rejectionReason: approved ? null : "Identity document mismatch or illegible image.",
      });
      alert(`User identity verification successfully ${approved ? "approved" : "rejected"}.`);
    } catch (err: any) {
      alert(`Verification update error: ${err.message || err}`);
    } finally {
      setProcessingId(null);
    }
  };

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      (u.name || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
      (u.phone || "").includes(searchTerm) ||
      (u.email || "").toLowerCase().includes(searchTerm.toLowerCase());

    if (statusFilter === "pending") {
      return matchesSearch && u.verificationStatus === "pending";
    }
    if (statusFilter === "verified") {
      return matchesSearch && u.verificationStatus === "verified";
    }
    return matchesSearch;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">User & KYC Verification</h1>
          <p className="text-gray-500 text-sm mt-1">
            Manage user profiles, view Smile Identity verification statuses, and review KYC approvals
          </p>
        </div>
      </div>

      {/* Filters and Search Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-white p-4 rounded-xl border border-gray-100 shadow-sm">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
          <input
            type="text"
            placeholder="Search by name, phone or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:border-green-600"
          />
        </div>

        <div className="flex items-center space-x-2 w-full sm:w-auto">
          <button
            onClick={() => setStatusFilter("all")}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              statusFilter === "all"
                ? "bg-slate-900 text-white"
                : "bg-gray-100 text-gray-600 hover:bg-gray-200"
            }`}
          >
            All Users
          </button>
          <button
            onClick={() => setStatusFilter("pending")}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              statusFilter === "pending"
                ? "bg-amber-600 text-white"
                : "bg-amber-50 text-amber-700 hover:bg-amber-100"
            }`}
          >
            Pending Review
          </button>
          <button
            onClick={() => setStatusFilter("verified")}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              statusFilter === "verified"
                ? "bg-green-700 text-white"
                : "bg-green-50 text-green-700 hover:bg-green-100"
            }`}
          >
            Verified
          </button>
        </div>
      </div>

      {/* Users Data Table */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        {loading ? (
          <div className="p-12 text-center text-gray-400 text-sm">Loading users...</div>
        ) : filteredUsers.length === 0 ? (
          <div className="p-12 text-center text-gray-400 text-sm">No users match your criteria.</div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                <th className="py-3 px-4">User</th>
                <th className="py-3 px-4">Role</th>
                <th className="py-3 px-4">Rating & Jobs</th>
                <th className="py-3 px-4">Verification Status</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50/50">
                  <td className="py-3.5 px-4">
                    <div className="font-semibold text-gray-900">{user.name || "Unnamed User"}</div>
                    <div className="text-xs text-gray-400">{user.phone || user.email || user.id}</div>
                  </td>
                  <td className="py-3.5 px-4">
                    <span
                      className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${
                        user.role === "employer"
                          ? "bg-blue-50 text-blue-700 border border-blue-200"
                          : "bg-emerald-50 text-emerald-700 border border-emerald-200"
                      }`}
                    >
                      {user.role || "jobseeker"}
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-xs text-gray-600">
                    <div>⭐ {user.averageRating ? user.averageRating.toFixed(1) : "0.0"}</div>
                    <div className="text-gray-400">{user.totalJobsCompleted || 0} jobs completed</div>
                  </td>
                  <td className="py-3.5 px-4">
                    {user.verificationStatus === "verified" || user.isVerified ? (
                      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800">
                        <CheckCircle className="w-3.5 h-3.5 mr-1" /> Verified
                      </span>
                    ) : user.verificationStatus === "pending" ? (
                      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">
                        <Clock className="w-3.5 h-3.5 mr-1" /> Pending KYC Review
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-600">
                        Not Verified
                      </span>
                    )}
                  </td>
                  <td className="py-3.5 px-4 text-right">
                    {user.verificationStatus === "pending" ? (
                      <div className="flex items-center justify-end space-x-2">
                        <button
                          disabled={processingId === user.id}
                          onClick={() => handleReviewVerification(user.id, true)}
                          className="px-2.5 py-1 bg-green-700 text-white rounded text-xs font-semibold hover:bg-green-800 disabled:opacity-50"
                        >
                          Approve
                        </button>
                        <button
                          disabled={processingId === user.id}
                          onClick={() => handleReviewVerification(user.id, false)}
                          className="px-2.5 py-1 bg-red-600 text-white rounded text-xs font-semibold hover:bg-red-700 disabled:opacity-50"
                        >
                          Reject
                        </button>
                      </div>
                    ) : (
                      <span className="text-xs text-gray-400">No action needed</span>
                    )}
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
