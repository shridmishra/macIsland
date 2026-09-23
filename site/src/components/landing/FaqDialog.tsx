"use client";

import * as React from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/components/ui/accordion";

interface FaqDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function FaqDialog({ open, onOpenChange }: FaqDialogProps) {
  const faqs = [
    {
      q: "Is Mac Island free to use?",
      a: "Yes! All core features of Mac Island are 100% free to download and use forever—no credit card required, no trial expiration, and no recurring subscriptions. In the future, an optional Pro tier will offer advanced power features, but everything available today remains completely free.",
    },
    {
      q: "Does Mac Island require Accessibility or Automation permissions?",
      a: "No! Unlike standard AppleScript utilities that require invasive Accessibility permissions and per-app Automation alerts, Mac Island dynamically binds to macOS MediaRemote.framework at runtime. It detects playback automatically with zero permission prompts.",
    },
    {
      q: "What happens on Macs without a notch (Mac mini, Mac Studio, iMac, or external displays)?",
      a: "Mac Island automatically detects your display geometry. On non-notched Macs or external screens (such as Apple Studio Display or Pro Display XDR), it floats gracefully as a compact capsule anchored at the top menu bar altitude.",
    },
    {
      q: "Which music players and video streaming apps are supported?",
      a: "Mac Island universally supports Apple Music, Spotify, YouTube (in Safari, Brave, and Google Chrome), Soundcloud, Podcasts, and any macOS app that outputs audio through system media channels.",
    },
    {
      q: "Does Mac Island drain battery or consume noticeable CPU?",
      a: "No. Because it is written in 100% pure native Swift and AppKit (without Electron or Chromium runtimes), Mac Island consumes 0.0% CPU when media is paused or when collapsed at idle, using less than 28MB of memory.",
    },
    {
      q: "How does focus-stealing prevention work?",
      a: "Mac Island utilizes an AppKit NSPanel with the .nonactivatingPanel attribute set at the .statusBar window level (Layer 25). This guarantees that clicking pause/play, scrubbing timelines, or hovering over the island will never steal cursor focus from Xcode, VS Code, or your terminal.",
    },
    {
      q: "Is Mac Island 100% private and offline?",
      a: "Yes. Mac Island contains zero analytics, zero trackers, and zero telemetry. It runs completely offline on your Mac with zero cloud dependency and zero network data collection.",
    },
  ];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl border border-border bg-card">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold tracking-tight text-foreground">
            Frequently Asked Questions
          </DialogTitle>
          <DialogDescription className="text-sm text-muted-foreground">
            Everything you need to know about getting started with Mac Island.
          </DialogDescription>
        </DialogHeader>

        <Accordion type="single" collapsible className="w-full space-y-2 mt-2">
          {faqs.map((faq, index) => (
            <AccordionItem
              key={index}
              value={`item-${index}`}
              className="border border-border rounded-xl px-3 bg-surface-elevated/70"
            >
              <AccordionTrigger className="text-sm font-semibold text-foreground py-3.5 hover:no-underline">
                {faq.q}
              </AccordionTrigger>
              <AccordionContent className="text-xs leading-relaxed text-muted-foreground pb-4">
                {faq.a}
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </DialogContent>
    </Dialog>
  );
}
