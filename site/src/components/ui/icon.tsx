import * as React from "react";
import { HugeiconsIcon } from "@hugeicons/react";
import { cn } from "@/lib/utils";

type HugeiconsIconType = React.ComponentProps<typeof HugeiconsIcon>["icon"];

export interface IconProps
  extends Omit<React.ComponentProps<typeof HugeiconsIcon>, "icon"> {
  icon: HugeiconsIconType;
  className?: string;
}

export function Icon({
  icon,
  className,
  size = 18,
  strokeWidth = 1.8,
  ...props
}: IconProps) {
  return (
    <HugeiconsIcon
      icon={icon}
      size={size}
      strokeWidth={strokeWidth}
      className={cn("inline-block shrink-0 transition-colors", className)}
      {...props}
    />
  );
}
