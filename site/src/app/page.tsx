import { Navbar } from "@/components/landing/Navbar";
import { HeroSection } from "@/components/landing/HeroSection";
import { ShelfShowcase } from "@/components/landing/ShelfShowcase";
import { FeatureDeepDives } from "@/components/landing/FeatureDeepDives";
import { PersonaSection } from "@/components/landing/PersonaSection";
import { PricingSection } from "@/components/landing/PricingSection";
import { FAQSection } from "@/components/landing/FAQSection";
import { BottomCtaBanner } from "@/components/landing/BottomCtaBanner";
import { Footer } from "@/components/landing/Footer";

export default function Home() {
  return (
    <main className="min-h-screen bg-background text-foreground flex flex-col selection:bg-accent selection:text-accent-foreground">
      {/* 1. Top-Anchored Black Notch Navigation */}
      <Navbar />

      {/* 2. Light Pastel Pink Hero with Desktop Notch Shelf Mockup */}
      <HeroSection />

      {/* 3. Dynamic Island Anywhere Ribbon & Chips */}
      <ShelfShowcase />

      {/* 4. Deep-Dive Feature Showcases & Community Testimonials */}
      <FeatureDeepDives />

      {/* 5. Built for Everything You Listen To (6 Persona Cards) */}
      <PersonaSection />

      {/* 6. 100% Free & Open Source Section */}
      <PricingSection />

      {/* 7. Frequently Asked Questions */}
      <FAQSection />

      {/* 8. Bottom CTA Banner with Mini Screen Preview */}
      <BottomCtaBanner />

      {/* 9. Black Apple Footer with Giant Watermark */}
      <Footer />
    </main>
  );
}
