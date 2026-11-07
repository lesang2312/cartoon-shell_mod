# Ultra-Clear Liquid Glass — Refraction Update

This build focuses on visible edge refraction rather than merely reducing tint.

## What changed
- `components/GlassBackdrop.qml` now captures extra wallpaper around the card and maps the shader to the centre of that padded texture. This lets the bevel sample real pixels from outside the panel boundary instead of smearing/clamping only within the card.
- The padded capture is enabled only for the custom shader path. `GlassFallback` continues to receive a panel-sized source if customShader is disabled.
- `services/GlassService.qml` uses a 1.62 thickness scale, IOR 1.50, moderate dispersion, a subtle frost, and a slightly stronger bevel for small bar capsules.
- Added a very restrained inner optical rim and made the dashboard PlayerWidget use GlassPanel too.
- The existing QSB shader is not changed; its `srcRect` and `sampleBounds` uniforms are already used by the shader. No shader rebake is required for these QML changes.

## Tuning
- For even stronger edge refraction, try `thicknessScale: 1.8` and `dispersion: 0.065`.
- For low-power GPUs, try `textureScale: 0.60` and `thicknessScale: 1.35`.
- Text, controls, and layout logic are otherwise unchanged.

The project was checked for archive integrity and basic QML delimiter balance in the files edited here. A live Quickshell render test was not available in this build environment.
