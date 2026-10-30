"use client";

import React, { useState, useEffect } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { useRouter } from "next/navigation";
import QRCode from "qrcode";
import { auth } from "@/lib/firebase";
import { generateBase32Secret, verifyTOTP } from "@/lib/totp";
import { Shield, Lock, Mail, KeyRound, Smartphone, Copy, Check, ArrowRight, CheckCircle2, QrCode } from "lucide-react";

export default function AdminLoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [totpCode, setTotpCode] = useState("");
  const [step, setStep] = useState<"credentials" | "totp" | "setup">("credentials");
  const [secret, setSecret] = useState<string>("");
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string>("");
  const [copiedSecret, setCopiedSecret] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  // Generate QR Code data URL whenever secret or email changes
  useEffect(() => {
    if (secret && email) {
      const otpAuthUrl = `otpauth://totp/Kazi%20Admin:${encodeURIComponent(email)}?secret=${secret}&issuer=Kazi%20Marketplace`;
      QRCode.toDataURL(otpAuthUrl, { margin: 1, width: 220 }, (err, url) => {
        if (!err && url) {
          setQrCodeDataUrl(url);
        }
      });
    }
  }, [secret, email]);

  // Step 1: Verify Email & Password
  const handleCredentialLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await signInWithEmailAndPassword(auth, email, password);

      const savedSecret = localStorage.getItem(`kazi_admin_2fa_${email.toLowerCase()}`);
      if (savedSecret) {
        setSecret(savedSecret);
        setStep("totp");
      } else {
        const newSecret = generateBase32Secret();
        setSecret(newSecret);
        setStep("setup");
      }
    } catch (err: any) {
      setError(err.message || "Failed to authenticate credentials");
    } finally {
      setLoading(false);
    }
  };

  // Step 2: Verify TOTP Authenticator Code
  const handleVerifyTOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const isValid = await verifyTOTP(totpCode, secret);
      if (isValid) {
        localStorage.setItem(`kazi_admin_2fa_${email.toLowerCase()}`, secret);
        router.push("/");
      } else {
        setError("Invalid 6-digit authenticator code. Please check your Authenticator app.");
      }
    } catch (err: any) {
      setError(`Verification error: ${err.message || err}`);
    } finally {
      setLoading(false);
    }
  };

  const copySecretToClipboard = () => {
    navigator.clipboard.writeText(secret);
    setCopiedSecret(true);
    setTimeout(() => setCopiedSecret(false), 2000);
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4 selection:bg-emerald-500 selection:text-white">
      <div className="bg-white w-full max-w-md p-8 rounded-3xl shadow-2xl border border-slate-100 space-y-6">
        {/* Header Branding */}
        <div className="text-center space-y-2">
          <div className="w-12 h-12 bg-emerald-100 text-emerald-800 rounded-2xl flex items-center justify-center mx-auto shadow-inner">
            <Shield className="w-6 h-6 text-emerald-600" />
          </div>
          <h1 className="text-2xl font-black text-slate-900 tracking-tight">Kazi Executive Admin</h1>
          <p className="text-xs text-slate-500">2-Factor Authenticator App (RFC 6238)</p>
        </div>

        {error && (
          <div className="p-3 bg-rose-50 border border-rose-200 text-rose-800 text-xs rounded-xl font-semibold">
            {error}
          </div>
        )}

        {/* STEP 1: EMAIL & PASSWORD */}
        {step === "credentials" && (
          <form onSubmit={handleCredentialLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Admin Email
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@kazi.co.ke"
                  className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-emerald-600 transition-all font-medium"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:bg-white focus:outline-none focus:border-emerald-600 transition-all font-medium"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-slate-900 text-white font-bold text-xs rounded-xl hover:bg-slate-800 transition-all shadow-md shadow-slate-900/10 flex items-center justify-center space-x-2 disabled:opacity-50"
            >
              <span>{loading ? "Validating..." : "Continue to 2FA Verification"}</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>
        )}

        {/* STEP 2: TOTP CODE VERIFICATION */}
        {step === "totp" && (
          <form onSubmit={handleVerifyTOTP} className="space-y-4">
            <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-600 flex items-center space-x-3">
              <Smartphone className="w-5 h-5 text-emerald-600 shrink-0" />
              <span>Enter the 6-digit code from your Authenticator app (Google Authenticator / Authy / 1Password).</span>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                6-Digit Authenticator Code
              </label>
              <div className="relative">
                <KeyRound className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                <input
                  type="text"
                  required
                  maxLength={6}
                  value={totpCode}
                  onChange={(e) => setTotpCode(e.target.value)}
                  placeholder="123456"
                  className="w-full pl-9 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-lg font-mono font-black tracking-widest text-slate-900 focus:bg-white focus:outline-none focus:border-emerald-600 text-center transition-all"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading || totpCode.length !== 6}
              className="w-full py-3 bg-emerald-600 text-white font-bold text-xs rounded-xl hover:bg-emerald-500 transition-all shadow-md shadow-emerald-600/20 flex items-center justify-center space-x-2 disabled:opacity-50"
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>{loading ? "Verifying Token..." : "Authenticate & Open Dashboard"}</span>
            </button>

            <button
              type="button"
              onClick={() => setStep("credentials")}
              className="w-full text-xs text-slate-500 hover:text-slate-900 font-semibold pt-2 text-center block"
            >
              Back to Credentials
            </button>
          </form>
        )}

        {/* STEP 3: SCAN QR CODE TO ENROLL AUTHENTICATOR APP */}
        {step === "setup" && (
          <div className="space-y-4 text-center">
            <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-xs text-emerald-800 space-y-1 text-left">
              <p className="font-bold flex items-center gap-1.5">
                <QrCode className="w-4 h-4 text-emerald-600" /> Scan QR Code with Authenticator App
              </p>
              <p className="text-[11px] text-emerald-700">
                Open Google Authenticator, Authy, or 1Password on your smartphone and scan this QR code:
              </p>
            </div>

            {/* Rendered QR Code Image */}
            <div className="p-4 bg-slate-50 border border-slate-200 rounded-2xl flex flex-col items-center justify-center space-y-2">
              {qrCodeDataUrl ? (
                <img
                  src={qrCodeDataUrl}
                  alt="2FA QR Code"
                  className="w-48 h-48 rounded-xl shadow-md border border-slate-200"
                />
              ) : (
                <div className="w-48 h-48 bg-slate-200 animate-pulse rounded-xl flex items-center justify-center text-xs text-slate-500">
                  Generating QR...
                </div>
              )}
              <span className="text-[10px] text-slate-400 font-mono uppercase">Scan to Enroll Admin</span>
            </div>

            {/* Base32 Key Fallback */}
            <div className="p-3 bg-slate-950 text-white rounded-xl space-y-1 text-left border border-slate-800">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest block">
                Manual Entry Key
              </span>
              <div className="flex items-center justify-between">
                <span className="font-mono text-xs font-black tracking-widest text-emerald-400">{secret}</span>
                <button
                  onClick={copySecretToClipboard}
                  className="p-1 bg-slate-800 hover:bg-slate-700 rounded text-slate-300 transition-colors"
                >
                  {copiedSecret ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>

            <button
              onClick={() => setStep("totp")}
              className="w-full py-3 bg-slate-900 text-white font-bold text-xs rounded-xl hover:bg-slate-800 transition-all shadow-md flex items-center justify-center space-x-2"
            >
              <span>I Have Scanned the QR Code – Continue</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
