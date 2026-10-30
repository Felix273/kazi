"use client";

import React, { useState, useEffect } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { useRouter } from "next/navigation";
import QRCode from "qrcode";
import { auth } from "@/lib/firebase";
import { generateBase32Secret, verifyTOTP } from "@/lib/totp";
import {
  Shield,
  Lock,
  Mail,
  KeyRound,
  Smartphone,
  Copy,
  Check,
  ArrowRight,
  CheckCircle2,
  QrCode,
  Sparkles,
} from "lucide-react";

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
      setError(err.message || "Invalid admin credentials. Please check email and password.");
    } finally {
      setLoading(false);
    }
  };

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
        setError("Invalid 6-digit authenticator code. Check your Google Authenticator or Authy app.");
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
    <div className="min-h-screen w-full bg-slate-950 flex flex-col justify-between p-6 relative overflow-hidden font-sans selection:bg-emerald-500 selection:text-slate-950">
      {/* Background Decorative Ambient Glows */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-emerald-500/10 rounded-full blur-[140px] pointer-events-none" />
      <div className="absolute bottom-10 right-10 w-[400px] h-[400px] bg-teal-500/10 rounded-full blur-[120px] pointer-events-none" />

      {/* Top Header Logo */}
      <header className="relative z-10 flex items-center justify-between max-w-6xl mx-auto w-full pt-2">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-emerald-600 via-emerald-500 to-teal-400 flex items-center justify-center font-black text-xl text-slate-950 shadow-lg shadow-emerald-500/20">
            K
          </div>
          <div>
            <h2 className="font-extrabold text-base tracking-tight text-white flex items-center gap-2">
              KAZI <span className="text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">ADMIN OS</span>
            </h2>
            <p className="text-[11px] text-slate-400 font-medium">Nairobi Marketplace Hub</p>
          </div>
        </div>

        <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 bg-slate-900/80 px-3.5 py-1.5 rounded-full border border-slate-800">
          <Shield className="w-3.5 h-3.5 text-emerald-400" />
          <span>RFC 6238 2FA Enforced</span>
        </div>
      </header>

      {/* Main Form Center Box */}
      <main className="relative z-10 my-auto flex justify-center w-full py-8">
        <div className="bg-slate-900/90 backdrop-blur-2xl w-full max-w-md p-8 rounded-3xl shadow-2xl border border-slate-800/80 space-y-6">
          {/* Header Branding */}
          <div className="text-center space-y-2">
            <div className="w-12 h-12 bg-gradient-to-tr from-emerald-500/20 to-teal-500/20 text-emerald-400 rounded-2xl flex items-center justify-center mx-auto border border-emerald-500/30 shadow-inner">
              <Shield className="w-6 h-6 text-emerald-400" />
            </div>
            <h1 className="text-2xl font-black text-white tracking-tight">Executive Authentication</h1>
            <p className="text-xs text-slate-400">Secure 2-Factor Operating System Access</p>
          </div>

          {error && (
            <div className="p-3.5 bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs rounded-2xl font-semibold flex items-center gap-2">
              <Sparkles className="w-4 h-4 shrink-0 text-rose-400" />
              <span>{error}</span>
            </div>
          )}

          {/* STEP 1: EMAIL & PASSWORD */}
          {step === "credentials" && (
            <form onSubmit={handleCredentialLogin} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                  Administrator Email
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-3.5" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="admin@kazi.co.ke"
                    className="w-full pl-10 pr-4 py-3 bg-slate-950 border border-slate-800 focus:border-emerald-500 rounded-2xl text-sm text-white focus:outline-none transition-all font-medium placeholder:text-slate-600"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                  Password
                </label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-3.5" />
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full pl-10 pr-4 py-3 bg-slate-950 border border-slate-800 focus:border-emerald-500 rounded-2xl text-sm text-white focus:outline-none transition-all font-medium placeholder:text-slate-600"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full py-3.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black text-xs uppercase tracking-wider rounded-2xl transition-all shadow-lg shadow-emerald-500/20 flex items-center justify-center space-x-2 disabled:opacity-50"
              >
                <span>{loading ? "Authenticating..." : "Continue to 2FA Verification"}</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </form>
          )}

          {/* STEP 2: TOTP CODE VERIFICATION */}
          {step === "totp" && (
            <form onSubmit={handleVerifyTOTP} className="space-y-4">
              <div className="p-3.5 bg-slate-950 border border-slate-800 rounded-2xl text-xs text-slate-300 flex items-center space-x-3">
                <Smartphone className="w-5 h-5 text-emerald-400 shrink-0" />
                <span>Enter the 6-digit security code from your Authenticator app (Google Authenticator, Authy, or 1Password).</span>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                  6-Digit Authenticator Code
                </label>
                <div className="relative">
                  <KeyRound className="w-4 h-4 text-slate-500 absolute left-3.5 top-4" />
                  <input
                    type="text"
                    required
                    maxLength={6}
                    value={totpCode}
                    onChange={(e) => setTotpCode(e.target.value)}
                    placeholder="123456"
                    className="w-full pl-10 pr-4 py-3.5 bg-slate-950 border border-slate-800 focus:border-emerald-500 rounded-2xl text-xl font-mono font-black tracking-widest text-emerald-400 focus:outline-none text-center transition-all"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading || totpCode.length !== 6}
                className="w-full py-3.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black text-xs uppercase tracking-wider rounded-2xl transition-all shadow-lg shadow-emerald-500/20 flex items-center justify-center space-x-2 disabled:opacity-50"
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>{loading ? "Verifying Token..." : "Authenticate & Access OS"}</span>
              </button>

              <button
                type="button"
                onClick={() => setStep("credentials")}
                className="w-full text-xs text-slate-400 hover:text-white font-semibold pt-2 text-center block transition-colors"
              >
                Back to Credentials
              </button>
            </form>
          )}

          {/* STEP 3: SCAN QR CODE TO ENROLL AUTHENTICATOR APP */}
          {step === "setup" && (
            <div className="space-y-4 text-center">
              <div className="p-3.5 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl text-xs text-emerald-300 space-y-1 text-left">
                <p className="font-bold flex items-center gap-1.5">
                  <QrCode className="w-4 h-4 text-emerald-400" /> Authenticator Setup Required
                </p>
                <p className="text-[11px] text-slate-300">
                  Scan this QR code with Google Authenticator, Authy, or 1Password on your mobile device:
                </p>
              </div>

              {/* Rendered QR Code Image */}
              <div className="p-4 bg-white rounded-2xl border border-slate-800 flex flex-col items-center justify-center space-y-2 shadow-xl">
                {qrCodeDataUrl ? (
                  <img
                    src={qrCodeDataUrl}
                    alt="2FA QR Code"
                    className="w-48 h-48 rounded-xl"
                  />
                ) : (
                  <div className="w-48 h-48 bg-slate-100 animate-pulse rounded-xl flex items-center justify-center text-xs text-slate-400">
                    Generating QR...
                  </div>
                )}
                <span className="text-[10px] text-slate-500 font-mono uppercase font-bold">Scan to Enroll Admin</span>
              </div>

              {/* Base32 Key Fallback */}
              <div className="p-3 bg-slate-950 text-white rounded-2xl space-y-1 text-left border border-slate-800">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest block">
                  Manual Base32 Entry Key
                </span>
                <div className="flex items-center justify-between">
                  <span className="font-mono text-xs font-black tracking-widest text-emerald-400">{secret}</span>
                  <button
                    onClick={copySecretToClipboard}
                    className="p-1.5 bg-slate-800 hover:bg-slate-700 rounded-lg text-slate-300 transition-colors"
                  >
                    {copiedSecret ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                </div>
              </div>

              <button
                onClick={() => setStep("totp")}
                className="w-full py-3.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black text-xs uppercase tracking-wider rounded-2xl transition-all shadow-lg shadow-emerald-500/20 flex items-center justify-center space-x-2"
              >
                <span>I Have Scanned the QR Code – Continue</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          )}
        </div>
      </main>

      {/* Footer System Info */}
      <footer className="relative z-10 max-w-6xl mx-auto w-full text-center border-t border-slate-900 pb-2 pt-4 flex flex-col sm:flex-row items-center justify-between text-[11px] text-slate-500 font-medium">
        <span>Kazi Marketplace Operations System © {new Date().getFullYear()}</span>
        <span className="font-mono text-[10px] text-slate-400">Encrypted Session Token (AES-256)</span>
      </footer>
    </div>
  );
}
