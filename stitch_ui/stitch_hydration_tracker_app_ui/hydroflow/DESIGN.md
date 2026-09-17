---
name: HydroFlow
colors:
  surface: '#faf9fe'
  surface-dim: '#dad9df'
  surface-bright: '#faf9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f8'
  surface-container: '#eeedf3'
  surface-container-high: '#e9e7ed'
  surface-container-highest: '#e3e2e7'
  on-surface: '#1a1b1f'
  on-surface-variant: '#414755'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f1f0f5'
  outline: '#717786'
  outline-variant: '#c1c6d7'
  surface-tint: '#005bc1'
  primary: '#0058bc'
  on-primary: '#ffffff'
  primary-container: '#0070eb'
  on-primary-container: '#fefcff'
  inverse-primary: '#adc6ff'
  secondary: '#006a65'
  on-secondary: '#ffffff'
  secondary-container: '#5df6ec'
  on-secondary-container: '#006f69'
  tertiary: '#4c4aca'
  on-tertiary: '#ffffff'
  tertiary-container: '#6664e4'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004493'
  secondary-fixed: '#61f9ef'
  secondary-fixed-dim: '#39dcd2'
  on-secondary-fixed: '#00201e'
  on-secondary-fixed-variant: '#00504c'
  tertiary-fixed: '#e2dfff'
  tertiary-fixed-dim: '#c2c1ff'
  on-tertiary-fixed: '#0c006a'
  on-tertiary-fixed-variant: '#3631b4'
  background: '#faf9fe'
  on-background: '#1a1b1f'
  surface-variant: '#e3e2e7'
typography:
  display-hero:
    fontFamily: Manrope
    fontSize: 56px
    fontWeight: '800'
    lineHeight: 64px
    letterSpacing: -0.02em
  display-hero-mobile:
    fontFamily: Manrope
    fontSize: 44px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-large:
    fontFamily: Manrope
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 41px
    letterSpacing: -0.015em
  headline-large-mobile:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-medium:
    fontFamily: Manrope
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-small:
    fontFamily: Manrope
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-large:
    fontFamily: Manrope
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-medium:
    fontFamily: Manrope
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-bold:
    fontFamily: Manrope
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0em
  label-subheadline:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-caption:
    fontFamily: Manrope
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 13px
    letterSpacing: 0.02em
  numeric-stat:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies the crystalline clarity, serenity, and functional elegance of modern iOS utility experiences. Inspired by iOS 17 Human Interface Guidelines and Apple Health’s clean data presentations, the system elevates hydration tracking into an ambient, refreshing daily ritual.

### Aesthetic Tone & Identity
- **Personality:** Pristine, encouraging, rhythmic, and effortless. It avoids punitive alert mechanics in favor of refreshing nudges and crisp visual rewards.
- **Visual Language:** A hybrid of Apple’s iOS 17 vibrant translucency (Material Thin & Ultra-Thin blurs) and clean, clinical minimalism. The visual environment mimics calm, illuminated aquatic depths, utilizing pure whites, cool cerulean gradients, soft glass sheens, and smooth squircle geometry.
- **Target Audience:** Health-conscious professionals, athletes, and wellness seekers who appreciate disciplined, native-feeling software tailored precisely to the iOS paradigm.
- **Emotional Response:** Tranquil focus, a sense of biological renewal, physical lightness, and effortless control over hydration goals.

## Colors

The palette is tuned around aquatic chromaticity, balanced against neutral backgrounds to ensure accessibility and compliance with native iOS light mode hierarchy.

### Core Color Roles
- **Primary (`#007AFF` - iOS Azure Blue):** The dominant active brand tone. Used for interactive controls, dynamic liquid volume fills, key tracking toggles, and forward navigation paths.
- **Secondary (`#00C7BE` - Refreshing Aqua Cyan):** Used for micro-achievements, target completion badges, optimal intake indicators, and ambient hydration highlights.
- **Tertiary (`#5856D6` - Deep Indigo / Soft Violet):** Evokes deep water resonance; drives secondary charts, evening reminder tags, caffeine/electrolyte counterbalances, and gradient terminal stops.
- **Neutral (`#8E8E93` - iOS System Secondary Label):** Governs structural hierarchy, timestamps, inactive states, and assistive meta-captions.

### Functional Canvas & Surface Palette
- **System Canvas (Default Background):** `#F2F2F7` (iOS Grouped Background).
- **Secondary Canvas (Grouped Table Container):** `#FFFFFF` with `92%` opacity or full opacity with inset padding.
- **Glass Card Fill (Light Material):** `rgba(255, 255, 255, 0.72)` combined with backdrop saturation filters.
- **Hairline Dividers:** `rgba(60, 60, 67, 0.12)`.
- **Text & Glyph Hierarchy:**
  - *Primary Label:* `#000000` (or `rgba(0, 0, 0, 0.88)`).
  - *Secondary Label:* `rgba(60, 60, 67, 0.60)`.
  - *Tertiary Label:* `rgba(60, 60, 67, 0.30)`.

## Typography

Manrope delivers a clean geometric balance that mirrors the functional proportions and optical legibility of Apple’s SF Pro. Its alternate stylistic sets provide numerical clarity for tracking milliliter and fluid-ounce counts.

### Usage Standards
- **Large Titles (`headline-large`):** Reserved for native top navigation titles, screen headers, and prominent intake summary panels.
- **Metric Displays (`display-hero`, `numeric-stat`):** Tabular figures must be enabled via font-variant features (`tnum`) to keep rapidly updating hydration logs aligned and vibration-free during progress wheel fills.
- **Subheadlines & Captions (`label-subheadline`, `label-caption`):** Rendered in secondary label values or tertiary colors to reinforce the native Apple HIG hierarchy.

## Layout & Spacing

Layout conforms strictly to the iOS 17 Inset Grouped Table philosophy. Screens feature full-bleed ambient canvas backgrounds with inset cards and stacked modules that scale responsively.

### Structural Parameters
- **Screen Padding:** Fixed `16px` (`margin`) outer gutter for phone form factors, expanding to `24px` on tablet layouts.
- **Safe Area Insets:** Layouts respect dynamic system islands, top status bars (`44px`–`54px`), and the bottom Home Indicator bar (`34px`).
- **Component Stacking:** Vertical stacks follow a baseline rhythm of `8px` (`space-sm`), `16px` (`space-md`), and `20px` (`space-lg`) between logical functional sections.
- **Grouped List Insets:** Internal cells feature `16px` horizontal padding with `11px` to `14px` vertical padding, maintaining native iOS touch-target expectations (minimum `44x44pt`).

## Elevation & Depth

This design system minimizes physical dropped shadows in favor of dynamic translucency, optical refraction, and luminous backdrop filters (iOS Material System).

### Elevation Tiers
- **Base Tier (Ground):** `#F2F2F7` matte canvas. Represents the infinite bed over which content cards hover.
- **Tier 1 (Inset Grouped Cards):** Solid `#FFFFFF` or translucent `rgba(255, 255, 255, 0.85)` with `backdrop-filter: blur(20px) saturate(180%)`. Bordered by a `0.5px` inner stroke of `rgba(0, 0, 0, 0.04)`.
- **Tier 2 (Floating Action Triggers & Modals):** Surface fill `rgba(255, 255, 255, 0.92)` with `backdrop-filter: blur(30px)`. Elevation is supported by a diffuse ambient shadow: `box-shadow: 0 8px 32px -4px rgba(0, 122, 255, 0.08), 0 2px 8px -2px rgba(0, 0, 0, 0.04)`.
- **Liquid Depth (Hydration Gauge):** Inner glow layered through radial gradients: `radial-gradient(circle at 50% 10%, rgba(0, 199, 190, 0.35), transparent 70%)` overlapping an azure blue base fill, simulating volumetric water within glass vessels.

## Shapes

Shapes utilize Apple’s continuous corner curvature (super-ellipses/squircles) to avoid the abrupt inflection points of standard geometric radii.

### Curvature Tokens
- **Micro Elements (Chips, Badges):** `8px` corner radius.
- **Standard Controls (Inputs, Quick-Add Buttons):** `12px` to `14px` corner radius.
- **Grouped Table Cards & Modules:** `16px` to `20px` continuous corner radius (`rounded-2xl`).
- **Hydration Vessels & Progress Rings:** Concentric continuous rounding with fully pill-shaped terminations (`rounded-full`) for quick log actions.

## Components

### 1. Buttons & Quick-Add Quick Actions
- **Primary Log Button:** Capsule shape (`height: 52px`), filled with an azure-to-cyan gradient (`linear-gradient(135deg, #007AFF 0%, #00C7BE 100%)`). White bold label with an integrated droplet icon. On press, scales to `0.97` with a subtle haptic feedback visual state.
- **Quick-Add Volumetric Chips (e.g., +250ml, +500ml):** Frosted glass surface (`rgba(255, 255, 255, 0.7)`), `12px` squircle, azure border (`0.5px` solid `rgba(0, 122, 255, 0.2)`), displaying an SF-style droplet and volume amount in `headline-small`.

### 2. Hydration Progress Ring & Cylinder
- **Ring Tracker:** Double-ring configuration. The outer background track is `rgba(0, 122, 255, 0.12)`. The active track features a gradient stroke (`#007AFF` transitioning into `#00C7BE`) with smooth rounded caps. Center displays `numeric-stat` current intake with secondary label target goals.
- **Wave Tank Visual (Alternative View):** Smooth SVG sine wave animation clip-path inside an inset grouped card, dynamically filling up as fluid intake is logged.

### 3. Inset Grouped Lists & Metric Rows
- Apple Health-style table presentation with inset margins. Rows inside the same card are separated by an inset divider (`margin-left: 54px`, `height: 0.5px`, color: `rgba(60, 60, 67, 0.12)`).
- Left-hand anchor: SF-style glyph inside a squircle tile (`32x32px`, tinted background: `rgba(0, 122, 255, 0.12)`, icon color: `#007AFF`).
- Right-hand accessory: Secondary label with numerical data, accompanied by a subtle trailing chevron.

### 4. Chips, Badges & Toggles
- **Hydration Type Filter:** Horizontally scrolling segmented pill row (`Water`, `Electrolytes`, `Tea`, `Coffee`). Active item is solid `#007AFF` with white text; inactive items are soft neutral fills (`rgba(118, 118, 128, 0.12)`).
- **iOS Native Switch:** Toggle for reminder automation (`Smart Reminders`). Green-blue active tint (`#34C759` or `#007AFF`), white circular thumb with crisp native drop shadow.

### 5. Input Fields & Log Adjusters
- Stepper input with frosted glass backing. Minus and plus symbols rendered in iOS azure tint with continuous hold-to-accelerate interaction patterns. Numeric readout centered in tabular bold font.