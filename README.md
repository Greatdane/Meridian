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

## Notes

Meridian stores preferences locally in `UserDefaults` under the app bundle identifier `local.meridian.app`.
