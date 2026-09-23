"use client";

import * as React from "react";
import Link from "next/link";
import { Comment01Icon, Notebook01Icon } from "@hugeicons/core-free-icons";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Icon } from "@/components/ui/icon";

interface DownloadNavbarProps {
  onOpenFaq: () => void;
  onOpenChangelog: () => void;
}

export function DownloadNavbar({
  onOpenFaq,
  onOpenChangelog,
}: DownloadNavbarProps) {
  return (
    <header className="w-full max-w-5xl mx-auto px-6 sm:px-8 pt-7 pb-4 flex items-center justify-between">
      {/* Brand Logo, Name & Version Badge */}
      <Link href="/" className="flex items-center gap-3 group select-none">
        {/* Glossy App Icon Squircle */}
        <div className="h-8 w-8 rounded-xl bg-gradient-to-br from-apple-blue via-apple-purple to-hero-orange-start flex items-center justify-center p-1 shadow-xs border border-border transition-transform duration-200 group-hover:scale-105">
          <AppleOfficialIcon size={16} className="text-white drop-shadow-2xs" />
        </div>

        <span className="font-bold text-base sm:text-lg tracking-tight text-foreground">
          Mac Island
        </span>

        <Badge variant="version" className="hidden xs:inline-flex">
          v1.2
        </Badge>
      </Link>

      {/* Header Actions: FAQs & Changelog */}
      <nav className="flex items-center gap-1 sm:gap-2" aria-label="Main Navigation">
        <Button
          variant="ghost"
          size="sm"
          onClick={onOpenFaq}
          className="gap-1.5 text-xs font-semibold text-foreground/85 hover:text-foreground"
        >
          <Icon icon={Comment01Icon} size={15} />
          <span>FAQs</span>
        </Button>

        <Button
          variant="ghost"
          size="sm"
          onClick={onOpenChangelog}
          className="gap-1.5 text-xs font-semibold text-foreground/85 hover:text-foreground"
        >
          <Icon icon={Notebook01Icon} size={15} />
          <span>Changelog</span>
        </Button>
      </nav>
    </header>
  );
}
