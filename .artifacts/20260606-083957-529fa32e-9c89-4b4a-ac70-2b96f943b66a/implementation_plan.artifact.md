# Implementation Plan - Theme Naturalization & Texture Realism

Transform the app into a grounded physical experience by removing all digital neon, glows, and "glassy" effects. Implement high-fidelity natural textures for wood, bamboo, and stone.

## Proposed Changes

### 1. Global Refinements (All Themes)
#### [app_theme.dart](file:///M:/techprojects/ultimate_tictactoe-V2/lib/core/theme/app_theme.dart)
- **Zero-Neon Shift**: Further reduce saturation and brightness of `mainColor` and `accentGlow` to remove any remaining "neon" feel.
- **Matte Lighting**: Adjust `NeumorphicColors` to use matte, material-matched highlights (limestone, dried wood, terracotta) instead of white digital glares.

### 2. Physical Texture Realism
#### [clay_bevel_painter.dart](file:///M:/techprojects/ultimate_tictactoe-V2/lib/widgets/board/clay_bevel_painter.dart)
- **Jungle (Rough Wood)**: Implement a deep-etched "Rough Mahogany" texture with dark walnut knots, grain fractures, and matte shading using complex `Path` and `Paint` layers.
- **Pacific (Bamboo Raft)**:
    - **Rough Bamboo**: Redesign bamboo poles with "dried" matte textures, rough splintered nodes, and realistic depth.
    - **Water Lapping**: Implement an occasional "water lapping" animation on the sides of the bamboo raft using low-opacity wave paths synced to the game's pulse.
- **Ambient Occlusion**: Deepen contact shadows where markers land and where boards meet the background to ground them physically.

### 3. Glow & Effect Removal
#### [features/game/widgets/floating_cloud_button.dart](file:///M:/techprojects/ultimate_tictactoe-V2/lib/features/game/widgets/floating_cloud_button.dart)
- **Remove Digital Glass**: Disable `BackdropFilter` and "frosted glass" effects. Switch to solid matte material buttons (wood for Jungle, stone for Cloud).

#### [widgets/board/neumorphic_cell.dart](file:///M:/techprojects/ultimate_tictactoe-V2/lib/widgets/board/neumorphic_cell.dart)
- **Remove Neon Indicators**: Delete the "Pulse neon ring overlay" and high-contrast "AnticipationHalo". Replace with subtle physical debossing or matte markers.

#### [widgets/board/marker_drawings.dart](file:///M:/techprojects/ultimate_tictactoe-V2/lib/widgets/board/marker_drawings.dart)
- **Material Markers**: Shift Starfish/Clamshell and Chalk drawings to use matte, organic colors instead of glowing shaders.

## Verification Plan

### Automated Tests
- `flutter analyze` to ensure zero syntax errors.

### Manual Verification
- **Jungle Audit**: Verify the board looks like "Rough Wood" with visible grain and knots, not a smooth digital surface.
- **Pacific Audit**: Confirm the bamboo raft looks hand-tied and verify the "Water Lapping" effect on the edges.
- **Eye Strain Test**: Ensure all themes are comfortable in low light with zero neon glare.

## Verification Plan

### Automated Tests
- `flutter analyze` to ensure zero syntax errors in new painter logic.

### Manual Verification
- **Audit Mode**: Cycle through all 6 themes. Confirm zero "cloudy" or "powdery" halos around boards.
- **Brightness Test**: Verify the app is comfortable to look at in low-light environments (no eye strain from neon).
- **Texture Check**: Zoom in on the bamboo/mahogany/stone boards to ensure textures look like real-world materials.
