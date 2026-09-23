import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium transition-colors select-none",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground border border-transparent shadow-sm",
        secondary:
          "bg-secondary text-muted-foreground border border-border-subtle",
        solid:
          "apple-pill text-foreground text-xs",
        glass:
          "apple-pill text-foreground text-xs",
        glassActive:
          "apple-pill-active text-foreground font-semibold",
        solidActive:
          "apple-pill-active text-foreground font-semibold",
        outline:
          "border border-border text-muted-foreground bg-transparent",
        appleBlue:
          "bg-accent text-foreground border border-border-highlight",
        hud:
          "bg-card text-foreground border border-border font-mono text-xs",
        appleOrange:
          "bg-apple-orange/15 text-apple-orange border border-apple-orange/30 text-xs font-semibold",
        heroOrange:
          "bg-hero-orange-badge text-hero-orange-text border border-hero-orange-badge-border text-xs font-medium",
        version:
          "border border-border text-muted-foreground bg-surface-elevated/80 text-[11px] px-2 py-0.5 font-mono rounded-md shadow-2xs",
      },
    },
    defaultVariants: {
      variant: "solid",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants };
