import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-full text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 select-none cursor-pointer",
  {
    variants: {
      variant: {
        default:
          "bg-primary text-primary-foreground hover:opacity-90 active:scale-[0.98] shadow-sm",
        apple:
          "bg-primary text-primary-foreground hover:opacity-90 active:scale-[0.98] shadow-md border border-border-highlight",
        solid:
          "apple-pill text-foreground hover:bg-surface-hover active:bg-surface-active active:scale-[0.98]",
        glass:
          "apple-pill text-foreground hover:bg-surface-hover active:bg-surface-active active:scale-[0.98]",
        secondary:
          "bg-secondary text-secondary-foreground hover:bg-surface-hover active:scale-[0.98] border border-border-subtle",
        outline:
          "border border-border bg-transparent text-foreground hover:bg-secondary hover:border-border-highlight active:scale-[0.98]",
        ghost:
          "text-muted-foreground hover:text-foreground hover:bg-secondary active:scale-[0.98]",
        notch:
          "bg-notch-surface text-foreground border border-border shadow-xl hover:border-border-highlight active:scale-[0.98]",
        heroBlack:
          "bg-hero-btn-black text-hero-btn-black-text hover:opacity-90 active:scale-[0.98] shadow-2xl border border-border-subtle font-semibold",
        heroWhite:
          "bg-hero-btn-white text-hero-btn-white-text hover:opacity-90 active:scale-[0.98] shadow-md font-semibold text-xs",
        appleWhite:
          "bg-hero-btn-white text-hero-btn-white-text hover:opacity-90 active:scale-[0.98] shadow-sm font-medium text-xs rounded-lg",
      },
      size: {
        default: "h-10 px-5 py-2",
        sm: "h-8 px-3.5 text-xs",
        lg: "h-13 px-8 text-base font-semibold",
        icon: "h-9 w-9 p-0 rounded-full",
        iconSm: "h-7 w-7 p-0 rounded-full",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
