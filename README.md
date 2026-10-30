# MenuClocks

A small native macOS menu bar world clock, inspired by Clocker. Built with SwiftUI and AppKit, with no external dependencies or network access. This is an independent implementation, not Clocker's source or branding.

## Launch

Open `dist/MenuClocks.app`. It lives in the menu bar and does not show a Dock icon. Click its clocks (or globe icon) to open the panel. To install, drag the app to Applications; it can also run from this folder.

The included app was built for Apple Silicon. Rebuild on an Intel Mac to produce an Intel version. Requires macOS 13 or newer; building requires Xcode with Swift 6 or newer.

## Use

- **+** searches macOS's built-in time zone database by city, region, or identifier (e.g. `Tokyo`, `New York`, `Europe`, `UTC`). City search uses time zone database names, not every geographic city.
- **In menu bar** pins a clock. The first two pinned clocks appear in saved order; extra pins become a `+N` count so the title stays compact. Hover the menu bar title for all pinned times.
- **Edit** lets you rename, reorder, or remove clocks. Empty labels fall back to city names.
- **24-hour** switches between 24-hour and AM/PM time.
- **Look ahead** previews up to 24 hours either way, in 30-minute steps. The menu bar always shows live time. Click **Now**, or close/reopen the panel, to return to live time.
- **Copy** copies the displayed times, dates, and UTC offsets, including any preview offset.
- **… → Quit MenuClocks** exits the app.

Clocks, pinning, labels, order, and time format are saved automatically in macOS UserDefaults (`local.menuclocks.app`). Day offsets are relative to the Mac's system time zone at the viewed instant. Sun/moon symbols indicate 07:00–18:59 / 19:00–06:59 local time, not astronomical sunrise or sunset. Times refresh every five seconds while the Mac is awake.

To start automatically, add the app in **System Settings → General → Login Items**.

## Build and test

```sh
./scripts/build.sh
swift test
open dist/MenuClocks.app
```

The build script produces an optimized, locally ad-hoc-signed app. It is not notarized for distribution. The automated tests cover time formatting, DST transitions, date-line/year boundaries, fractional UTC offsets, search, custom-label fallback, and menu bar overflow.

## Scope

Included: offline world clocks, menu bar pinning, custom labels, ordering, date/UTC offsets, time preview, clipboard copy, saved preferences, and system light/dark appearance.

Not included: calendar integrations, reminders, geographic street search, widgets, or Clocker's other advanced features.
