"use client";

import * as React from "react";
import { NewTwitterIcon, DiscordIcon, Github01Icon } from "@hugeicons/core-free-icons";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Button } from "@/components/ui/button";
import { Icon } from "@/components/ui/icon";
import { DownloadNavbar } from "@/components/landing/DownloadNavbar";
import { DownloadCard } from "@/components/landing/DownloadCard";
import { FaqDialog } from "@/components/landing/FaqDialog";
import { ChangelogDialog } from "@/components/landing/ChangelogDialog";

export default function Home() {
  const [faqOpen, setFaqOpen] = React.useState(false);
  const [changelogOpen, setChangelogOpen] = React.useState(false);

  return (
    <main className="min-h-screen bg-background text-foreground flex flex-col justify-between selection:bg-accent selection:text-accent-foreground relative overflow-x-hidden">
      {/* 1. Minimal Top Navigation */}
      <DownloadNavbar
        onOpenFaq={() => setFaqOpen(true)}
        onOpenChangelog={() => setChangelogOpen(true)}
      />

      {/* 2. Main Hero & Download Section */}
      <section className="flex-1 flex flex-col items-center justify-center px-4 pt-6 sm:pt-10 pb-6 w-full max-w-4xl mx-auto">
        {/* Main Bold Headline */}
        <h1 className="text-[38px] sm:text-[62px] md:text-[72px] font-black tracking-tight text-foreground text-center leading-[1.08] select-none">
          <span className="block">Download Mac Island</span>
          <span className="flex items-center justify-center gap-2 sm:gap-3 mt-1 sm:mt-2">
            <span className="font-extrabold">for</span>
            <AppleOfficialIcon size={32} className="text-foreground shrink-0" />
            <span className="inline-block bg-highlight-pill text-foreground px-3.5 py-0.5 rounded-xl font-black">
              Mac
            </span>
          </span>
        </h1>

        {/* Installation Subtitle with Inline App Icon */}
        <p className="text-xs sm:text-sm text-foreground/80 text-center max-w-lg mx-auto mt-5 sm:mt-6 leading-relaxed font-normal select-none">
          <span>Once downloaded, run the DMG and move </span>
          <span className="inline-flex items-center gap-1.5 font-semibold text-foreground align-middle">
            <span className="h-4 w-4 rounded-[4px] bg-gradient-to-br from-apple-blue via-apple-purple to-hero-orange-start inline-flex items-center justify-center p-0.5 border border-border shrink-0">
              <AppleOfficialIcon size={9} className="text-white" />
            </span>
            Mac Island
          </span>
          <span> to your Applications folder </span>
          <span className="italic font-medium">before</span>
          <span> launching it.</span>
        </p>

        {/* Centerpiece DMG Download Card */}
        <div className="w-full mt-7 sm:mt-9 mb-7">
          <DownloadCard />
        </div>

        {/* Help / Contact Us Notice */}
        <p className="text-xs sm:text-sm text-muted-foreground text-center">
          If you have any issues downloading or installing, please{" "}
          <a
            href="mailto:support@macisland.app"
            className="text-foreground underline underline-offset-4 hover:opacity-80 transition-opacity font-medium"
          >
            contact us
          </a>
          .
        </p>

        {/* Social Icons Row */}
        <div className="flex items-center justify-center gap-3 mt-6">
          <Button
            asChild
            variant="social"
            size="iconBox"
            aria-label="Mac Island on X (Twitter)"
          >
            <a
              href="https://x.com/macislandapp"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon icon={NewTwitterIcon} size={15} />
            </a>
          </Button>

          <Button
            asChild
            variant="social"
            size="iconBox"
            aria-label="Mac Island Discord Community"
          >
            <a
              href="https://discord.gg/macisland"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon icon={DiscordIcon} size={16} />
            </a>
          </Button>

          <Button
            asChild
            variant="social"
            size="iconBox"
            aria-label="Mac Island GitHub Repository"
          >
            <a
              href="https://github.com/shridmishra/macIsland"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Icon icon={Github01Icon} size={16} />
            </a>
          </Button>
        </div>
      </section>

      {/* 3. Giant Subtle Bottom Watermark */}
      <div
        className="w-full flex justify-center pointer-events-none select-none overflow-hidden -mb-4 sm:-mb-8"
        aria-hidden="true"
      >
        <span className="text-[96px] xs:text-[120px] sm:text-[180px] md:text-[230px] font-black tracking-tighter text-watermark leading-none whitespace-nowrap">
          Mac Island
        </span>
      </div>

      {/* 4. Full FAQ Dialog Overlay */}
      <FaqDialog open={faqOpen} onOpenChange={setFaqOpen} />

      {/* 5. Changelog & Updates Dialog Overlay */}
      <ChangelogDialog
        open={changelogOpen}
        onOpenChange={setChangelogOpen}
      />
    </main>
  );
}
