"use client";

import * as React from "react";
import { MacDmgDrive } from "@/components/ui/mac-dmg-drive";
import { Button } from "@/components/ui/button";

export function DownloadCard() {
  const handleDownload = () => {
    // Direct DMG download link with fallback
    window.location.href = "https://macisland.app/download";
  };

  return (
    <div className="w-full max-w-[390px] mx-auto bg-card-download border border-card-download-border rounded-[32px] p-8 sm:p-9 flex flex-col items-center text-center shadow-xs">
      {/* 3D External Drive Icon */}
      <div className="mb-4">
        <MacDmgDrive size={110} />
      </div>

      {/* App Name */}
      <h2 className="text-lg sm:text-xl font-bold tracking-tight text-foreground">
        Mac Island
      </h2>

      {/* Minimum macOS Requirement */}
      <p className="text-xs sm:text-sm text-muted-foreground mt-1 font-medium">
        Minimum macOS 14.0 Sonoma
      </p>

      {/* File Specs & Version */}
      <p className="text-xs text-muted-foreground/80 mt-1 font-mono">
        DMG, 18MB • v1.2.0
      </p>

      {/* Download CTA Button */}
      <div className="w-full mt-6">
        <Button
          variant="download"
          size="default"
          onClick={handleDownload}
          className="w-36 h-10 text-sm font-medium mx-auto shadow-2xs hover:shadow-xs transition-all"
        >
          Download
        </Button>
      </div>

      {/* Terms */}
      <div className="mt-4 flex flex-col items-center gap-1 text-[11px] text-muted-foreground">
        <span>100% Free • All core features unlocked</span>
        <span className="text-foreground/70 font-medium">
          Optional Pro features coming soon
        </span>
      </div>
    </div>
  );
}
