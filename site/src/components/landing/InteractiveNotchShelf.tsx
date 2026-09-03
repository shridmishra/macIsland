"use client";

import * as React from "react";
import {
  AudioWave01Icon,
  VolumeHighIcon,
  HeadphonesIcon,
  AppWindowMacIcon,
  Sun01Icon,
} from "@hugeicons/core-free-icons";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Slider } from "@/components/ui/slider";
import { Icon } from "@/components/ui/icon";

export function InteractiveNotchShelf() {
  const [volLevel, setVolLevel] = React.useState([68]);
  const [brightnessLevel, setBrightnessLevel] = React.useState([85]);

  return (
    <section id="hud-lyrics" className="py-20 max-w-5xl mx-auto px-4">
      <div className="text-center max-w-2xl mx-auto mb-12">
        <Badge variant="solidActive" className="mb-4 text-xs font-mono">
          DYNAMIC NOTCH SHELF
        </Badge>
        <h2 className="text-4xl sm:text-5xl font-bold tracking-tight text-foreground">
          Four intelligent modes.{" "}
          <span className="font-apple-serif italic font-normal text-transparent bg-clip-text bg-gradient-to-r from-foreground via-muted-foreground/80 to-foreground">
            Zero screen clutter.
          </span>
        </h2>
        <p className="mt-4 text-muted-foreground text-base sm:text-lg">
          Switch between media control, karaoke lyrics, system level HUDs, and
          source jumping seamlessly.
        </p>
      </div>

      <Tabs defaultValue="lyrics" className="w-full flex flex-col items-center">
        <TabsList className="mb-8">
          <TabsTrigger value="lyrics" className="gap-2">
            <Icon icon={AudioWave01Icon} size={15} />
            <span>Live Lyrics</span>
          </TabsTrigger>
          <TabsTrigger value="hud" className="gap-2">
            <Icon icon={VolumeHighIcon} size={15} />
            <span>Stealth HUD</span>
          </TabsTrigger>
          <TabsTrigger value="sources" className="gap-2">
            <Icon icon={HeadphonesIcon} size={15} />
            <span>Source Jumping</span>
          </TabsTrigger>
        </TabsList>

        {/* TAB 1: LIVE LYRICS */}
        <TabsContent value="lyrics" className="w-full max-w-3xl">
          <Card className="apple-card p-8 flex flex-col items-center text-center">
            <div className="flex items-center gap-2 mb-4">
              <span className="h-2 w-2 rounded-full bg-apple-green animate-ping" />
              <Badge variant="hud">SYNCHRONIZED NOTCH LYRICS</Badge>
            </div>

            <h3 className="text-xl font-semibold text-foreground mb-6">
              Midnight City — M83
            </h3>

            {/* Karaoke Line Progression */}
            <div className="space-y-4 w-full max-w-lg">
              <p className="text-sm text-muted-foreground/50 transition-opacity">
                Waiting in a car, waiting for a ride in the dark
              </p>
              <div className="p-3.5 rounded-xl bg-card-secondary border border-border shadow-md">
                <p className="text-lg sm:text-xl font-apple-serif italic text-foreground tracking-wide">
                  &ldquo;The city is my church, it wraps me in the blinding twilight&rdquo;
                </p>
              </div>
              <p className="text-sm text-muted-foreground/50 transition-opacity">
                The sky is screaming, and the wind is wild
              </p>
            </div>

            <p className="text-xs text-muted-foreground mt-8 font-mono">
              Auto-fetches synced lyrics without requiring Spotify Premium or Apple Music subscriptions.
            </p>
          </Card>
        </TabsContent>

        {/* TAB 2: STEALTH HUD */}
        <TabsContent value="hud" className="w-full max-w-3xl">
          <Card className="apple-card p-8 flex flex-col items-center">
            <div className="flex items-center gap-2 mb-4">
              <Badge variant="hud">NON-DISRUPTIVE SYSTEM HUD</Badge>
            </div>

            <h3 className="text-xl font-semibold text-foreground mb-2 text-center">
              Goodbye massive macOS overlays.
            </h3>
            <p className="text-sm text-muted-foreground text-center mb-8 max-w-md">
              Drag the sliders below to see how volume and display brightness hug
              the bottom perimeter of your notch.
            </p>

            {/* Interactive HUD Sliders inside simulated notch */}
            <div className="w-full max-w-md space-y-6 rounded-2xl bg-card-secondary border border-border p-6">
              {/* Volume Slider */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs font-mono">
                  <span className="flex items-center gap-1.5 text-foreground">
                    <Icon icon={VolumeHighIcon} size={15} className="text-apple-blue" />
                    Output Volume
                  </span>
                  <span className="text-muted-foreground">{volLevel[0]}%</span>
                </div>
                <Slider
                  value={volLevel}
                  max={100}
                  step={1}
                  onValueChange={setVolLevel}
                />
              </div>

              {/* Brightness Slider */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs font-mono">
                  <span className="flex items-center gap-1.5 text-foreground">
                    <Icon icon={Sun01Icon} size={15} className="text-apple-orange" />
                    Display Brightness
                  </span>
                  <span className="text-muted-foreground">{brightnessLevel[0]}%</span>
                </div>
                <Slider
                  value={brightnessLevel}
                  max={100}
                  step={1}
                  onValueChange={setBrightnessLevel}
                />
              </div>
            </div>
          </Card>
        </TabsContent>

        {/* TAB 3: SOURCE JUMPING */}
        <TabsContent value="sources" className="w-full max-w-3xl">
          <Card className="apple-card p-8 flex flex-col items-center text-center">
            <div className="flex items-center gap-2 mb-4">
              <Badge variant="hud">INSTANT CONTEXT SWITCHING</Badge>
            </div>

            <h3 className="text-xl font-semibold text-foreground mb-3">
              One-click Jump to Playing Source
            </h3>
            <p className="text-sm text-muted-foreground max-w-lg mb-8 leading-relaxed">
              Have 40 browser tabs open and can’t find where that YouTube video or
              podcast audio is coming from? Click the badge in Mac Island to
              instantly focus the exact tab in Safari, Chrome, or Brave.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 w-full max-w-lg">
              <div className="p-4 rounded-xl bg-card-secondary border border-border flex flex-col items-center">
                <Icon icon={AppWindowMacIcon} size={24} className="text-apple-blue mb-2" />
                <span className="text-xs font-semibold text-foreground">Safari Tabs</span>
                <span className="text-[10px] text-muted-foreground mt-1">Focus specific tab</span>
              </div>
              <div className="p-4 rounded-xl bg-card-secondary border border-border flex flex-col items-center">
                <Icon icon={HeadphonesIcon} size={24} className="text-apple-green mb-2" />
                <span className="text-xs font-semibold text-foreground">Spotify Desktop</span>
                <span className="text-[10px] text-muted-foreground mt-1">Direct app toggle</span>
              </div>
              <div className="p-4 rounded-xl bg-card-secondary border border-border flex flex-col items-center">
                <Icon icon={AudioWave01Icon} size={24} className="text-apple-purple mb-2" />
                <span className="text-xs font-semibold text-foreground">Apple Music</span>
                <span className="text-[10px] text-muted-foreground mt-1">Library playback</span>
              </div>
            </div>
          </Card>
        </TabsContent>
      </Tabs>
    </section>
  );
}
