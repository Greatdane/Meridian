# Meridian

Meridian is a lightweight macOS menu bar app for tracking world clocks without the bulk of a full calendar or team-scheduling tool.

It is built as a native SwiftUI/AppKit utility. Meridian lives in the menu bar, opens a compact popover, and lets you add cities, choose a local reference timezone, scrub time forward or backward, and copy displayed times quickly.

## Features

- Native macOS menu bar app.
- Add time zones by city, country, region, or `UTC`.
- Add colored tags for people, teams, events, or other reminders.
- Assign multiple tags to each saved time zone.
- Configure a local reference timezone, shown separately at the top.
- Hide or show the local row.
- Show UTC offsets per row.
- Scrub time forward or backward with a slider.
- Slider snaps to real 5-minute clock boundaries.
- 15-minute forward/back controls.
- Copy a displayed time by clicking a row.
- Reorder locations from the popover or settings.
- Sort locations by displayed time, ascending or descending.
- Customize zone names and emoji.
- Manage tag names and colors in Settings.
- Choose menu bar display: icon only or selected zone time.
- Optional selected-zone flag and compact place abbreviation in the menu bar.
- 24-hour or AM/PM time format.
- Small, default, or large display sizing with a live preview.
- Light, dark, or system appearance.
- Optional launch at login.

## Requirements

- macOS 13 or later.
- Apple Silicon is the primary target.
- Xcode Command Line Tools or Xcode with Swift Package Manager support.

## Install

Download the latest release from:

```text
https://github.com/Greatdane/Meridian/releases
```

Unzip `Meridian.app.zip`, move `Meridian.app` to `/Applications` if you want it installed system-wide, and open it. Meridian is currently signed ad hoc for local use, not notarized with an Apple Developer ID, so macOS may ask you to confirm before opening it.

## Basic Usage

Launch Meridian and click the globe icon in the macOS menu bar to open the popover.

- Add a location with the `+` button.
- Open Settings with the gear button.
- Close the app with the `x` button.
- Click a time zone card to copy that displayed time to the clipboard.
- Drag cards in the popover to reorder locations.
- Use the time slider to scrub forward or backward; it snaps to 5-minute clock boundaries.
- Use the 15-minute buttons for quick jumps.

### Local Time

Meridian can show a local reference timezone at the top of the popover. By default this uses your system timezone. In Settings, you can change the local timezone or hide the local row entirely.

### Tags

Use `Settings > Tags` to create colored tags for people, teams, events, or other reminders. Tags can be assigned to multiple time zones, and each time zone can have multiple tags.

### Appearance

Use `Settings > Appearance` to change:

- Light, dark, or system appearance.
- Display size: small, default, or large.
- 24-hour or AM/PM time.
- Menu bar mode: icon or selected zone.
- Optional flag and compact place abbreviation in the menu bar.

## Build

```sh
swift build
swift run MeridianChecks
./scripts/build_app.sh release
```

The packaged app is created at:

```sh
dist/Meridian.app
```

Run it with:

```sh
open -n dist/Meridian.app
```

## Project Structure

```text
Sources/Meridian        AppKit + SwiftUI app target
Sources/MeridianCore    Time-zone catalog, formatting, preferences, helpers
Sources/MeridianChecks  Lightweight executable checks
Resources/Meridian.icns  macOS app icon
packaging/Info.plist    macOS app bundle metadata
scripts/build_app.sh    Local app bundle build script
```

## Development

Common commands:

```sh
make build
make test
make app
make run
```

`MeridianChecks` covers catalog parsing, search, formatting, preference compatibility, time snapping, menu bar defaults, and abbreviation behavior.

Regenerate the app icon after changing `scripts/generate_icon.swift`:

```sh
swift scripts/generate_icon.swift
```

## Notes

Meridian stores preferences locally in `UserDefaults` under the app bundle identifier `local.meridian.app`.
