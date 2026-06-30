# Meridian Agent Guide

## Technical Summary

Meridian is a native macOS menu bar application for tracking world clocks. It is built with Swift Package Manager, SwiftUI, and AppKit. The app runs as an `LSUIElement` accessory app, places a configurable status item in the macOS menu bar, and opens an `NSPopover` containing local time, saved time zones, a 5-minute snapping time scrubber, and quick actions.

The core product goal is a small, fast, low-friction alternative to heavier world-clock apps. Meridian should feel like a native macOS utility: quiet visuals, compact controls, predictable settings, and no unnecessary onboarding or marketing surfaces.

## Architecture

- `Sources/Meridian`: AppKit and SwiftUI app target. Owns the menu bar status item, popover UI, settings window, state model, and launch-at-login integration.
- `Sources/MeridianCore`: Pure Foundation domain code for time-zone entries, catalog loading/search, preference payloads, display formatting, UTC offsets, and name abbreviation.
- `Sources/MeridianChecks`: Lightweight executable checks used as the project test suite.
- `packaging/Info.plist`: App bundle metadata for the packaged `.app`.
- `scripts/build_app.sh`: Builds the Swift package executable, creates `dist/Meridian.app`, copies the `Info.plist`, and signs ad hoc for local use.

## Build And Test

```sh
swift build
swift run MeridianChecks
./scripts/build_app.sh release
open -n dist/Meridian.app
```

`make build`, `make test`, `make app`, and `make run` wrap the same commands.

## Implementation Notes

- Keep preferences backward compatible by using optional decode defaults in `ZonePreferencesPayload`.
- Keep reusable date/time behavior in `MeridianCore` where it can be checked by `MeridianChecks`.
- Menu bar icon mode should default to the globe icon on fresh install.
- Slider movement should snap displayed local time to real 5-minute clock boundaries.
- Manual drag ordering should remain available; time sorting is a convenience mode and can be toggled.
- Use SF Symbols/template images for menu bar icons so macOS handles tinting correctly.

## UI Guidelines

- Favor native macOS controls and restrained styling.
- Keep the popover compact and scannable.
- Avoid decorative layout, marketing copy, and oversized controls.
- Settings should be clear, centered, and utility-like.
- If an icon performs a destructive or app-level action, make its purpose visible through hover state, help text, and accessibility labels.
