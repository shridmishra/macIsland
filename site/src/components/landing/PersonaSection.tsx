"use client";

import * as React from "react";
import {
  CodeIcon,
  AppWindowMacIcon,
  HeadphonesIcon,
  SlidersHorizontalIcon,
  AudioWave01Icon,
  VolumeHighIcon,
} from "@hugeicons/core-free-icons";
import { Card, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";

export function PersonaSection() {
  const personas = [
    {
      icon: CodeIcon,
      accent: "text-apple-green",
      bg: "bg-apple-green/10",
      title: "Developers",
      desc: "Stay locked in terminal and code editor sessions. Mac Island's non-activating panel ensures clicking controls never steals cursor focus.",
    },
    {
      icon: AppWindowMacIcon,
      accent: "text-apple-blue",
      bg: "bg-apple-blue/10",
      title: "Designers",
      desc: "Minimalist Apple aesthetics that respect your screen real estate. Dynamic ambient backlighting complements your canvas.",
    },
    {
      icon: HeadphonesIcon,
      accent: "text-apple-purple",
      bg: "bg-apple-purple/10",
      title: "Audiophiles",
      desc: "Scrub lossless audio with precision, follow synchronized line-by-line lyrics, and toggle equalizers seamlessly.",
    },
    {
      icon: AudioWave01Icon,
      accent: "text-apple-orange",
      bg: "bg-apple-orange/10",
      title: "Podcasters & Creators",
      desc: "Monitor audio streams, podcasts, and video timelines while multitasking across multiple desktop spaces.",
    },
    {
      icon: SlidersHorizontalIcon,
      accent: "text-apple-blue",
      bg: "bg-apple-blue/10",
      title: "Multi-Monitor Users",
      desc: "Adapts automatically between your MacBook notch and Studio Display or Pro Display XDR floating pill.",
    },
    {
      icon: VolumeHighIcon,
      accent: "text-apple-green",
      bg: "bg-apple-green/10",
      title: "Everyday Mac Lovers",
      desc: "Replaces intrusive center-screen volume and brightness HUD overlays with fluid stealth indicators.",
    },
  ];

  return (
    <section className="py-24 max-w-5xl mx-auto px-4">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <h2 className="text-4xl sm:text-6xl font-bold tracking-tight text-foreground leading-[1.08]">
          Built for everything you{" "}
          <span className="font-apple-serif italic font-normal text-muted-foreground">
            listen to.
          </span>
        </h2>
        <p className="mt-4 text-muted-foreground text-base sm:text-lg max-w-2xl mx-auto">
          From Spotify and Apple Music playlists to YouTube tutorials, podcasts,
          and sound clips, Mac Island keeps your audio right where you need it.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
        {personas.map((p, i) => (
          <Card key={i} hoverEffect className="p-6 border border-border bg-surface-elevated flex flex-col justify-between">
            <CardHeader className="p-0">
              <div className="flex items-center gap-3 mb-3">
                <div
                  className={`h-10 w-10 rounded-xl ${p.bg} border border-border flex items-center justify-center`}
                >
                  <Icon icon={p.icon} size={20} className={p.accent} />
                </div>
                <CardTitle className="text-lg">{p.title}</CardTitle>
              </div>
              <CardDescription className="text-sm leading-relaxed text-muted-foreground">
                {p.desc}
              </CardDescription>
            </CardHeader>
          </Card>
        ))}
      </div>
    </section>
  );
}
