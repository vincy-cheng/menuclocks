# MenuClocks

A small native macOS menu bar world clock, inspired by Clocker. Built with SwiftUI and AppKit, with no external dependencies or network access. This is an independent implementation, not Clocker's source or branding.

## Build and launch

Requires macOS 13 or newer and Xcode with Swift 6 or newer. Clone the source and build the app locally:

```sh
git clone https://github.com/vincy-cheng/menuclocks.git
cd menuclocks
./scripts/build.sh
open dist/MenuClocks.app
```

If you already have the source (including through the `useless-gadgets` submodule), run the last two commands from the MenuClocks folder.

The build produces an app for your Mac's architecture. Build outputs are not included in the repository. The app lives in the menu bar and does not show a Dock icon. Click its clocks (or globe icon) to open the panel. To install, drag `dist/MenuClocks.app` to Applications; it can also run from the build folder.

The app is locally ad-hoc signed and is not notarized for distribution.

## Use

- **+** searches macOS's built-in time zone database by city, region, or identifier (e.g. `Tokyo`, `New York`, `Europe`, `UTC`). City search uses time zone database names, not every geographic city.
- **In menu bar** pins a clock. The first two pinned clocks appear in saved order; extra pins become a `+N` count so the title stays compact. Hover the menu bar title for all pinned times.
- **Edit** lets you rename, reorder, or remove clocks. Empty labels fall back to city names.
- **Edit → Menu bar name** offers full name, time zone abbreviation, or custom short name. Hong Kong and Japan use HKT and JST. Abbreviations follow daylight saving time; blank short names fall back to the full name. List names and copied times keep the full name.
- **24-hour** switches between 24-hour and AM/PM time.
- **Look ahead** previews up to 24 hours either way, in 30-minute steps. The menu bar always shows live time. Click **Now**, or close/reopen the panel, to return to live time.
- **Copy** copies the displayed times, dates, and UTC offsets, including any preview offset.
- **… → Two-line menu bar** places each clock’s name above its time, with clocks side by side. It works with all name modes; single-line display remains the default.
- **Right-click the menu bar icon → Quit MenuClocks** exits the app. Control-click also opens this menu; left-click toggles the clock panel.

Clocks, pinning, labels, menu bar name modes, short names, layout, order, and time format are saved automatically in macOS UserDefaults (`local.menuclocks.app`). Day offsets are relative to the Mac's system time zone at the viewed instant. Sun/moon symbols indicate 07:00–18:59 / 19:00–06:59 local time, not astronomical sunrise or sunset. Times refresh every five seconds while the Mac is awake.

To start automatically, add the app in **System Settings → General → Login Items**.

## Test

```sh
swift test
```

The automated tests cover time formatting, DST transitions, date-line/year boundaries, fractional UTC offsets, search, custom-label and short-name fallback, menu bar name modes, backward-compatible clock decoding, shared single/two-line menu bar content and overflow, outside-click monitor lifecycle, and Quit menu construction.

## Scope

Included: offline world clocks, menu bar pinning, custom labels, ordering, date/UTC offsets, time preview, clipboard copy, saved preferences, and system light/dark appearance.

Not included: calendar integrations, reminders, geographic street search, widgets, or Clocker's other advanced features.

## License

[MIT](LICENSE)
