"use client";

import * as React from "react";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { InteractiveIslandMockup } from "./InteractiveIslandMockup";

export function HeroSection() {
  return (
    <section
      id="hero"
      className="relative pt-24 sm:pt-32 pb-16 flex flex-col items-center text-center overflow-hidden bg-hero-pink-gradient"
    >
      {/* Hero Text Container matching exact Figma specifications */}
      <div className="flex flex-col flex-nowrap justify-center items-center gap-[20px] relative top-[0px] right-[0px] bottom-[0px] left-[0px] w-full max-w-[600px] min-h-[420.602px] text-[12px] px-4 mx-auto select-none">
        {/* Top Feature Tag Pill with Official Apple Logo */}
        <Badge
          variant="heroPink"
          className="gap-2 px-3.5 py-1 text-[13px] font-medium shadow-sm"
        >
          <AppleOfficialIcon size={14} className="text-white drop-shadow-sm" />
          <span className="font-semibold text-white drop-shadow-sm">
            Dynamic Island for Mac
          </span>
        </Badge>

        {/* Dual-Typeface Headline with exact 80px/80px/-4px letter spacing */}
        <h1 className="hero-text-shadow text-center flex flex-col items-center">
          <span className="block text-[44px] sm:text-[80px] font-bold leading-[46px] sm:leading-[80px] tracking-[-2px] sm:tracking-[-4px] text-white font-sans">
            Glance once.
          </span>
          <span className="block text-[48px] sm:text-[80px] font-normal italic leading-[50px] sm:leading-[80px] tracking-[-2px] sm:tracking-[-4px] text-white font-apple-serif">
            Control everything.
          </span>
        </h1>

        {/* Subtitle Paragraph */}
        <p className="text-sm sm:text-base text-white/90 leading-relaxed font-normal max-w-[540px] drop-shadow-sm">
          Mac Island turns your MacBook notch into an intelligent Dynamic Island.
          Real-time media playback, synchronized lyrics, stealth system HUDs, and
          seamless controls without ever stealing focus.
        </p>

        {/* Primary Black Pill CTA Button with Official Apple Logo */}
        <Button
          asChild
          variant="heroBlack"
          size="lg"
          className="h-12 px-7 rounded-full shadow-2xl gap-2.5 text-sm font-medium"
        >
          <a
            href="https://github.com/shridhar/macIsland/releases"
            target="_blank"
            rel="noopener noreferrer"
          >
            <AppleOfficialIcon size={16} className="text-white" />
            <span>Download for macOS</span>
          </a>
        </Button>

        {/* Micro-Features Metadata Line */}
        <div className="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 text-[12px] text-white/85 font-medium drop-shadow-sm">
          <span>Free &amp; open-source</span>
          <span className="opacity-60">•</span>
          <span>100% native Swift</span>
          <span className="opacity-60">•</span>
          <span>macOS Sonoma 14.0 or later</span>
        </div>
      </div>

      {/* Live Interactive Island Mockup below */}
      <div id="interactive-demo" className="w-full mt-6 sm:mt-10">
        <InteractiveIslandMockup />
      </div>
    </section>
  );
}
