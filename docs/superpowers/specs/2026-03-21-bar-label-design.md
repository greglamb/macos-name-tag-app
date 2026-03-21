# BarLabel — macOS Menu Bar Hostname/Label App

## Overview

A macOS menu bar-only app that displays the machine's hostname (or a user-defined custom label) as text in the system status bar. Clicking the text reveals a dropdown menu with options to configure the label, toggle start-at-login, or quit.

**Target**: macOS 13.0+, Swift 5.9+

## Architecture

**Approach**: SwiftUI App lifecycle with AppKit menu bar plumbing.

- `@main` SwiftUI App struct with `NSApplicationDelegateAdaptor` for the AppDelegate
- `NSStatusItem` with `NSMenu` for full control over the menu bar (text-only, no icon)
- SwiftUI view hosted in an `NSPanel` for the options dialog
- Menu bar-only app: `LSUIElement = true` (no Dock icon, no main window)

## Menu Bar

The status item displays **text only** — no icon. The text is either:
- The machine's live hostname via `ProcessInfo.processInfo.hostName` (default)
- A user-defined custom label stored in UserDefaults

### Dropdown Menu

```
┌─────────────────────────┐
│ ✓ Start at Login        │  ← Toggle with checkmark
│ Options...              │  ← Opens options dialog
│ ───────────────────     │  ← Separator
│ Quit                    │  ← Exits the app
└─────────────────────────┘
```

## Options Dialog

A floating `NSPanel`, centered on screen, containing a SwiftUI view via `NSHostingController`.

### Layout

```
┌─────────────────────────────────────┐
│  Options                            │
│                                     │
│  Display Label:                     │
│  ┌───────────────────────────────┐  │
│  │ [current text or hostname]    │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Hostname]    [Cancel]    [Save]   │
│                                     │
└─────────────────────────────────────┘
```

### Button Behavior

- **Save** — Writes the text field value to UserDefaults as the custom label, updates the status item title, closes the dialog.
- **Cancel** — Discards changes, closes the dialog.
- **Hostname** — Deletes the custom label key from UserDefaults entirely. The app reverts to reading the live hostname from `ProcessInfo.processInfo.hostName`. This means if the machine's hostname changes, the menu bar reflects it automatically. Closes the dialog.

## Start at Login

Uses `SMAppService.mainApp` from the `ServiceManagement` framework (macOS 13+).

- Menu item reads current status from `SMAppService.mainApp.status` to show/hide checkmark
- Clicking toggles: registered → `unregister()`, unregistered → `register()`
- Checkmark updates immediately after toggling
- No helper app or launch agent needed

## Data Flow & State Management

### AppState (ObservableObject)

Single source of truth for the display label:

- Reads/writes custom label to UserDefaults
- Exposes a computed `displayLabel`: returns custom label if set, otherwise `ProcessInfo.processInfo.hostName`
- AppDelegate observes this and updates `statusItem.button?.title` on change

```
UserDefaults (custom label, if set)
        ↓
    AppState.displayLabel  ←── ProcessInfo.hostName (fallback)
        ↓
    NSStatusItem.button.title
```

The options dialog receives the same `AppState` instance, so changes propagate immediately.

### Persistence

- **UserDefaults** stores only the custom label (when set)
- No value stored = use live hostname (hostname is never saved since it can change)
- Simple key: `"customLabel"` → `String?`

## Project Structure

```
macos-bar-label/
├── BarLabel/
│   ├── BarLabelApp.swift              # @main, NSApplicationDelegateAdaptor
│   ├── AppDelegate.swift              # NSStatusItem, NSMenu setup
│   ├── AppState.swift                 # ObservableObject, UserDefaults, display logic
│   ├── OptionsView.swift              # SwiftUI view for the options dialog
│   ├── OptionsWindowController.swift  # NSPanel hosting the SwiftUI view
│   ├── Assets.xcassets/               # App icon (can be empty initially)
│   └── Info.plist                     # LSUIElement = true
├── BarLabel.xcodeproj/                # Xcode project file
└── docs/
    └── superpowers/specs/             # This design doc
```

## Error Handling & Edge Cases

- **SMAppService failure** — Log the error silently. Checkmark reads from `.status` so it always reflects reality.
- **Long labels** — The menu bar truncates naturally. No enforced limit.
- **Options dialog already open** — Bring existing window to front instead of opening a second one.
- **No prior state** — No UserDefaults key = show live hostname. No first-run setup needed.

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Architecture | SwiftUI lifecycle + AppKit menu plumbing | Modern app lifecycle with full NSStatusItem control for text-only display |
| Login item | SMAppService (macOS 13+) | Apple-recommended, no helper app needed |
| Persistence | UserDefaults | Simple key-value, standard for app preferences |
| Hostname storage | Never saved | Hostname can change; always read live |
| Minimum macOS | 13.0 | Required for SMAppService and MenuBarExtra-era APIs |
