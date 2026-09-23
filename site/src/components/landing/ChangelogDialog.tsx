"use client";

import * as React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";

interface ChangelogDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function ChangelogDialog({ open, onOpenChange }: ChangelogDialogProps) {
  const releases = [
    {
      version: "v1.2.0",
      date: "Latest Release",
      isLatest: true,
      highlights: [
        "Stealth System HUD: Real-time feedback for system volume and brightness inside the notch.",
        "Synchronized Lyrics: Smooth marquee lyrics rendering anchored in the hardware notch.",
        "Universal Binary: Fully optimized for Apple Silicon (M1–M4) and Intel Macs.",
        "Memory & CPU tuning: Reduced idle footprint to 0.0% CPU and <28MB memory.",
      ],
    },
    {
      version: "v1.1.0",
      date: "Previous Release",
      isLatest: false,
      highlights: [
        "Browser Audio Hooks: MediaSession metadata detection for Chrome, Safari, and Brave.",
        "Floating Capsule Mode: Automatic geometry detection for iMac, Mac Studio, and external monitors.",
        "Artwork Color Extraction: Vibrant adaptive tinting matching active music artwork.",
      ],
    },
    {
      version: "v1.0.0",
      date: "Initial Release",
      isLatest: false,
      highlights: [
        "Core Dynamic Island notch integration with AppKit non-activating windowing.",
        "MediaRemote.framework integration with zero permission prompts required.",
        "Free edition with all core features unlocked and zero trial limits.",
      ],
    },
  ];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-xl border border-border bg-card">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold tracking-tight text-foreground">
            Changelog &amp; Updates
          </DialogTitle>
          <DialogDescription className="text-sm text-muted-foreground">
            What&apos;s new in Mac Island.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6 mt-3 max-h-[60vh] overflow-y-auto pr-1">
          {releases.map((release) => (
            <div
              key={release.version}
              className="border border-border rounded-2xl p-4 bg-surface-elevated/70 space-y-3"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="font-bold text-sm text-foreground">
                    {release.version}
                  </span>
                  {release.isLatest && (
                    <Badge variant="solid" className="text-[10px] py-0 px-2">
                      Latest
                    </Badge>
                  )}
                </div>
                <span className="text-xs text-muted-foreground font-mono">
                  {release.date}
                </span>
              </div>
              <ul className="space-y-1.5 text-xs text-muted-foreground leading-relaxed list-disc list-inside">
                {release.highlights.map((h, i) => (
                  <li key={i}>{h}</li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}
