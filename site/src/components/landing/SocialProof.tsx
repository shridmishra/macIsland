"use client";

import * as React from "react";
import { GithubIcon } from "@hugeicons/core-free-icons";
import { Badge } from "@/components/ui/badge";
import { Icon } from "@/components/ui/icon";

export function SocialProof() {
  return (
    <section className="py-12 border-y border-border-subtle bg-card-secondary/50 relative overflow-hidden">
      <div className="max-w-6xl mx-auto px-4 flex flex-col items-center text-center">
        <p className="text-xs font-mono uppercase tracking-widest text-muted-foreground mb-6">
          Featured & Celebrated Across The Mac Community
        </p>

        {/* Badges Grid - Solid Apple Cards */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3 w-full max-w-4xl">
          <div className="apple-card flex items-center justify-center gap-2 py-3 px-4 rounded-xl">
            <Icon icon={GithubIcon} size={16} className="text-foreground" />
            <span className="text-xs font-semibold text-foreground">GitHub</span>
            <Badge variant="hud" className="text-[10px] py-0 px-1.5 ml-1">
              Trending
            </Badge>
          </div>

          <div className="apple-card flex items-center justify-center gap-2 py-3 px-4 rounded-xl">
            <span className="font-bold text-xs text-foreground tracking-tighter">Y</span>
            <span className="text-xs font-semibold text-foreground">Hacker News</span>
            <Badge variant="hud" className="text-[10px] py-0 px-1.5 ml-1">
              Top #1
            </Badge>
          </div>

          <div className="apple-card flex items-center justify-center gap-2 py-3 px-4 rounded-xl">
            <span className="font-bold text-xs text-foreground">P</span>
            <span className="text-xs font-semibold text-foreground">Product Hunt</span>
            <Badge variant="hud" className="text-[10px] py-0 px-1.5 ml-1">
              #1 Daily
            </Badge>
          </div>

          <div className="apple-card flex items-center justify-center gap-2 py-3 px-4 rounded-xl">
            <span className="font-serif italic text-xs text-foreground font-bold">MS</span>
            <span className="text-xs font-semibold text-foreground">MacStories</span>
          </div>

          <div className="apple-card col-span-2 sm:col-span-1 flex items-center justify-center gap-2 py-3 px-4 rounded-xl">
            <span className="font-mono font-bold text-xs text-foreground">9to5</span>
            <span className="text-xs font-semibold text-foreground">9to5Mac</span>
          </div>
        </div>
      </div>
    </section>
  );
}
