import * as React from "react";
import { cn } from "@/lib/utils";

export interface MacDmgDriveProps extends React.SVGProps<SVGSVGElement> {
  size?: number;
  className?: string;
}

export function MacDmgDrive({
  size = 112,
  className,
  ...props
}: MacDmgDriveProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 120 120"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={cn("drop-shadow-md select-none", className)}
      role="img"
      aria-label="Mac Island DMG Drive Icon"
      {...props}
    >
      <defs>
        {/* Outer Aluminum Chassis Gradient */}
        <linearGradient id="dmg-chassis" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#f3f4f6" />
          <stop offset="15%" stopColor="#e5e7eb" />
          <stop offset="70%" stopColor="#d1d5db" />
          <stop offset="100%" stopColor="#9ca3af" />
        </linearGradient>

        {/* Chassis Top Edge Highlight */}
        <linearGradient id="dmg-bevel" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#ffffff" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#ffffff" stopOpacity="0.1" />
        </linearGradient>

        {/* Inner Platter Recess Gradient */}
        <linearGradient id="dmg-recess" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#9ca3af" stopOpacity="0.35" />
          <stop offset="25%" stopColor="#d1d5db" stopOpacity="0.2" />
          <stop offset="100%" stopColor="#ffffff" stopOpacity="0.6" />
        </linearGradient>

        {/* Inner Metallic Plate */}
        <linearGradient id="dmg-plate" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#e2e5e9" />
          <stop offset="100%" stopColor="#cbd2d9" />
        </linearGradient>

        {/* LED Glow Filter */}
        <filter id="led-glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="1.5" result="coloredBlur" />
          <feMerge>
            <feMergeNode in="coloredBlur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>

        {/* Cast Shadow Under Chassis */}
        <filter id="dmg-drop-shadow" x="-20%" y="-10%" width="140%" height="140%">
          <feDropShadow dx="0" dy="6" stdDeviation="5" floodColor="#261a12" floodOpacity="0.18" />
        </filter>
      </defs>

      {/* Main Cast Shadow Base */}
      <g filter="url(#dmg-drop-shadow)">
        {/* Drive Outer Aluminum Body */}
        <rect
          x="28"
          y="12"
          width="64"
          height="88"
          rx="14"
          fill="url(#dmg-chassis)"
          stroke="rgba(255, 255, 255, 0.6)"
          strokeWidth="1"
        />

        {/* Edge Bevel Highlight */}
        <rect
          x="28.5"
          y="12.5"
          width="63"
          height="87"
          rx="13.5"
          fill="none"
          stroke="url(#dmg-bevel)"
          strokeWidth="1"
          opacity="0.8"
        />

        {/* Inner Depressed Squircle (Drive Cavity) */}
        <rect
          x="38"
          y="24"
          width="44"
          height="44"
          rx="10"
          fill="url(#dmg-plate)"
          stroke="url(#dmg-recess)"
          strokeWidth="1.5"
        />

        {/* Deep Embossed Inner Platter */}
        <rect
          x="42"
          y="28"
          width="36"
          height="36"
          rx="8"
          fill="none"
          stroke="#9ca3af"
          strokeWidth="1.5"
          strokeOpacity="0.35"
        />

        {/* Subtle Bottom Lip Shadow */}
        <path
          d="M 32 94 Q 60 96 88 94"
          stroke="rgba(0, 0, 0, 0.15)"
          strokeWidth="1"
          strokeLinecap="round"
        />

        {/* Status Activity LED */}
        <circle
          cx="60"
          cy="92"
          r="2"
          fill="#a855f7"
          filter="url(#led-glow)"
        />
        <circle
          cx="60"
          cy="92"
          r="1.2"
          fill="#e9d5ff"
        />
      </g>
    </svg>
  );
}
