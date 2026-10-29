"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext";
import {
  Briefcase,
  Users,
  AlertTriangle,
  ShieldCheck,
  TrendingUp,
  CheckCircle,
  Calculator,
  MapPin,
  Activity,
  Clock,
  Zap,
  LogIn,
  Lock,
} from "lucide-react";

interface ActivityItem {
  id: string;
  type: "job_posted" | "job_hired" | "checkin" | "dispute";
  title: string;
  subtitle: string;
  timestamp: string;
  badgeColor: string;
}

export default function DashboardOverview() {
  const { user } = useAuth();
  const [activeJobsCount, setActiveJobsCount] = useState<number>(0);
  const [pendingKycCount, setPendingKycCount] = useState<number>(0);
  const [openDisputesCount, setOpenDisputesCount] = useState<number>(0);
  const [totalEscrowVolume, setTotalEscrowVolume] = useState<number>(0);
  const [recentActivities, setRecentActivities] = useState<ActivityItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [authError, setAuthError] = useState<boolean>(false);

  useEffect(() => {
    setAuthError(false);

    // 1. Listen to jobs collection
    const unsubJobs = onSnapshot(
      collection(db, "jobs"),
      (snapshot) => {
        let activeCount = 0;
        let escrowSum = 0;
        const activities: ActivityItem[] = [];

        snapshot.docs.forEach((doc) => {
          const data = doc.data();
          const status = data.status || "open";
          if (status === "open" || status === "hired") {
            activeCount++;
          }
          if (status === "hired" || data.paymentStatus === "escrowed") {
            escrowSum += Number(data.employerPaysKES || data.salaryKES || 0);
          }

          activities.push({
            id: doc.id,
            type: status === "hired" ? "job_hired" : "job_posted",
            title: data.title || "Untitled Job",
            subtitle: `${data.category || "General"} in ${data.neighborhood || "Nairobi"} • KES ${Number(data.salaryKES || 0).toLocaleString()}`,
            timestamp: data.createdAt ? "Recent" : "Just now",
            badgeColor: status === "hired" ? "bg-blue-100 text-blue-800" : "bg-green-100 text-green-800",
          });
        });

        setActiveJobsCount(activeCount);
        setTotalEscrowVolume(escrowSum);
        setRecentActivities(activities.slice(0, 6));
        setLoading(false);
      },
      (err) => {
        // If not signed in or permission denied
        setAuthError(true);
        setLoading(false);
      }
    );

    // 2. Listen to users collection
    const unsubUsers = onSnapshot(
      collection(db, "users"),
      (snapshot) => {
        let pendingCount = 0;
        snapshot.docs.forEach((doc) => {
          const data = doc.data();
          if (data.kycStatus === "pending" || data.identityStatus === "pending" || data.isVerified === false) {
            pendingCount++;
          }
        });
        setPendingKycCount(pendingCount);
      },
      () => {}
    );

    // 3. Listen to disputes collection
    const unsubDisputes = onSnapshot(
      collection(db, "disputes"),
      (snapshot) => {
        let disputeCount = 0;
        snapshot.docs.forEach((doc) => {
          const data = doc.data();
          if (data.status === "open" || data.status === "under_review" || !data.status) {
            disputeCount++;
          }
        });
        setOpenDisputesCount(disputeCount);
      },
      () => {}
    );

    return () => {
      unsubJobs();
      unsubUsers();
      unsubDisputes();
    };
  }, [user]);

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
        <p className="text-gray-500 text-sm mt-1">Real-time marketplace activity & live metrics across Nairobi</p>
      </div>

      {/* Auth Banner if not signed in */}
      {!user && (
        <div className="bg-amber-50 border border-amber-200 p-4 rounded-xl flex items-center justify-between">
          <div className="flex items-center space-x-3 text-amber-900">
            <Lock className="w-5 h-5 text-amber-700" />
            <div>
              <p className="font-semibold text-sm">Authentication Required for Live Data</p>
              <p className="text-xs text-amber-700 mt-0.5">
                Firestore security rules require logging in to stream live database records.
              </p>
            </div>
          </div>
          <Link
            href="/login"
            className="inline-flex items-center space-x-1 px-4 py-2 bg-amber-700 text-white text-xs font-semibold rounded-lg hover:bg-amber-800 transition-colors"
          >
            <LogIn className="w-3.5 h-3.5" />
            <span>Sign In to Admin</span>
          </Link>
        </div>
      )}

      {/* Primary Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-gray-500 text-sm font-medium">Active Jobs</span>
            <div className="p-2.5 bg-green-50 text-green-700 rounded-lg">
              <Briefcase className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline justify-between">
            <span className="text-3xl font-bold text-gray-900">
              {loading ? "..." : activeJobsCount}
            </span>
            <span className="text-xs text-green-600 font-semibold flex items-center">
              Live <Activity className="w-3 h-3 ml-0.5 animate-pulse" />
            </span>
          </div>
          <p className="text-xs text-gray-400 mt-1">Open & in-progress jobs</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-gray-500 text-sm font-medium">Pending Verifications</span>
            <div className="p-2.5 bg-amber-50 text-amber-700 rounded-lg">
              <ShieldCheck className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline justify-between">
            <span className="text-3xl font-bold text-gray-900">
              {loading ? "..." : pendingKycCount}
            </span>
            <span className="text-xs text-amber-600 font-semibold">Requires Review</span>
          </div>
          <p className="text-xs text-gray-400 mt-1">Smile Identity KYC queue</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-gray-500 text-sm font-medium">Open Disputes</span>
            <div className="p-2.5 bg-red-50 text-red-700 rounded-lg">
              <AlertTriangle className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline justify-between">
            <span className="text-3xl font-bold text-gray-900">
              {loading ? "..." : openDisputesCount}
            </span>
            <span className="text-xs text-red-600 font-semibold">Action Needed</span>
          </div>
          <p className="text-xs text-gray-400 mt-1">Frozen escrow funds</p>
        </div>

        <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-gray-500 text-sm font-medium">Escrow Volume</span>
            <div className="p-2.5 bg-blue-50 text-blue-700 rounded-lg">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4 flex items-baseline justify-between">
            <span className="text-3xl font-bold text-gray-900">
              KES {loading ? "..." : totalEscrowVolume.toLocaleString()}
            </span>
            <span className="text-xs text-blue-600 font-semibold">M-Pesa</span>
          </div>
          <p className="text-xs text-gray-400 mt-1">Total escrow processed</p>
        </div>
      </div>

      {/* Real-Time Activity Feed & Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Activity Stream */}
        <div className="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-100 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Zap className="w-5 h-5 text-amber-500" />
              <h3 className="font-semibold text-gray-900 text-base">Live Activity Stream</h3>
            </div>
            <span className="text-xs text-gray-400 flex items-center">
              <Clock className="w-3.5 h-3.5 mr-1" /> Real-time feed
            </span>
          </div>

          {recentActivities.length === 0 ? (
            <div className="p-8 text-center text-gray-400 text-sm">
              {user ? "No job activity recorded in Firestore yet." : "Please sign in to view live activity."}
            </div>
          ) : (
            <div className="divide-y divide-gray-100 text-sm">
              {recentActivities.map((act) => (
                <div key={act.id} className="py-3.5 flex items-center justify-between hover:bg-gray-50/50 px-2 rounded-lg transition-colors">
                  <div className="space-y-0.5">
                    <div className="font-semibold text-gray-900 flex items-center space-x-2">
                      <span>{act.title}</span>
                    </div>
                    <div className="text-xs text-gray-500 flex items-center">
                      <MapPin className="w-3 h-3 mr-1 text-gray-400" /> {act.subtitle}
                    </div>
                  </div>
                  <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${act.badgeColor}`}>
                    {act.timestamp}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Quick Action Navigation */}
        <div className="space-y-4">
          <h3 className="font-semibold text-gray-900 text-base">Management Modules</h3>

          <Link href="/users" className="group block bg-white p-5 rounded-xl border border-gray-100 shadow-sm hover:border-green-600 transition-all">
            <div className="flex items-center space-x-4">
              <div className="p-3 bg-green-100 text-green-800 rounded-xl group-hover:bg-green-700 group-hover:text-white transition-colors">
                <Users className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 group-hover:text-green-700">User Management</h4>
                <p className="text-xs text-gray-500 mt-0.5">Review KYC identity & ratings</p>
              </div>
            </div>
          </Link>

          <Link href="/jobs" className="group block bg-white p-5 rounded-xl border border-gray-100 shadow-sm hover:border-green-600 transition-all">
            <div className="flex items-center space-x-4">
              <div className="p-3 bg-green-100 text-green-800 rounded-xl group-hover:bg-green-700 group-hover:text-white transition-colors">
                <Briefcase className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 group-hover:text-green-700">Job Lifecycle</h4>
                <p className="text-xs text-gray-500 mt-0.5">Monitor open posts & escrow</p>
              </div>
            </div>
          </Link>

          <Link href="/pricing" className="group block bg-white p-5 rounded-xl border border-gray-100 shadow-sm hover:border-green-600 transition-all">
            <div className="flex items-center space-x-4">
              <div className="p-3 bg-green-100 text-green-800 rounded-xl group-hover:bg-green-700 group-hover:text-white transition-colors">
                <Calculator className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 group-hover:text-green-700">Category Rate Manager</h4>
                <p className="text-xs text-gray-500 mt-0.5">Configure benchmark rates for Nairobi</p>
              </div>
            </div>
          </Link>
        </div>
      </div>

      {/* System Health / Status */}
      <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm space-y-4">
        <h3 className="font-semibold text-gray-900 text-base">Integration Status</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <span className="text-gray-600 font-medium">M-Pesa Daraja Gateway</span>
            <span className="px-2.5 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full flex items-center">
              <CheckCircle className="w-3 h-3 mr-1" /> Active
            </span>
          </div>

          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <span className="text-gray-600 font-medium">Smile Identity KYC</span>
            <span className="px-2.5 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full flex items-center">
              <CheckCircle className="w-3 h-3 mr-1" /> Active
            </span>
          </div>

          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <span className="text-gray-600 font-medium">FCM Push Messaging</span>
            <span className="px-2.5 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full flex items-center">
              <CheckCircle className="w-3 h-3 mr-1" /> Active
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
