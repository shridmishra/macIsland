"use client";

import * as React from "react";
import Image from "next/image";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Button } from "@/components/ui/button";

export function BottomCtaBanner() {
  return (
    <section className="py-20 max-w-5xl mx-auto px-4">
      {/* Main Banner Card */}
      <div className="rounded-3xl border border-border bg-surface-elevated p-8 sm:p-12 flex flex-col md:flex-row items-center justify-between gap-8 shadow-xl overflow-hidden relative">
        {/* Left Copy & CTA */}
        <div className="space-y-4 max-w-md text-left">
          <h3 className="text-3xl sm:text-4xl font-bold tracking-tight text-foreground leading-tight">
            Glance once.{" "}
            <span className="font-apple-serif italic font-normal text-muted-foreground block">
              Control everything.
            </span>
          </h3>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Mac Island turns your MacBook notch into an intelligent Dynamic Island.
            Download the free universal app and experience fluid media control.
          </p>
          <div className="pt-2">
            <Button
              asChild
              variant="heroBlack"
              size="lg"
              className="gap-2.5 h-12 px-6"
            >
              <a
                href="https://github.com/shridhar/macIsland/releases"
                target="_blank"
                rel="noopener noreferrer"
              >
                <AppleOfficialIcon size={16} className="text-white" />
                <span>Download for macOS</span>
              </a>
            </Button>
          </div>
        </div>

        {/* Right Mini Desktop Mockup */}
        <div className="w-full md:w-80 h-48 rounded-2xl overflow-hidden border border-border shadow-lg relative bg-card shrink-0">
          <Image
            src="/images/sonoma-wallpaper.webp"
            alt="macOS Sonoma Screen"
            fill
            className="object-cover object-center"
            sizes="350px"
          />
          {/* Mini Notch */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-5 bg-black rounded-b-lg border-x border-b border-white/10 flex items-center justify-between px-2 text-[8px] text-white">
            <span className="h-1 w-1 rounded-full bg-apple-green" />
            <span className="truncate text-[8px]">Now Playing</span>
            <div className="flex gap-0.5 h-2 items-center">
              <span className="w-0.5 h-1.5 bg-apple-green rounded-full" />
              <span className="w-0.5 h-2 bg-apple-green rounded-full" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
