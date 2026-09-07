import React from 'react';
import Link from 'next/link';
import {
  Briefcase,
  Users,
  AlertTriangle,
  ShieldCheck,
  TrendingUp,
  CheckCircle,
  Clock,
  ArrowUpRight
} from 'lucide-react';

export default function DashboardOverview() {
  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
        <p className="text-gray-500 text-sm mt-1">Real-time marketplace activity & metrics across Nairobi</p>
      </div>

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
            <span className="text-3xl font-bold text-gray-900">142</span>
            <span className="text-xs text-green-600 font-semibold flex items-center">
              +12.5% <ArrowUpRight className="w-3 h-3 ml-0.5" />
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
            <span className="text-3xl font-bold text-gray-900">18</span>
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
            <span className="text-3xl font-bold text-gray-900">3</span>
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
            <span className="text-3xl font-bold text-gray-900">KES 485,200</span>
            <span className="text-xs text-blue-600 font-semibold">M-Pesa</span>
          </div>
          <p className="text-xs text-gray-400 mt-1">Total escrow processed</p>
        </div>
      </div>

      {/* Quick Action Navigation Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Link href="/users" className="group bg-white p-6 rounded-xl border border-gray-100 shadow-sm hover:border-green-600 transition-all">
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-green-100 text-green-800 rounded-xl group-hover:bg-green-700 group-hover:text-white transition-colors">
              <Users className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900 group-hover:text-green-700">User Management</h3>
              <p className="text-xs text-gray-500 mt-0.5">Review KYC identity submissions & ratings</p>
            </div>
          </div>
        </Link>

        <Link href="/jobs" className="group bg-white p-6 rounded-xl border border-gray-100 shadow-sm hover:border-green-600 transition-all">
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-green-100 text-green-800 rounded-xl group-hover:bg-green-700 group-hover:text-white transition-colors">
              <Briefcase className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900 group-hover:text-green-700">Job Lifecycle</h3>
              <p className="text-xs text-gray-500 mt-0.5">Monitor open posts & escrow allocations</p>
            </div>
          </div>
        </Link>

        <Link href="/disputes" className="group bg-white p-6 rounded-xl border border-gray-100 shadow-sm hover:border-green-600 transition-all">
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-green-100 text-green-800 rounded-xl group-hover:bg-green-700 group-hover:text-white transition-colors">
              <AlertTriangle className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900 group-hover:text-green-700">Dispute Center</h3>
              <p className="text-xs text-gray-500 mt-0.5">Resolve employer & worker disputes</p>
            </div>
          </div>
        </Link>
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
