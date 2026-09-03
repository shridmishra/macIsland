"use client";

import * as React from "react";
import Image from "next/image";
import {
  AudioWave01Icon,
  VolumeHighIcon,
  ShieldCheckIcon,
  AppWindowMacIcon,
  SlidersHorizontalIcon,
} from "@hugeicons/core-free-icons";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Icon } from "@/components/ui/icon";

export function FeatureDeepDives() {
  return (
    <section className="py-12 max-w-5xl mx-auto px-4 space-y-24">
      {/* SHOWCASE 1: Smarter, Faster, and Connected Across Your Mac */}
      <div className="space-y-6 text-center max-w-3xl mx-auto">
        <h3 className="text-3xl sm:text-5xl font-bold tracking-tight text-foreground">
          Smarter, Faster, and Native Across Your Mac
        </h3>
        <p className="text-base sm:text-lg text-muted-foreground leading-relaxed">
          Keep your audio controls synced with macOS MediaRemote, automatically detect
          music from Spotify, Apple Music, and browser tabs, and control playback
          with instant responsiveness.
        </p>

        {/* Screen Frame with Sonoma Wallpaper */}
        <div className="rounded-3xl border border-border shadow-2xl overflow-hidden relative aspect-[16/9] w-full mt-8 bg-card">
          <Image
            src="/images/sonoma-wallpaper.webp"
            alt="macOS Sonoma Desktop"
            fill
            className="object-cover object-center"
            sizes="(max-w-768px) 100vw, 1100px"
          />
          {/* Top Notch Island floating gracefully */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-72 h-9 bg-black rounded-b-2xl border-x border-b border-white/10 shadow-xl flex items-center justify-between px-4 text-white text-xs">
            <div className="flex items-center gap-2">
              <span className="h-2 w-2 rounded-full bg-apple-green animate-pulse" />
              <span className="font-semibold text-xs">Starboy</span>
            </div>
            <div className="flex items-center gap-1">
              <span className="w-1 h-3 bg-apple-green rounded-full animate-eq-1" />
              <span className="w-1 h-3 bg-apple-green rounded-full animate-eq-2" />
              <span className="w-1 h-3 bg-apple-green rounded-full animate-eq-3" />
            </div>
          </div>
        </div>
      </div>

      {/* SHOWCASE 2: One Beautiful Place for Everything You Listen To */}
      <div className="space-y-6 text-center max-w-3xl mx-auto">
        <h3 className="text-3xl sm:text-5xl font-bold tracking-tight text-foreground">
          One Beautiful Place for Everything You Listen To
        </h3>
        <p className="text-base sm:text-lg text-muted-foreground leading-relaxed">
          Keep your Now Playing status, album art, synchronized lyrics, and volume
          neatly accessible right at the top of your screen. Instantly preview,
          scrub tracks, and toggle sources with keyboard shortcuts.
        </p>

        {/* Screen Frame */}
        <div className="rounded-3xl border border-border shadow-2xl overflow-hidden relative aspect-[16/9] w-full mt-8 bg-card flex items-start justify-center pt-8">
          <Image
            src="/images/sonoma-wallpaper.webp"
            alt="macOS Sonoma Desktop"
            fill
            className="object-cover object-center"
            sizes="(max-w-768px) 100vw, 1100px"
          />
          {/* Expanded Media Controller Pill */}
          <div className="relative z-10 w-96 rounded-2xl bg-black/95 text-white border border-white/15 p-4 shadow-2xl space-y-3">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-xl bg-apple-purple/30 border border-white/20 flex items-center justify-center font-bold text-xs">
                M83
              </div>
              <div className="flex-1 min-w-0 text-left">
                <p className="text-sm font-semibold truncate">Midnight City</p>
                <p className="text-xs text-muted-foreground truncate">
                  Hurry Up, We&apos;re Dreaming
                </p>
              </div>
              <Badge variant="hud">Apple Music</Badge>
            </div>
            {/* Progress line */}
            <div className="h-1.5 w-full bg-white/20 rounded-full overflow-hidden">
              <div className="h-full w-2/3 bg-white rounded-full" />
            </div>
            <div className="flex justify-between text-[10px] font-mono text-white/60">
              <span>2:44</span>
              <span>-1:20</span>
            </div>
          </div>
        </div>
      </div>

      {/* TESTIMONIAL 1 */}
      <div className="max-w-2xl mx-auto">
        <Card className="p-8 border border-border shadow-md bg-surface-elevated text-center relative overflow-hidden">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/20 text-amber-600 text-xs font-semibold mb-4">
            COMMUNITY HIGHLIGHT
          </div>
          <p className="text-base sm:text-lg text-foreground font-medium leading-relaxed italic">
            &ldquo;I&apos;ve been using Mac Island for weeks and I LOVE it. It finally
            turns the MacBook notch into something truly functional and delightful.
            Finding which tab is playing audio has never been easier.&rdquo;
          </p>
          <div className="mt-6 flex items-center justify-center gap-2">
            <div className="h-8 w-8 rounded-full bg-foreground text-background font-bold text-xs flex items-center justify-center">
              E
            </div>
            <div className="text-left">
              <p className="text-xs font-semibold text-foreground">Evan</p>
              <p className="text-[11px] text-muted-foreground">
                Lead Designer &amp; Developer
              </p>
            </div>
          </div>
        </Card>
      </div>

      {/* SHOWCASE 3: Control Anything Without Switching Windows */}
      <div className="space-y-6 text-center max-w-3xl mx-auto">
        <h3 className="text-3xl sm:text-5xl font-bold tracking-tight text-foreground">
          Control Anything Without Switching Windows
        </h3>
        <p className="text-base sm:text-lg text-muted-foreground leading-relaxed">
          Keep your media controls right at the top of your Mac. Scrub tracks, adjust
          volume, and read lyrics without opening another window or losing cursor
          focus in your code editor or browser.
        </p>

        {/* Screen Frame */}
        <div className="rounded-3xl border border-border shadow-2xl overflow-hidden relative aspect-[16/9] w-full mt-8 bg-card flex items-center justify-center">
          <Image
            src="/images/sonoma-wallpaper.webp"
            alt="macOS Sonoma Desktop"
            fill
            className="object-cover object-center"
            sizes="(max-w-768px) 100vw, 1100px"
          />
          <div className="relative z-10 p-6 rounded-2xl bg-black/90 border border-white/10 text-white max-w-md text-left shadow-2xl space-y-3">
            <div className="flex items-center gap-2">
              <Icon icon={ShieldCheckIcon} size={18} className="text-apple-green" />
              <span className="text-xs font-mono uppercase font-bold tracking-wider">
                Focus-Safe AppKit Windowing
              </span>
            </div>
            <p className="text-sm text-white/90 leading-relaxed">
              Mac Island stays stationary at status bar layer 25. Clicking buttons
              or scrubbing never deactivates your current foreground window.
            </p>
          </div>
        </div>
      </div>

      {/* TESTIMONIAL 2 */}
      <div className="max-w-2xl mx-auto">
        <Card className="p-8 border border-border shadow-md bg-surface-elevated text-center relative overflow-hidden">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-apple-blue/10 border border-apple-blue/20 text-apple-blue text-xs font-semibold mb-4">
            VERIFIED REVIEW
          </div>
          <p className="text-base sm:text-lg text-foreground font-medium leading-relaxed italic">
            &ldquo;I&apos;ve tried a ton of media controller apps, but they always stole
            window focus or required invasive Accessibility permissions. Mac
            Island&apos;s zero-permission MediaRemote architecture is genius.&rdquo;
          </p>
          <div className="mt-6 flex items-center justify-center gap-2">
            <div className="h-8 w-8 rounded-full bg-apple-blue text-white font-bold text-xs flex items-center justify-center">
              AB
            </div>
            <div className="text-left">
              <p className="text-xs font-semibold text-foreground">Antal Balazs</p>
              <p className="text-[11px] text-muted-foreground">macOS Power User</p>
            </div>
          </div>
        </Card>
      </div>

      {/* SHOWCASE 4: Synchronized Live Lyrics */}
      <div className="space-y-6 text-center max-w-3xl mx-auto">
        <h3 className="text-3xl sm:text-5xl font-bold tracking-tight text-foreground">
          Synchronized Live Lyrics
        </h3>
        <p className="text-base sm:text-lg text-muted-foreground leading-relaxed">
          Karaoke-style synchronized lyrics scroll word-by-word right inside your
          peripheral vision.
        </p>

        <div className="rounded-3xl border border-border shadow-2xl overflow-hidden relative aspect-[16/9] w-full mt-8 bg-card flex items-center justify-center p-6">
          <Image
            src="/images/sonoma-wallpaper.webp"
            alt="macOS Sonoma Desktop"
            fill
            className="object-cover object-center"
            sizes="(max-w-768px) 100vw, 1100px"
          />
          <div className="relative z-10 w-full max-w-lg rounded-2xl bg-black/95 border border-white/10 p-6 text-center space-y-4 shadow-2xl">
            <Badge variant="hud">SYNCHRONIZED NOTCH LYRICS</Badge>
            <p className="text-lg sm:text-xl font-apple-serif italic text-white leading-relaxed">
              &ldquo;The city is my church, it wraps me in the blinding twilight&rdquo;
            </p>
            <p className="text-xs text-white/50 font-mono">
              Auto-fetches synced lyrics without requiring Spotify Premium.
            </p>
          </div>
        </div>
      </div>

      {/* TWO SPLIT CARDS: Custom Categories & Keyboard Shortcuts */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
        <Card className="p-6 border border-border bg-surface-elevated">
          <div className="h-10 w-10 rounded-xl bg-apple-blue/10 border border-apple-blue/20 flex items-center justify-center mb-4">
            <Icon icon={AppWindowMacIcon} size={20} className="text-apple-blue" />
          </div>
          <h4 className="text-xl font-bold text-foreground mb-2">
            One-Click Source Jump
          </h4>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Quickly jump directly to the tab or app playing audio. Instantly focuses
            Safari, Chrome, Brave, Spotify, or Apple Music.
          </p>
        </Card>

        <Card className="p-6 border border-border bg-surface-elevated">
          <div className="h-10 w-10 rounded-xl bg-apple-purple/10 border border-apple-purple/20 flex items-center justify-center mb-4">
            <Icon icon={SlidersHorizontalIcon} size={20} className="text-apple-purple" />
          </div>
          <h4 className="text-xl font-bold text-foreground mb-2">
            Global Keyboard Shortcuts
          </h4>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Press <code className="bg-muted px-1.5 py-0.5 rounded text-xs font-mono">⌥ + Space</code> to
            expand or collapse the island instantly from anywhere on your Mac.
          </p>
        </Card>
      </div>
    </section>
  );
}
