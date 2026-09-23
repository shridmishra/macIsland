"use client";

import * as React from "react";
import {
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
} from "@/components/ui/accordion";

export function FAQSection() {
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
    <section id="faq" className="py-24 max-w-3xl mx-auto px-4">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-14">
        <h2 className="text-4xl sm:text-6xl font-bold tracking-tight text-foreground leading-[1.08]">
          Frequently Asked
          <span className="font-apple-serif italic font-normal block text-muted-foreground mt-1">
            Questions.
          </span>
        </h2>
        <p className="mt-4 text-base sm:text-lg text-muted-foreground">
          Everything you need to know about getting started with Mac Island, from
          features and pricing to privacy and system compatibility.
        </p>
      </div>

      {/* Accordion */}
      <Accordion type="single" collapsible className="w-full space-y-3">
        {faqs.map((faq, index) => (
          <AccordionItem
            key={index}
            value={`item-${index}`}
            className="border border-border bg-surface-elevated shadow-sm"
          >
            <AccordionTrigger className="text-base font-semibold text-foreground px-5 py-4">
              {faq.q}
            </AccordionTrigger>
            <AccordionContent className="text-sm leading-relaxed text-muted-foreground px-5 pb-5">
              {faq.a}
            </AccordionContent>
          </AccordionItem>
        ))}
      </Accordion>
    </section>
  );
}
