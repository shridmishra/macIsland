"use client";

import * as React from "react";
import Image from "next/image";
import {
  Search01Icon,
  Wifi01Icon,
  Bookmark01Icon,
  DashboardSquare01Icon,
  ArrowUpRight01Icon,
  Add01Icon,
} from "@hugeicons/core-free-icons";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Icon } from "@/components/ui/icon";
import { cn } from "@/lib/utils";

type ShelfTab = "playing" | "lyrics" | "hud" | "sources" | "recent";

export function InteractiveIslandMockup() {
  const [activeTab, setActiveTab] = React.useState<ShelfTab>("playing");
  const [searchQuery, setSearchQuery] = React.useState("");
  const [isPlaying, setIsPlaying] = React.useState(true);

  return (
    <div className="w-full max-w-5xl mx-auto px-4 py-4 sm:py-6 flex flex-col items-center select-none">
      {/* macOS Desktop Screen Container with Sonoma Wallpaper */}
      <div className="w-full relative rounded-2xl sm:rounded-3xl border border-white/15 shadow-2xl overflow-hidden min-h-[460px] sm:min-h-[520px] flex flex-col justify-between bg-card">
        {/* Real Sonoma Wallpaper Background */}
        <div className="absolute inset-0 -z-10 overflow-hidden">
          <Image
            src="/images/sonoma-wallpaper.webp"
            alt="macOS Sonoma Wallpaper"
            fill
            priority
            className="object-cover object-bottom scale-105"
            sizes="(max-w-768px) 100vw, 1200px"
          />
          {/* Subtle vignette / atmospheric overlay */}
          <div className="absolute inset-0 bg-gradient-to-b from-black/20 via-transparent to-black/30 pointer-events-none" />
        </div>

        {/* Top macOS Menu Bar */}
        <div className="h-10 px-5 sm:px-7 flex items-center justify-between text-xs text-white select-none relative z-10">
          {/* Left Menu Items */}
          <div className="flex items-center gap-3.5 font-medium text-white/90">
            <AppleOfficialIcon size={14} className="text-white drop-shadow-sm" />
            <span className="font-semibold text-white tracking-tight drop-shadow-sm">
              Mac Island
            </span>
            <span className="hidden md:inline-block opacity-80 hover:opacity-100 cursor-pointer">
              File
            </span>
            <span className="hidden md:inline-block opacity-80 hover:opacity-100 cursor-pointer">
              Edit
            </span>
            <span className="hidden lg:inline-block opacity-80 hover:opacity-100 cursor-pointer">
              Controls
            </span>
            <span className="hidden lg:inline-block opacity-80 hover:opacity-100 cursor-pointer">
              Window
            </span>
          </div>

          {/* Right Status Tray */}
          <div className="flex items-center gap-3 font-mono text-[11px] text-white/90">
            <Icon icon={Search01Icon} size={14} className="opacity-90" />
            <Icon icon={Wifi01Icon} size={14} className="opacity-90" />
            <span className="font-semibold tracking-wide">09:41</span>
          </div>
        </div>

        {/* Center Top-Anchored Dynamic Notch Shelf */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 z-20 w-full flex justify-center px-2 pointer-events-none">
          <div className="relative pointer-events-auto">
            {/* Left Hardware Notch Smooth Ear Fillet */}
            <div className="absolute top-0 -left-5 w-5 h-5 overflow-hidden pointer-events-none">
              <svg
                viewBox="0 0 20 20"
                className="w-5 h-5 fill-notch-surface scale-x-[-1]"
                aria-hidden="true"
              >
                <path d="M 0 0 L 20 0 C 8.954 0 0 8.954 0 20 Z" />
              </svg>
            </div>

            {/* Right Hardware Notch Smooth Ear Fillet */}
            <div className="absolute top-0 -right-5 w-5 h-5 overflow-hidden pointer-events-none">
              <svg
                viewBox="0 0 20 20"
                className="w-5 h-5 fill-notch-surface"
                aria-hidden="true"
              >
                <path d="M 0 0 L 20 0 C 8.954 0 0 8.954 0 20 Z" />
              </svg>
            </div>

            {/* The Black Notch Shelf Enclosure */}
            <div className="bg-notch-surface text-white rounded-b-3xl border-x border-b border-white/10 shadow-2xl p-4 sm:p-5 w-[92vw] sm:w-[640px] md:w-[720px] transition-all duration-300">
              {/* Row 1: Search Bar + Action Icons */}
              <div className="flex items-center justify-between gap-3 mb-3.5">
                {/* Search Input Bar */}
                <div className="relative flex-1">
                  <Icon
                    icon={Search01Icon}
                    size={14}
                    className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
                  />
                  <Input
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search…"
                    className="h-8 pl-8 pr-3 text-xs bg-surface-elevated border-border text-white placeholder:text-muted-foreground rounded-full w-48 sm:w-64 focus-visible:w-full transition-all duration-200"
                  />
                </div>

                {/* Right Mini Action Buttons */}
                <div className="flex items-center gap-1.5 shrink-0">
                  <Button
                    variant="ghost"
                    size="iconSm"
                    className="h-7 w-7 rounded-full bg-surface-elevated text-white/70 hover:text-white border border-border-subtle"
                    aria-label="Bookmarks"
                  >
                    <Icon icon={Bookmark01Icon} size={13} />
                  </Button>
                  <Button
                    variant="ghost"
                    size="iconSm"
                    className="h-7 w-7 rounded-full bg-surface-elevated text-white/70 hover:text-white border border-border-subtle"
                    aria-label="Grid View"
                  >
                    <Icon icon={DashboardSquare01Icon} size={13} />
                  </Button>
                  <Button
                    variant="ghost"
                    size="iconSm"
                    className="h-7 w-7 rounded-full bg-surface-elevated text-white/70 hover:text-white border border-border-subtle"
                    aria-label="Popout"
                  >
                    <Icon icon={ArrowUpRight01Icon} size={13} />
                  </Button>
                </div>
              </div>

              {/* Row 2: Shelf Filter Category Tabs */}
              <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-3 mb-1 text-xs">
                <Button
                  variant={activeTab === "playing" ? "apple" : "ghost"}
                  size="sm"
                  onClick={() => setActiveTab("playing")}
                  className={cn(
                    "h-7 px-3 gap-1.5 rounded-full text-xs shrink-0 transition-colors",
                    activeTab === "playing"
                      ? "bg-white text-black font-semibold shadow-sm"
                      : "bg-surface-elevated text-white/80 hover:text-white border border-border-subtle"
                  )}
                >
                  <span>History</span>
                  <span
                    className={cn(
                      "text-[10px] px-1.5 py-0.2 rounded-full font-mono",
                      activeTab === "playing"
                        ? "bg-black/10 text-black"
                        : "bg-white/10 text-white/70"
                    )}
                  >
                    24
                  </span>
                </Button>

                <Button
                  variant={activeTab === "lyrics" ? "apple" : "ghost"}
                  size="sm"
                  onClick={() => setActiveTab("lyrics")}
                  className={cn(
                    "h-7 px-3 gap-1.5 rounded-full text-xs shrink-0 transition-colors",
                    activeTab === "lyrics"
                      ? "bg-white text-black font-semibold shadow-sm"
                      : "bg-surface-elevated text-white/80 hover:text-white border border-border-subtle"
                  )}
                >
                  <span>Prompts</span>
                  <span
                    className={cn(
                      "text-[10px] px-1.5 py-0.2 rounded-full font-mono",
                      activeTab === "lyrics"
                        ? "bg-black/10 text-black"
                        : "bg-white/10 text-white/70"
                    )}
                  >
                    24
                  </span>
                </Button>

                <Button
                  variant={activeTab === "hud" ? "apple" : "ghost"}
                  size="sm"
                  onClick={() => setActiveTab("hud")}
                  className={cn(
                    "h-7 px-3 gap-1.5 rounded-full text-xs shrink-0 transition-colors",
                    activeTab === "hud"
                      ? "bg-white text-black font-semibold shadow-sm"
                      : "bg-surface-elevated text-white/80 hover:text-white border border-border-subtle"
                  )}
                >
                  <span>Colors</span>
                  <span
                    className={cn(
                      "text-[10px] px-1.5 py-0.2 rounded-full font-mono",
                      activeTab === "hud"
                        ? "bg-black/10 text-black"
                        : "bg-white/10 text-white/70"
                    )}
                  >
                    24
                  </span>
                </Button>

                <Button
                  variant={activeTab === "sources" ? "apple" : "ghost"}
                  size="sm"
                  onClick={() => setActiveTab("sources")}
                  className={cn(
                    "h-7 px-3 gap-1.5 rounded-full text-xs shrink-0 transition-colors",
                    activeTab === "sources"
                      ? "bg-white text-black font-semibold shadow-sm"
                      : "bg-surface-elevated text-white/80 hover:text-white border border-border-subtle"
                  )}
                >
                  <span>Assets</span>
                  <span
                    className={cn(
                      "text-[10px] px-1.5 py-0.2 rounded-full font-mono",
                      activeTab === "sources"
                        ? "bg-black/10 text-black"
                        : "bg-white/10 text-white/70"
                    )}
                  >
                    24
                  </span>
                </Button>

                <Button
                  variant={activeTab === "recent" ? "apple" : "ghost"}
                  size="sm"
                  onClick={() => setActiveTab("recent")}
                  className={cn(
                    "h-7 px-3 gap-1.5 rounded-full text-xs shrink-0 transition-colors",
                    activeTab === "recent"
                      ? "bg-white text-black font-semibold shadow-sm"
                      : "bg-surface-elevated text-white/80 hover:text-white border border-border-subtle"
                  )}
                >
                  <span>Inspirations</span>
                  <span
                    className={cn(
                      "text-[10px] px-1.5 py-0.2 rounded-full font-mono",
                      activeTab === "recent"
                        ? "bg-black/10 text-black"
                        : "bg-white/10 text-white/70"
                    )}
                  >
                    24
                  </span>
                </Button>

                <Button
                  variant="ghost"
                  size="iconSm"
                  className="h-7 w-7 rounded-full bg-surface-elevated text-white/70 hover:text-white border border-border-subtle shrink-0"
                  aria-label="Add Category"
                >
                  <Icon icon={Add01Icon} size={14} />
                </Button>
              </div>

              {/* Row 3: 5 Sleek Content Cards Grid matching Screenshot */}
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2.5 pt-1">
                {/* Card 1: Dock widgets card */}
                <div
                  onClick={() => setIsPlaying(!isPlaying)}
                  className="group relative rounded-xl overflow-hidden bg-surface-elevated border border-border-subtle hover:border-border-highlight aspect-[1.15/1] p-2.5 flex flex-col justify-between cursor-pointer transition-all duration-200 hover:-translate-y-0.5 shadow-md"
                >
                  <div className="relative z-10 flex items-center justify-between">
                    <span className="text-[10px] font-bold text-white leading-tight line-clamp-2">
                      A useful Dock for live widgets.
                    </span>
                  </div>

                  {/* Waveform Equalizer Mini Graphic */}
                  <div className="h-6 w-full rounded bg-black/40 border border-white/10 flex items-center justify-between px-2 my-auto">
                    <span className="text-[9px] font-mono text-white/70">dock.cool</span>
                    <div className="flex items-center gap-0.5 h-3">
                      <span className="w-1 bg-apple-green rounded-full animate-eq-1" />
                      <span className="w-1 bg-apple-green rounded-full animate-eq-2" />
                      <span className="w-1 bg-apple-green rounded-full animate-eq-3" />
                    </div>
                  </div>

                  <div className="flex items-center gap-1.5 pt-1 text-[9px] text-white/70">
                    <div className="h-3 w-3 rounded-full bg-apple-blue flex items-center justify-center text-[7px] text-white font-bold">
                      G
                    </div>
                    <span className="truncate">23 min ago</span>
                  </div>
                </div>

                {/* Card 2: Artist Photo Card */}
                <div className="group relative rounded-xl overflow-hidden bg-gradient-to-br from-emerald-800 to-teal-950 border border-border-subtle hover:border-border-highlight aspect-[1.15/1] p-2.5 flex flex-col justify-between cursor-pointer transition-all duration-200 hover:-translate-y-0.5 shadow-md">
                  {/* Decorative Avatar / Photo Center */}
                  <div className="h-10 w-10 rounded-full bg-white/20 border border-white/30 mx-auto flex items-center justify-center my-auto shadow-inner">
                    <div className="h-5 w-5 rounded-full bg-white/40" />
                  </div>

                  <div className="flex items-center justify-between pt-1 text-[9px] text-white/80">
                    <div className="flex items-center gap-1">
                      <div className="h-3 w-3 rounded bg-apple-orange flex items-center justify-center text-[7px] text-white font-bold">
                        P
                      </div>
                      <span>5 min ago</span>
                    </div>
                    <span className="opacity-70 font-mono">3.5 MB</span>
                  </div>
                </div>

                {/* Card 3: Classic Mac Artwork Card */}
                <div className="group relative rounded-xl overflow-hidden bg-stone-100 text-stone-900 border border-border-subtle hover:border-border-highlight aspect-[1.15/1] p-2.5 flex flex-col justify-between cursor-pointer transition-all duration-200 hover:-translate-y-0.5 shadow-md">
                  <div>
                    <p className="text-[10px] font-bold leading-tight">
                      A curated shelf of beautifully designed macOS apps.
                    </p>
                    <span className="text-[8px] opacity-70 font-mono">macapp.supply</span>
                  </div>

                  {/* Classic Macintosh Sketch icon */}
                  <div className="h-6 w-6 rounded bg-stone-300 border border-stone-400 self-end flex items-center justify-center text-[7px] font-mono">
                    hello
                  </div>

                  <div className="flex items-center gap-1 pt-1 text-[9px] text-stone-600">
                    <div className="h-3 w-3 rounded-full bg-amber-500 flex items-center justify-center text-[7px] text-white font-bold">
                      S
                    </div>
                    <span>23 min ago</span>
                  </div>
                </div>

                {/* Card 4: Address / Snippet Card */}
                <div className="group relative rounded-xl overflow-hidden bg-surface-elevated border border-border-subtle hover:border-border-highlight aspect-[1.15/1] p-2.5 flex flex-col justify-between cursor-pointer transition-all duration-200 hover:-translate-y-0.5 shadow-md">
                  <div className="space-y-0.5">
                    <p className="text-[10px] font-medium text-white/90 leading-tight">
                      Minneapolis 55410,
                    </p>
                    <p className="text-[9px] text-white/70 leading-tight">
                      2941 Rocket Drive
                    </p>
                    <p className="text-[9px] text-white/70 leading-tight">
                      United States
                    </p>
                  </div>

                  <div className="flex items-center gap-1.5 pt-1 text-[9px] text-white/70">
                    <div className="h-3 w-3 rounded-full bg-red-500 flex items-center justify-center text-[7px] text-white font-bold">
                      M
                    </div>
                    <span className="truncate">19 min ago</span>
                  </div>
                </div>

                {/* Card 5: Vibrant Solid Blue Swatch Card */}
                <div className="group relative rounded-xl overflow-hidden bg-apple-blue border border-white/20 hover:border-white/40 aspect-[1.15/1] p-2.5 flex flex-col justify-between cursor-pointer transition-all duration-200 hover:-translate-y-0.5 shadow-md">
                  <span className="font-mono text-xs font-bold text-white tracking-wide">
                    Apple Blue
                  </span>

                  <div className="flex items-center gap-1.5 pt-1 text-[9px] text-white/90">
                    <div className="h-3 w-3 rounded-full bg-white/20 flex items-center justify-center text-[7px] text-white font-bold">
                      F
                    </div>
                    <span>35 min ago</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Area of the Desktop Screen */}
        <div className="p-4 sm:p-6 flex items-center justify-between text-xs text-white/80 select-none relative z-10">
          <Badge
            variant="solid"
            className="bg-black/40 text-white border-white/10 text-[11px] py-1 px-3 shadow-md"
          >
            Hover or click tabs to explore notch shelf
          </Badge>
          <span className="text-[10px] font-mono text-white/60 hidden sm:inline-block">
            macOS Sonoma 14.0+ • Liquid Retina XDR
          </span>
        </div>
      </div>
    </div>
  );
}
