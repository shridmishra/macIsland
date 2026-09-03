"use client";

import * as React from "react";
import {
  AudioWave01Icon,
  HeadphonesIcon,
  AppWindowMacIcon,
  VolumeHighIcon,
  ShieldCheckIcon,
  SlidersHorizontalIcon,
} from "@hugeicons/core-free-icons";
import { Badge } from "@/components/ui/badge";
import { Icon } from "@/components/ui/icon";

export function ShelfShowcase() {
  const chips = [
    "Zero Permissions",
    "100% Native Swift",
    "Local First",
    "Privacy First",
    "Synchronized Lyrics",
    "Stealth HUD",
    "Zero Focus Stealing",
    "Multi-Display Support",
    "Apple Silicon Ready",
    "Universal MediaRemote",
  ];

  return (
    <section className="py-20 max-w-5xl mx-auto px-4 text-center">
      {/* App Icons Ribbon */}
      <div className="flex items-center justify-center gap-3 sm:gap-4 mb-8 overflow-x-auto no-scrollbar py-2">
        <div className="h-11 w-11 rounded-2xl bg-surface-elevated border border-border flex items-center justify-center shadow-sm">
          <Icon icon={AppWindowMacIcon} size={20} className="text-apple-blue" />
        </div>
        <div className="h-11 w-11 rounded-2xl bg-surface-elevated border border-border flex items-center justify-center shadow-sm">
          <Icon icon={HeadphonesIcon} size={20} className="text-apple-green" />
        </div>
        <div className="h-11 w-11 rounded-2xl bg-surface-elevated border border-border flex items-center justify-center shadow-sm">
          <Icon icon={AudioWave01Icon} size={20} className="text-apple-purple" />
        </div>
        <div className="h-11 w-11 rounded-2xl bg-surface-elevated border border-border flex items-center justify-center shadow-sm">
          <Icon icon={VolumeHighIcon} size={20} className="text-apple-orange" />
        </div>
        <div className="h-11 w-11 rounded-2xl bg-surface-elevated border border-border flex items-center justify-center shadow-sm">
          <Icon icon={ShieldCheckIcon} size={20} className="text-apple-green" />
        </div>
        <div className="h-11 w-11 rounded-2xl bg-surface-elevated border border-border flex items-center justify-center shadow-sm">
          <Icon icon={SlidersHorizontalIcon} size={20} className="text-apple-blue" />
        </div>
      </div>

      {/* Main Headline */}
      <h2 className="text-4xl sm:text-6xl font-bold tracking-tight text-foreground leading-[1.08] max-w-3xl mx-auto">
        Your dynamic island, wherever you{" "}
        <span className="font-apple-serif italic font-normal text-muted-foreground">
          need it.
        </span>
      </h2>

      {/* Subtitle */}
      <p className="mt-5 text-base sm:text-lg text-muted-foreground max-w-2xl mx-auto leading-relaxed">
        Use the notch shelf, quick controls, live lyrics ticker, stealth system
        HUD, and one-click source switching to manage your Mac audio effortlessly.
      </p>

      {/* Feature Filter Chips Carousel / Badges Row */}
      <div className="mt-8 flex flex-wrap items-center justify-center gap-2 max-w-3xl mx-auto">
        {chips.map((chip, i) => (
          <Badge
            key={i}
            variant="solid"
            className="text-xs py-1 px-3 bg-surface-elevated border-border text-foreground hover:bg-surface-hover transition-colors"
          >
            {chip}
          </Badge>
        ))}
      </div>
    </section>
  );
}
