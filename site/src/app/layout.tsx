import type { Metadata } from "next";
import { Instrument_Serif, Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const instrumentSerif = Instrument_Serif({
  variable: "--font-instrument-serif",
  subsets: ["latin"],
  weight: "400",
  style: ["normal", "italic"],
});

export const metadata: Metadata = {
  title: "Mac Island — Native Dynamic Island for macOS",
  description:
    "Mac Island turns your MacBook notch into an intelligent Dynamic Island. Real-time media playback, synchronized lyrics, stealth system HUD, and seamless controls. 100% free with all core features unlocked.",
  keywords: [
    "Mac Island",
    "macOS Dynamic Island",
    "MacBook notch",
    "SwiftUI",
    "AppKit",
    "macOS utility",
    "Now Playing Mac",
    "free macOS app",
  ],
  authors: [{ name: "Mac Island Team" }],
  openGraph: {
    title: "Mac Island — Native Dynamic Island for macOS",
    description:
      "Turn your MacBook notch into an intelligent Dynamic Island. 100% free with all core features included.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${inter.variable} ${instrumentSerif.variable}`}>
      <body className="min-h-screen bg-background text-foreground antialiased selection:bg-accent selection:text-accent-foreground">
        {children}
      </body>
    </html>
  );
}
