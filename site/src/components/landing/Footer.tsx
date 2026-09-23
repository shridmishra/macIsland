"use client";

import * as React from "react";
import Image from "next/image";
import Link from "next/link";
import { AppleOfficialIcon } from "@/components/ui/apple-icon";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export interface FooterLink {
  label: string;
  href: string;
  external?: boolean;
}

export interface FooterProps {
  variant?: "supaste" | "macisland";
  appName?: string;
  appBadge?: string;
  headlineBold?: string;
  headlineItalic?: string;
  description?: string;
  downloadText?: string;
  downloadHref?: string;
  copyrightText?: string;
  creatorName?: string;
  creatorAvatar?: string;
  creatorHref?: string;
  menuLinks?: FooterLink[];
  navLinks?: FooterLink[];
  productLinks?: FooterLink[];
  showAwwwardsBadge?: boolean;
  className?: string;
}

export function SupasteAppIcon({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "relative h-6 w-6 rounded-[7px] bg-gradient-to-b from-sky-400 via-apple-blue to-blue-700 p-0.5 shadow-md flex items-center justify-center overflow-hidden border border-white/20 shrink-0",
        className
      )}
    >
      {/* Top Gloss Highlight */}
      <div className="absolute top-0 inset-x-0 h-2 bg-gradient-to-b from-white/40 to-transparent pointer-events-none" />
      {/* Metallic clip */}
      <div className="absolute top-0.5 w-3 h-0.5 rounded-full bg-white/90 shadow-xs" />
      {/* Sheet silhouette */}
      <div className="w-3 h-3 mt-1 rounded-[1.5px] bg-white/25 border border-white/40 flex flex-col items-center justify-center gap-0.5">
        <div className="w-1.5 h-[1px] bg-white/75 rounded-full" />
        <div className="w-1.5 h-[1px] bg-white/50 rounded-full" />
      </div>
    </div>
  );
}

export function MacIslandAppIcon({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "h-6 w-6 rounded-[7px] bg-gradient-to-br from-apple-blue via-apple-purple to-hero-orange-mid flex items-center justify-center p-0.5 shadow-md border border-white/20 shrink-0",
        className
      )}
    >
      <AppleOfficialIcon size={12} className="text-white drop-shadow-sm" />
    </div>
  );
}

const DEFAULT_SUPASTE_MENU: FooterLink[] = [
  { label: "Home", href: "#hero" },
  { label: "Features", href: "#features" },
  { label: "FAQ", href: "#faq" },
  { label: "Pricing", href: "#pricing" },
  { label: "Updates", href: "#updates" },
];

const DEFAULT_SUPASTE_NAV: FooterLink[] = [
  { label: "Contact", href: "mailto:support@supaste.com", external: true },
  { label: "Roadmap", href: "#roadmap" },
  { label: "Privacy policy", href: "/privacy" },
  { label: "Terms of service", href: "/terms" },
  { label: "Customer portal", href: "#portal" },
];

const DEFAULT_SUPASTE_PRODUCTS: FooterLink[] = [
  { label: "Screen Movie", href: "https://screenmovie.app", external: true },
  { label: "Cooldock", href: "https://cooldock.app", external: true },
  { label: "Macapp.Supply", href: "https://macapp.supply", external: true },
  { label: "Runey.app", href: "https://runey.app", external: true },
  { label: "Revone.app", href: "https://revone.app", external: true },
  { label: "Icoon.co", href: "https://icoon.co", external: true },
  { label: "Selected.site", href: "https://selected.site", external: true },
  { label: "Supaframe.io", href: "https://supaframe.io", external: true },
  { label: "Frameblox.com", href: "https://frameblox.com", external: true },
];

const DEFAULT_MACISLAND_MENU: FooterLink[] = [
  { label: "Home", href: "#hero" },
  { label: "Features", href: "#features" },
  { label: "FAQ", href: "#faq" },
  { label: "Pricing (Free)", href: "#pricing" },
];

const DEFAULT_MACISLAND_NAV: FooterLink[] = [
  { label: "Download Free for Mac", href: "#pricing" },
  { label: "Privacy policy", href: "/privacy" },
  { label: "Terms of service", href: "/terms" },
  { label: "Customer Support", href: "mailto:support@macisland.app", external: true },
];

const DEFAULT_MACISLAND_PRODUCTS: FooterLink[] = [
  { label: "Screen Movie", href: "https://screenmovie.app", external: true },
  { label: "Cooldock", href: "https://cooldock.app", external: true },
  { label: "Macapp.Supply", href: "https://macapp.supply", external: true },
  { label: "Runey.app", href: "https://runey.app", external: true },
  { label: "Revone.app", href: "https://revone.app", external: true },
];

export function Footer({
  variant = "supaste",
  appName,
  appBadge,
  headlineBold,
  headlineItalic,
  description,
  downloadText,
  downloadHref,
  copyrightText,
  creatorName,
  creatorAvatar,
  creatorHref,
  menuLinks,
  navLinks,
  productLinks,
  showAwwwardsBadge = true,
  className,
}: FooterProps) {
  const isMacIsland = variant === "macisland";

  const resolvedAppName = appName ?? (isMacIsland ? "Mac Island" : "Supaste");
  const resolvedAppBadge = appBadge ?? "macOS app";
  const resolvedHeadlineBold = headlineBold ?? (isMacIsland ? "Glance once." : "Copy once.");
  const resolvedHeadlineItalic = headlineItalic ?? (isMacIsland ? "Control anytime." : "Reuse anytime.");
  const resolvedDescription =
    description ??
    (isMacIsland
      ? "Mac Island transforms your MacBook notch into an intelligent Dynamic Island, automatically grouping live media playback, lyrics, and stealth system HUDs in seconds."
      : "Supaste saves your clipboard and screenshots in a beautiful visual history, automatically grouped by type, app, and custom categories, so you can search, find, and paste anything back in seconds.");
  const resolvedDownloadText = downloadText ?? (isMacIsland ? "Download Free for Mac" : "Download for macOS");
  const resolvedDownloadHref =
    downloadHref ??
    (isMacIsland
      ? "#pricing"
      : "https://supaste.com");
  const resolvedCopyright =
    copyrightText ??
    (isMacIsland
      ? "© 2026 Mac Island · Free & Open Core"
      : "© 2026 Supaste.com - All rights reserved");
  const resolvedCreatorName = creatorName ?? "Solt Wagner";
  const resolvedCreatorAvatar = creatorAvatar ?? "/images/creator-avatar.png";
  const resolvedCreatorHref =
    creatorHref ?? (isMacIsland ? "https://macisland.app" : "https://x.com/soltwagner");

  const resolvedMenu = menuLinks ?? (isMacIsland ? DEFAULT_MACISLAND_MENU : DEFAULT_SUPASTE_MENU);
  const resolvedNav = navLinks ?? (isMacIsland ? DEFAULT_MACISLAND_NAV : DEFAULT_SUPASTE_NAV);
  const resolvedProducts =
    productLinks ?? (isMacIsland ? DEFAULT_MACISLAND_PRODUCTS : DEFAULT_SUPASTE_PRODUCTS);

  return (
    <footer
      className={cn("w-full relative select-none", className)}
      role="contentinfo"
    >
      {/* 1. Signature Scooped Top Transition Bar */}
      <div
        className="w-full flex items-end h-7 pointer-events-none -mb-px relative z-10"
        aria-hidden="true"
      >
        {/* Left Shoulder (Elevated black ledge) */}
        <div className="flex-1 min-w-4 sm:min-w-8 lg:min-w-16 h-full bg-footer-bg" />

        {/* Left Smooth S-Curve Fillet (Drops y: 0 -> 28px) */}
        <svg
          viewBox="0 0 28 28"
          className="w-7 h-7 shrink-0 block"
          preserveAspectRatio="none"
        >
          <path
            d="M 0,0 C 14,0 14,14 14,14 C 14,14 14,28 28,28 L 0,28 Z"
            className="fill-footer-bg"
          />
        </svg>

        {/* Central Recess Spacer (Transparent window exposing the page's light background) */}
        <div className="w-full max-w-6xl h-full shrink" />

        {/* Right Smooth S-Curve Fillet (Rises y: 28px -> 0) */}
        <svg
          viewBox="0 0 28 28"
          className="w-7 h-7 shrink-0 block"
          preserveAspectRatio="none"
        >
          <path
            d="M 0,28 C 14,28 14,14 14,14 C 14,14 14,0 28,0 L 28,28 Z"
            className="fill-footer-bg"
          />
        </svg>

        {/* Right Shoulder (Elevated black ledge) */}
        <div className="flex-1 min-w-4 sm:min-w-8 lg:min-w-16 h-full bg-footer-bg" />
      </div>

      {/* 2. Main Pitch-Black Footer Body */}
      <div className="bg-footer-bg text-footer-foreground w-full relative pt-10 sm:pt-14 pb-20 overflow-hidden">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="grid grid-cols-1 md:grid-cols-12 gap-10 lg:gap-14">
            {/* Column 1: Brand, Tagline, Description & CTA */}
            <div className="md:col-span-5 lg:col-span-5 space-y-4 text-left">
              {/* Brand Header */}
              <div className="flex items-center gap-2.5">
                {isMacIsland ? <MacIslandAppIcon /> : <SupasteAppIcon />}
                <span className="font-bold text-sm tracking-tight text-footer-foreground">
                  {resolvedAppName}
                </span>
                <span className="text-xs text-footer-muted font-normal">
                  {resolvedAppBadge}
                </span>
              </div>

              {/* Bold / Italic Serif Headline */}
              <div className="space-y-0.5 pt-1">
                <h3 className="text-3xl sm:text-4xl font-bold tracking-tight text-footer-foreground leading-tight">
                  {resolvedHeadlineBold}
                </h3>
                <p className="text-3xl sm:text-4xl font-apple-serif italic font-normal text-footer-foreground leading-tight tracking-tight">
                  {resolvedHeadlineItalic}
                </p>
              </div>

              {/* Description Copy */}
              <p className="text-xs text-footer-muted leading-relaxed max-w-[340px] pt-1">
                {resolvedDescription}
              </p>

              {/* Apple Download Button */}
              <div className="pt-2">
                <Button
                  asChild
                  variant="appleWhite"
                  size="sm"
                  className="h-8 px-3.5 gap-2 font-medium shadow-sm hover:opacity-95"
                >
                  <a
                    href={resolvedDownloadHref}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <AppleOfficialIcon size={12} className="text-black shrink-0" />
                    <span>{resolvedDownloadText}</span>
                  </a>
                </Button>
              </div>

              {/* Copyright Notice */}
              <div className="pt-2">
                <p className="text-xs text-footer-subtle">
                  {resolvedCopyright}
                </p>
              </div>

              {/* Creator Attribution */}
              <div className="flex items-center gap-2 text-xs text-footer-muted pt-1">
                <span>
                  Built with <span className="text-apple-blue inline-block">💙</span> by
                </span>
                <a
                  href={resolvedCreatorHref}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 text-footer-foreground hover:underline font-medium transition-colors"
                >
                  {resolvedCreatorAvatar && (
                    <Image alt={resolvedCreatorName}
                      src={resolvedCreatorAvatar}
                      width={18}
                      height={18}
                      className="rounded-full object-cover shrink-0 border border-white/10"
                    />
                  )}
                  <span>{resolvedCreatorName}</span>
                </a>
              </div>
            </div>

            {/* Column 2: Menu */}
            <div className="md:col-span-2 lg:col-span-2 space-y-3.5">
              <h4 className="text-xs font-medium text-footer-muted tracking-wide">
                Menu
              </h4>
              <ul className="space-y-2.5 text-xs">
                {resolvedMenu.map((link) => (
                  <li key={link.label}>
                    <Link
                      href={link.href}
                      className="text-footer-foreground hover:text-white transition-colors duration-150 inline-block"
                      {...(link.external
                        ? { target: "_blank", rel: "noopener noreferrer" }
                        : {})}
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            {/* Column 3: Navigation */}
            <div className="md:col-span-2 lg:col-span-2 space-y-3.5">
              <h4 className="text-xs font-medium text-footer-muted tracking-wide">
                Navigation
              </h4>
              <ul className="space-y-2.5 text-xs">
                {resolvedNav.map((link) => (
                  <li key={link.label}>
                    <Link
                      href={link.href}
                      className="text-footer-foreground hover:text-white transition-colors duration-150 inline-block"
                      {...(link.external
                        ? { target: "_blank", rel: "noopener noreferrer" }
                        : {})}
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            {/* Column 4: More Products */}
            <div className="md:col-span-3 lg:col-span-3 space-y-3.5">
              <h4 className="text-xs font-medium text-footer-muted tracking-wide">
                More products
              </h4>
              <ul className="space-y-2.5 text-xs">
                {resolvedProducts.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-footer-foreground hover:text-white transition-colors duration-150 inline-block"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        {/* 3. Awwwards Honors Ribbon (Pinned to Right Edge) */}
        {showAwwwardsBadge && (
          <aside
            className="hidden xl:flex absolute right-0 top-1/2 -translate-y-1/2 z-20 flex-col items-center gap-4 py-4 px-2 select-none"
            aria-label="Awwwards Honors"
          >
            <a
              href="https://www.awwwards.com"
              target="_blank"
              rel="noopener noreferrer"
              className="flex flex-col items-center gap-3.5 group"
            >
              <span className="font-bold text-base tracking-tighter text-footer-foreground group-hover:scale-105 transition-transform font-serif leading-none">
                W.
              </span>
              <span className="text-xs uppercase tracking-widest text-footer-muted group-hover:text-footer-foreground font-semibold [writing-mode:vertical-rl] transition-colors leading-none">
                Honors
              </span>
            </a>
          </aside>
        )}
      </div>
    </footer>
  );
}
