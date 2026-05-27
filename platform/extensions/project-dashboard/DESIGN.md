---
name: Fluent Professional
colors:
  surface: '#faf9f8'
  surface-dim: '#dadad9'
  surface-bright: '#faf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f2'
  surface-container: '#efeeed'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e3e2e1'
  on-surface: '#1a1c1c'
  on-surface-variant: '#424752'
  inverse-surface: '#2f3130'
  inverse-on-surface: '#f1f0ef'
  outline: '#727783'
  outline-variant: '#c2c6d4'
  surface-tint: '#005db5'
  primary: '#00488d'
  on-primary: '#ffffff'
  primary-container: '#005fb8'
  on-primary-container: '#cadcff'
  inverse-primary: '#a8c8ff'
  secondary: '#605e5c'
  on-secondary: '#ffffff'
  secondary-container: '#e6e2df'
  on-secondary-container: '#666462'
  tertiary: '#004985'
  on-tertiary: '#ffffff'
  tertiary-container: '#0061ad'
  on-tertiary-container: '#c6dcff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#a8c8ff'
  on-primary-fixed: '#001b3d'
  on-primary-fixed-variant: '#00468b'
  secondary-fixed: '#e6e2df'
  secondary-fixed-dim: '#c9c6c3'
  on-secondary-fixed: '#1c1b1a'
  on-secondary-fixed-variant: '#484645'
  tertiary-fixed: '#d3e3ff'
  tertiary-fixed-dim: '#a3c9ff'
  on-tertiary-fixed: '#001c39'
  on-tertiary-fixed-variant: '#004883'
  background: '#faf9f8'
  on-background: '#1a1c1c'
  surface-variant: '#e3e2e1'
typography:
  display:
    fontFamily: Inter
    fontSize: 44px
    fontWeight: '600'
    lineHeight: 52px
    letterSpacing: -0.02em
  h1:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  h2:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  h3:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  caption:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-page: 40px
---

## Brand & Style
The design system is rooted in the principles of reliability, clarity, and precision. It targets enterprise environments where high density and cognitive ease are paramount. By leveraging a **Corporate / Modern** aesthetic, the system avoids visual noise, focusing instead on content hierarchy and functional efficiency. The emotional response is one of calm authority—a workspace that feels invisible yet highly supportive of complex workflows.

## Colors
The palette is intentionally restrained to maintain a discrete professional profile. 
- **Primary Blue:** A deep, accessible blue used exclusively for primary actions and indicative states. 
- **Neutrals:** A sophisticated range of cool grays that define structure without creating harsh boundaries. 
- **Backgrounds:** Pure white is used for the primary canvas, while subtle grays distinguish sidebar navigation and utility panels. 
- **Semantic Colors:** Success, Warning, and Error states utilize standard Microsoft-aligned hues but are applied with low saturation to ensure they do not disrupt the overall neutral harmony.

## Typography
This design system utilizes **Inter** as a highly functional proxy for Segoe UI, ensuring cross-platform legibility and a systematic feel. 
- **Weight Strategy:** Bold weights are reserved for high-level headers (H1-H3). Regular weights are used for the vast majority of interface text to maintain a light, airy feel.
- **Scale:** A tight typographic scale is employed to handle high-density data views commonly found in corporate software.
- **Color:** Body text uses a soft black (#323130) rather than pure black to reduce eye strain during prolonged use.

## Layout & Spacing
The layout follows a **Fluid Grid** model with a base-4 increment system. 
- **Structure:** Content is organized into a 12-column grid for web views. Sidebars are typically fixed-width (240px or 280px) to provide a stable anchor for navigation.
- **Density:** Spacing is compact but purposeful. Use `16px` (md) for standard padding between logical groups and `8px` (sm) for internal element spacing within components.
- **Alignment:** All elements must align to the pixel grid to maintain the crispness expected of a Microsoft-inspired interface.

## Elevation & Depth
Depth is communicated through **Tonal Layers** and extremely subtle **Ambient Shadows**. 
- **Layering:** The primary background sits at the lowest level. Content containers (Cards) use white backgrounds with a subtle 1px border (#EDEBE9).
- **Shadows:** Avoid heavy dropshadows. Use a "Soft Diffused" style for floating elements like menus and modals (e.g., `0px 4px 12px rgba(0,0,0,0.08)`).
- **Interactivity:** Elements do not lift on hover; instead, they transition through subtle background color shifts (e.g., white to #F3F2F1) to indicate clickability without disrupting the flat plane of the UI.

## Shapes
The design system employs **Soft** roundedness. 
- **Standard Radius:** 4px (0.25rem) is the default for buttons, input fields, and small components. 
- **Container Radius:** Larger components like cards or modals may use 8px (0.5rem) to soften the perimeter, but never exceed this to maintain the professional, structured look.
- **Logic:** Sharp corners are avoided to feel modern, but high-radius "pills" are avoided to maintain a serious, data-driven tone.

## Components
- **Buttons:** Primary buttons use a solid blue background with white text. Secondary buttons use a transparent background with a 1px gray border. High-density buttons use 12px horizontal padding and 14px text.
- **Input Fields:** Use a subtle 1px bottom border or a full ghost border in #D2D0CE. On focus, the border thickens to 2px and changes to the primary blue.
- **Cards:** White fill, 1px border (#EDEBE9), and 4px corner radius. No shadow unless the card is draggable or floating.
- **Lists:** High-density list items (32px or 40px height) with subtle hover states (#F3F2F1). Use "Segoe MDL2 Assets" or similar wireframe-style icons.
- **Data Grids:** Alternating row stripes are not required; use subtle horizontal dividers (#F3F2F1) to maintain a clean aesthetic.
- **Navigation:** Vertical navigation uses a subtle gray background (#FAF9F8) to differentiate the app structure from the workspace content.