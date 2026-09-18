# MyPri

A native priority tracker for macOS and iOS. On the Mac it's a slim panel
that docks to one side of your secondary display; on iPhone it's the same
interface, backed by the same JSON file synced through Google Drive (or
any Files-integrated location). Shared UI, models, and persistence logic
live in the `MyPriKit` Swift package so both apps stay in lockstep.

- `Sources/MyPriKit` — cross-platform: models, theme, SwiftUI views, and
  the `PriorityStore`.
- `Sources/MyPri` — macOS app (AppKit window management, NSSavePanel-based
  file picking).
- `iOSApp/` — iOS app (Xcode project, generated via `xcodegen`).

## One-time setup

Xcode's license needs to be accepted once before Swift will build anything
on this machine:

```bash
sudo xcodebuild -license
```

## Build & run

```bash
Scripts/build_app.sh
open dist/MyPri.app
```

This compiles the Swift package in release mode, assembles `dist/MyPri.app`
with the icon and Info.plist, and ad-hoc code-signs it. Drag `dist/MyPri.app`
to `/Applications` to install it permanently.

For quick iteration while developing:

```bash
swift run
```

## Using the app

- **Window**: starts full-height on your secondary display at ~20% of its
  width, docked to the right edge. Drag any edge to resize; use
  **Window → Dock Left / Dock Right** to flip sides, or **Reset Size &
  Position** to restore the default.
- **Add a priority**: click the `+` in the header, or **File → New Priority**
  (⌘N).
- **Priority level**: 1 (critical) – 3 (normal), set from a row's context
  menu or inside its detail window.
- **Details window**: click a row to open it in its own window. Title,
  assignees, notes, and links all autosave as you type. Press **Esc** to
  save and close.
- **People**: type a name under "Assigned To" and press Return; a priority
  can have multiple people tagged.
- **Links**: add a title + URL as reference links; click to open in your
  browser.
- **Data file**: stored as JSON, by default at
  `~/Library/Application Support/MyPri/priorities.json`. Use
  **File → Choose Data File Location…** to move it anywhere (e.g. a synced
  folder), or **Reveal Data File in Finder** to find it.

## Regenerating the app icon

The icon (a Sword of Damocles — a blade hanging by a thread, matching the
theme of ever-present priorities) is generated procedurally:

```bash
python3 -m venv /tmp/iconenv && /tmp/iconenv/bin/pip install Pillow
/tmp/iconenv/bin/python Scripts/generate_icon.py
Scripts/build_iconset.sh
```

This regenerates `Resources/icon_master_1024.png` (macOS, rounded) and
`Resources/icon_ios_1024.png` (iOS, square) and rebuilds
`Resources/AppIcon.icns`. Re-run `Scripts/build_app.sh` afterward to pick up
the new icon; for iOS, re-copy `icon_ios_1024.png` into
`iOSApp/MyPriMobile/Assets.xcassets/AppIcon.appiconset/icon_1024.png`.

## iOS app

The iOS project is generated from `iOSApp/project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`),
so the `.xcodeproj` itself isn't checked in:

```bash
cd iOSApp
xcodegen generate
open MyPriMobile.xcodeproj   # or build via xcodebuild for Simulator
```

It depends on the local `MyPriKit` package (`packages: MyPriKit: path: ../`
in `project.yml`), so any change to shared views/models/theme is picked up
automatically.

**Connecting to Google Drive**: on first launch the app shows a connect
screen with two options — "Choose Existing File" or "Create New File…".
Both open the standard iOS Files picker. If the Google Drive app is
installed and signed in, "Google Drive" appears there as a location
alongside iCloud Drive and On My iPhone — no sign-in or API setup needed
inside MyPri itself, since the Files picker handles authentication and file
access through Google's own Files integration. Pick (or create)
`priorities.json` inside your Drive, and the app reads/writes it in place
via `NSFileCoordinator`, the same way as Mac's "Choose Data File
Location…" pointed at the same Drive-synced folder — so a change on one
device shows up on the other once Drive syncs.

A security-scoped bookmark is stored locally so the app reconnects to the
same file automatically on future launches. Use the toolbar's cloud icon to
see which file is connected or to disconnect it.
