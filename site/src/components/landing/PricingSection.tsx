"use client";

import * as React from "react";
import {
  CheckmarkCircle02Icon,
  GithubIcon,
  ShieldCheckIcon,
} from "@hugeicons/core-free-icons";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Card, CardHeader, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Icon } from "@/components/ui/icon";

export function PricingSection() {
  const features = [
    "Universal macOS binary (Apple Silicon M1–M4 & Intel)",
    "Zero permission prompts (Dynamic MediaRemote hooks)",
    "Hardware notch hugging + floating capsule modes",
    "Real-time synchronized scrolling lyrics",
    "Stealth System HUD (Volume & Brightness in the notch)",
    "Non-activating windowing (zero cursor focus interruption)",
    "100% Offline & Private — zero analytics or telemetry",
    "macOS Sonoma 14.0 & Sequoia 15.0 ready",
  ];

  return (
    <section id="pricing" className="py-24 max-w-5xl mx-auto px-4 relative overflow-hidden">
      {/* Light Pink Ambient Aura matching user's pink request */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[500px] bg-hero-pink-mid/10 rounded-full blur-3xl pointer-events-none -z-10" />

      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-14">
        <h2 className="text-5xl sm:text-7xl font-bold tracking-tight text-foreground leading-[1.05]">
          100% Free.
          <span className="font-apple-serif italic font-normal block mt-1 text-muted-foreground">
            Open Source.
          </span>
        </h2>
        <p className="mt-5 text-base sm:text-lg text-muted-foreground leading-relaxed">
          No subscriptions. No tracking. No hidden fees. Mac Island is completely
          free and open-source for every Mac user.
        </p>
      </div>

      {/* Main Pricing Solid Card */}
      <div className="max-w-md mx-auto">
        <Card hoverEffect className="apple-card p-8 relative overflow-hidden border border-border bg-card shadow-2xl">
          <CardHeader className="pb-6">
            <div className="flex items-center justify-between">
              <Badge variant="solid" className="font-mono text-xs bg-surface-elevated text-foreground border-border">
                OPEN SOURCE &amp; FREE
              </Badge>
              <span className="text-xs text-apple-green font-mono flex items-center gap-1">
                <span className="h-1.5 w-1.5 rounded-full bg-apple-green" />
                Universal v1.2
              </span>
            </div>

            <div className="mt-5 flex items-baseline gap-2">
              <span className="text-6xl font-extrabold tracking-tight text-foreground">
                $0
              </span>
              <span className="text-sm text-muted-foreground font-medium">
                Free forever
              </span>
            </div>

            <CardDescription className="text-sm mt-3 leading-relaxed text-muted-foreground">
              Download the pre-compiled universal macOS DMG directly, or build from
              source using Swift Package Manager.
            </CardDescription>
          </CardHeader>

          {/* Feature Checklist */}
          <CardContent className="space-y-3 py-4 border-t border-border">
            <p className="text-xs font-mono uppercase tracking-wider text-muted-foreground mb-4">
              Everything included:
            </p>
            {features.map((f, i) => (
              <div key={i} className="flex items-center gap-3 text-sm text-foreground/90">
                <Icon
                  icon={CheckmarkCircle02Icon}
                  size={18}
                  className="text-apple-green shrink-0"
                />
                <span>{f}</span>
              </div>
            ))}
          </CardContent>

          {/* CTA Buttons */}
          <CardFooter className="flex flex-col gap-3 pt-6 border-t border-border">
            <Button
              asChild
              variant="heroBlack"
              size="lg"
              className="w-full gap-2.5 text-base font-semibold h-13 shadow-xl"
            >
              <a
                href="https://github.com/shridhar/macIsland/releases"
                target="_blank"
                rel="noopener noreferrer"
              >
                <AppleOfficialIcon size={18} className="text-white" />
                <span>Download for macOS (Free)</span>
              </a>
            </Button>

            <Button
              asChild
              variant="solid"
              size="default"
              className="w-full gap-2 text-sm h-10 border border-border"
            >
              <a
                href="https://github.com/shridhar/macIsland"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Icon icon={GithubIcon} size={16} />
                <span>View Swift Source Code on GitHub</span>
              </a>
            </Button>

            <div className="flex items-center justify-center gap-2 mt-2 text-[11px] text-muted-foreground font-mono">
              <Icon icon={ShieldCheckIcon} size={14} className="text-apple-green" />
              <span>Apple Notarized • 100% Free &amp; Open Source</span>
            </div>
          </CardFooter>
        </Card>
      </div>
    </section>
  );
}
