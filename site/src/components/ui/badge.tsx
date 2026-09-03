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
          "bg-card text-foreground border border-border font-mono text-[11px]",
        heroPink:
          "bg-hero-pink-badge text-hero-pink-text border border-hero-pink-badge-border text-xs font-medium",
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
