# Visual Design & Implementation Plan: "Rushing Wind" Theme

This document provides a detailed visual design analysis and a step-by-step technical implementation guide to realize the high-impact **Rushing Wind (Sage Green & Warm Alabaster)** theme.

---

## 1. High-Fidelity Visual Design Mockup

Below is the high-fidelity design mockup showing the powdery textures, neumorphic clay boards, organic shadows, and chalk-drawn markers in action:

![Rushing Wind Theme Visual Design Mockup](file:///C:/Users/Keepy/.gemini/antigravity/brain/1b9ffb56-5102-4907-ba68-d71219602919/rushing_wind_mockup_1780082523159.png)

---

## 2. Visual Style & Aesthetic Specifications

| Component | Visual Description | Color Palette | Technical Implementation |
| :--- | :--- | :--- | :--- |
| **Background Imagery** | Soft, serene bamboo leaf outlines swaying gently under quiet, calm river waves. | Green-Cream HSL Wave Gradients: `0xFFFAF9F6` $\rightarrow$ `0xFFEAEAE4` | Two slow-shifting sine-wave paths inside a CustomPainter, animated with a lightweight `AnimationController`. |
| **Board Material** | Soft, powdery warm alabaster clay. Looks tactile, inviting, and rounded with soft shadows. | Base: `0xFFEAEAE4`. Light Shadow: `0xFFFFFDF5` (90%). Dark Shadow: `0xFFDCDCD4` (16%) | BackdropFilter blur (sigma: 8) + double-layered offset neumorphic `BoxShadow` offsets. |
| **Chalk 'X' Marker** | Hand-drawn sage green chalk signature with a soft outer powder halo. | Main: `0xFF70806A` (85%). Glow: `0xFF70806A` (18%) | Multi-layered CustomPainter stroke with a blurred shadow pass (sigma: 0.6) and high-light core. |
| **Chalk 'O' Marker** | Hand-drawn sandy ochre chalk signature with a soft outer powder halo. | Main: `0xFFBAA38A` (85%). Glow: `0xFFBAA38A` (18%) | Multi-layered CustomPainter stroke with a blurred shadow pass and high-light core. |

---

## 3. Step-by-Step Technical Implementation Plan

To give the player a powerful sensory impact and delightful tactile sensations during gameplay, follow this three-phase plan:

### Phase A: Background Water Ripples & Leaf Sway
1. **Background Wave Color Sync:**
   Modify `lib/widgets/animated_vibrant_background.dart` to automatically extract `theme.scaffoldBg` and `theme.boardBg` when Rushing Wind is active.
2. **Organic Wave Slowness:**
   Ensure wave transitions are slow ($8$-$12$ seconds per loop) to mimic a calm lake.
3. **Bamboo Leaf Sway Overlay:**
   Draw a subtle, semi-transparent bamboo branch overlay in the background corners that rotates slightly ($0.02$ radians) using a desynchronized leaf-float sine animation.

### Phase B: Tactile Neumorphic Clay Board Material
1. **Multi-Layered Shadow Depth:**
   In `lib/widgets/board_widget.dart` and `NeumorphicCell`, calculate shadows using the custom HSL lighter/darker offsets.
2. **Backdrop Blur:**
   Keep the `BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8))` on the board cards to let the background ripples softly diffuse through the translucent alabaster board.
3. **Inner Bevel Sheen:**
   Draw a very thin ($1$px) inner border of a lighter, creamy white color along the top-left edges of the sub-boards to simulate light catching the clay corner.

### Phase C: Chalk Drawing Animations (X & O)
1. **Accelerated Brush Stroke (Chalk Drawing Effect):**
   In `MarkerPainter` (inside `board_widget.dart`), animate the drawing of X and O using a custom curve:
   - For X: Draw the first stroke from top-left to bottom-right, then pause slightly, and draw the second cross stroke.
   - For O: Draw the circle with a variable drawing speed (accelerating slightly toward the bottom and decelerating as it seals the loop).
2. **Powdery Halo (Glow Pass):**
   Double-draw the chalk path:
   - First pass: A wide, thick stroke (width: $14$px) drawn with `Paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0)` and low opacity ($18\%$) to render the dusty chalk powder halo left behind by the chalk.
   - Second pass: The solid core stroke (width: $7$px) with $85\%$ opacity representing the main chalk filament.
   - Third pass: A very thin, bright white center line ($1.5$px) representing the highest pressure point of the hand-drawn chalk.

---

## 4. Sensory Polish & Tactile Feedback
- **Soft Audio Signature:** Tap sound triggers a low-frequency, soft powdery "tink" sound (simulating a soft pebble hitting dry clay).
- **Light Haptics:** Tap triggers `HapticFeedback.lightImpact()` to mimic the physical sensation of the chalk hitting the alabaster surface.
