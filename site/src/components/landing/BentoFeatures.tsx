"use client";

import * as React from "react";
import {
  ShieldCheckIcon,
  AppWindowMacIcon,
  AudioWave01Icon,
  VolumeHighIcon,
  SlidersHorizontalIcon,
} from "@hugeicons/core-free-icons";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Icon } from "@/components/ui/icon";

export function BentoFeatures() {
  const [displayMode, setDisplayMode] = React.useState<"notch" | "floating">("notch");

  return (
    <section id="features" className="py-24 max-w-6xl mx-auto px-4">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-16">
        <Badge variant="solidActive" className="mb-4 text-xs font-mono">
          ENGINEERED FOR MACOS
        </Badge>
        <h2 className="text-4xl sm:text-5xl font-bold tracking-tight text-foreground">
          Your notch, redefined for your{" "}
          <span className="font-apple-serif italic font-normal text-transparent bg-clip-text bg-gradient-to-r from-foreground via-muted-foreground/80 to-foreground">
            entire workflow.
          </span>
        </h2>
        <p className="mt-4 text-base sm:text-lg text-muted-foreground leading-relaxed">
          Designed from the ground up in Swift and AppKit to look and feel like an
          integral part of macOS Tahoe, Sonoma, and Sequoia.
        </p>
      </div>

      {/* Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Card 1: Zero Permissions (Spans 2 cols on md) */}
        <Card hoverEffect className="md:col-span-2 flex flex-col justify-between">
          <CardHeader>
            <div className="flex items-center justify-between gap-4 mb-2">
              <div className="h-10 w-10 rounded-xl bg-apple-green/10 border border-apple-green/20 flex items-center justify-center">
                <Icon icon={ShieldCheckIcon} size={22} className="text-apple-green" />
              </div>
              <Badge variant="hud">ZERO PERMISSIONS</Badge>
            </div>
            <CardTitle className="text-2xl">
              Universal Media Detection via MediaRemote
            </CardTitle>
            <CardDescription className="text-base">
              Standard Mac utilities require invasive Accessibility and AppleScript
              automation alerts. Mac Island dynamically links to{" "}
              <code className="text-xs font-mono bg-card px-1.5 py-0.5 rounded border border-border-subtle text-foreground">
                MediaRemote.framework
              </code>{" "}
              with zero permission prompts. It instantly picks up audio from
              Spotify, Apple Music, YouTube (Safari, Brave, Chrome), Podcasts, and
              web streams.
            </CardDescription>
          </CardHeader>
          <CardContent>
            {/* Visual simulation of zero alerts */}
            <div className="rounded-xl bg-card-secondary border border-border p-4 mt-2 font-mono text-xs text-muted-foreground">
              <div className="flex items-center justify-between pb-2 border-b border-border-subtle text-foreground font-semibold">
                <span className="flex items-center gap-2">
                  <span className="h-2 w-2 rounded-full bg-apple-green" />
                  Media Detection Matrix
                </span>
                <span className="text-[10px] text-muted-foreground">POSIX dlopen</span>
              </div>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-3 text-center">
                <div className="p-2 rounded-lg bg-card border border-border-subtle">
                  <p className="text-foreground font-medium">Apple Music</p>
                  <p className="text-[10px] text-apple-green">Supported</p>
                </div>
                <div className="p-2 rounded-lg bg-card border border-border-subtle">
                  <p className="text-foreground font-medium">Spotify</p>
                  <p className="text-[10px] text-apple-green">Supported</p>
                </div>
                <div className="p-2 rounded-lg bg-card border border-border-subtle">
                  <p className="text-foreground font-medium">Safari / YouTube</p>
                  <p className="text-[10px] text-apple-green">Supported</p>
                </div>
                <div className="p-2 rounded-lg bg-card border border-border-subtle">
                  <p className="text-foreground font-medium">Chrome / Brave</p>
                  <p className="text-[10px] text-apple-green">Supported</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Card 2: Notch Hugging vs Floating Pill */}
        <Card hoverEffect className="flex flex-col justify-between">
          <CardHeader>
            <div className="flex items-center justify-between gap-4 mb-2">
              <div className="h-10 w-10 rounded-xl bg-apple-blue/10 border border-apple-blue/20 flex items-center justify-center">
                <Icon icon={AppWindowMacIcon} size={22} className="text-apple-blue" />
              </div>
              <div className="flex items-center gap-1 bg-secondary rounded-full p-0.5 border border-border-subtle">
                <Button
                  variant={displayMode === "notch" ? "apple" : "ghost"}
                  size="sm"
                  onClick={() => setDisplayMode("notch")}
                  className="text-[11px] h-6 px-2.5"
                >
                  Notch
                </Button>
                <Button
                  variant={displayMode === "floating" ? "apple" : "ghost"}
                  size="sm"
                  onClick={() => setDisplayMode("floating")}
                  className="text-[11px] h-6 px-2.5"
                >
                  Floating
                </Button>
              </div>
            </div>
            <CardTitle>Dual Display Modes</CardTitle>
            <CardDescription>
              Hugs the hardware notch on 14&rdquo; &amp; 16&rdquo; MacBook Pros, or floats as a
              sleek solid pill on Studio Display and external monitors.
            </CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col items-center justify-center py-6">
            <div className="w-full h-24 rounded-xl bg-card-secondary border border-border flex flex-col items-center justify-start p-2 relative overflow-hidden">
              {/* Display Simulation Header */}
              {displayMode === "notch" ? (
                <div className="w-36 h-7 bg-notch-surface rounded-b-xl border-x border-b border-border flex items-center justify-center shadow-lg">
                  <div className="h-2 w-2 rounded-full bg-apple-green/80" />
                </div>
              ) : (
                <div className="w-32 h-6 mt-3 apple-pill flex items-center justify-center text-[10px] font-mono text-muted-foreground shadow-md">
                  Floating Capsule
                </div>
              )}
              <span className="text-[10px] font-mono text-muted-foreground mt-auto">
                {displayMode === "notch" ? "MacBook Pro 16\" Notch" : "Studio Display (External)"}
              </span>
            </div>
          </CardContent>
        </Card>

        {/* Card 3: Non-Activating Windowing (Never steals focus) */}
        <Card hoverEffect>
          <CardHeader>
            <div className="h-10 w-10 rounded-xl bg-apple-purple/10 border border-apple-purple/20 flex items-center justify-center mb-2">
              <Icon icon={SlidersHorizontalIcon} size={22} className="text-apple-purple" />
            </div>
            <CardTitle>Zero Focus Stealing</CardTitle>
            <CardDescription>
              Built using AppKit <code className="text-xs font-mono">NSPanel.nonactivatingPanel</code> at
              Layer 25 status bar height. Clicking track controls or scrubbing
              never interrupts your typing cursor in Xcode, Terminal, or Slack.
            </CardDescription>
          </CardHeader>
        </Card>

        {/* Card 4: Stealth System HUD */}
        <Card hoverEffect>
          <CardHeader>
            <div className="h-10 w-10 rounded-xl bg-apple-orange/10 border border-apple-orange/20 flex items-center justify-center mb-2">
              <Icon icon={VolumeHighIcon} size={22} className="text-apple-orange" />
            </div>
            <CardTitle>Stealth System HUD</CardTitle>
            <CardDescription>
              Replace the massive square volume and display brightness overlays
              that block your screen. Mac Island tucks fluid audio level bars
              directly inside your notch.
            </CardDescription>
          </CardHeader>
        </Card>

        {/* Card 5: Synchronized Live Lyrics */}
        <Card hoverEffect>
          <CardHeader>
            <div className="h-10 w-10 rounded-xl bg-apple-green/10 border border-apple-green/20 flex items-center justify-center mb-2">
              <Icon icon={AudioWave01Icon} size={22} className="text-apple-green" />
            </div>
            <CardTitle>Synchronized Live Lyrics</CardTitle>
            <CardDescription>
              Follow along with real-time word-by-word or line-by-line lyrics
              elegantly scrolling right inside your camera notch without opening a
              separate karaoke app.
            </CardDescription>
          </CardHeader>
        </Card>
      </div>
    </section>
  );
}
