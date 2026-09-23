"use client";

import * as React from "react";
import Link from "next/link";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Button } from "@/components/ui/button";

export function Navbar() {
  return (
    <header className="fixed top-0 inset-x-0 z-50 flex justify-center pointer-events-none">
      {/* Top Connected Notch Enclosure */}
      <div className="relative pointer-events-auto">
        {/* Left Smooth Hardware Notch Ear Fillet */}
        <div className="absolute top-0 -left-5 w-5 h-5 overflow-hidden pointer-events-none">
          <svg
            viewBox="0 0 20 20"
            className="w-5 h-5 fill-notch-surface scale-x-[-1]"
            aria-hidden="true"
          >
            <path d="M 0 0 L 20 0 C 8.954 0 0 8.954 0 20 Z" />
          </svg>
        </div>

        {/* Right Smooth Hardware Notch Ear Fillet */}
        <div className="absolute top-0 -right-5 w-5 h-5 overflow-hidden pointer-events-none">
          <svg
            viewBox="0 0 20 20"
            className="w-5 h-5 fill-notch-surface"
            aria-hidden="true"
          >
            <path d="M 0 0 L 20 0 C 8.954 0 0 8.954 0 20 Z" />
          </svg>
        </div>

        {/* Central Black Notch Navigation Bar */}
        <nav className="bg-notch-surface text-hero-orange-text rounded-b-2xl px-5 sm:px-7 py-2.5 flex items-center justify-between gap-6 sm:gap-10 shadow-2xl border-x border-b border-white/10">
          {/* Brand Logo & Name */}
          <Link href="#hero" className="flex items-center gap-2.5 group">
            {/* Glossy App Icon Squircle with Official Apple Silhouette */}
            <div className="h-7 w-7 rounded-lg bg-gradient-to-br from-apple-blue via-apple-purple to-hero-orange-mid flex items-center justify-center p-0.5 shadow-md transition-transform duration-200 group-hover:scale-105 border border-white/20">
              <AppleOfficialIcon size={14} className="text-white drop-shadow-sm" />
            </div>
            <span className="font-bold text-sm tracking-tight text-white">
              Mac Island
            </span>
          </Link>

          {/* Desktop Navigation Links */}
          <div className="hidden md:flex items-center gap-6 text-xs font-medium text-white/80">
            <Link
              href="#features"
              className="hover:text-white transition-colors duration-150"
            >
              Features
            </Link>
            <Link
              href="#faq"
              className="hover:text-white transition-colors duration-150"
            >
              FAQ
            </Link>
            <Link
              href="#interactive-demo"
              className="hover:text-white transition-colors duration-150"
            >
              Live Demo
            </Link>
            <Link
              href="#hud-lyrics"
              className="hover:text-white transition-colors duration-150"
            >
              HUD &amp; Lyrics
            </Link>
            <Link
              href="#pricing"
              className="hover:text-white transition-colors duration-150"
            >
              Pricing
            </Link>
          </div>

          {/* White Download Pill Button with Official Apple Logo */}
          <Button asChild variant="heroWhite" size="sm" className="gap-1.5 px-4 h-7">
            <a href="#pricing">
              <AppleOfficialIcon size={12} className="text-black" />
              <span>Download</span>
            </a>
          </Button>
        </nav>
      </div>
    </header>
  );
}
