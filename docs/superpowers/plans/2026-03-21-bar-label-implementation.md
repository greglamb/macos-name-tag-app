# BarLabel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that displays the machine's hostname (or a custom label) with options to configure the label and toggle start-at-login.

**Architecture:** SwiftUI App lifecycle with `NSApplicationDelegateAdaptor` bridging to AppKit for `NSStatusItem`/`NSMenu` control. `AppState` (ObservableObject) is the single source of truth — reads custom label from UserDefaults, falls back to live hostname. Options dialog is a SwiftUI view hosted in an `NSPanel`.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, ServiceManagement (SMAppService), macOS 13.0+

**Environment note:** This project runs on Linux for development. There is no Xcode CLI or macOS SDK available, so `swift build` and `swift test` cannot be run. Code is written and committed; building/testing happens on macOS. Each task includes verification steps appropriate for this constraint (syntax review, file existence checks).

---

## File Structure

```
macos-bar-label/
├── BarLabel/
│   ├── BarLabelApp.swift              # @main App struct, NSApplicationDelegateAdaptor
│   ├── AppDelegate.swift              # NSStatusItem, NSMenu, login item toggle
│   ├── AppState.swift                 # ObservableObject: custom label, displayLabel
│   ├── OptionsView.swift              # SwiftUI view: text field, Save/Cancel/Hostname
│   ├── OptionsWindowController.swift  # NSPanel creation, singleton window management
│   ├── Assets.xcassets/
│   │   └── Contents.json             # Asset catalog root
│   └── Info.plist                     # LSUIElement = true
├── BarLabel.xcodeproj/
│   └── project.pbxproj               # Xcode project file
└── docs/
```

**Responsibilities:**
- `AppState.swift` — Owns all state: reads/writes `"customLabel"` in UserDefaults, exposes `displayLabel` (custom label or hostname). Pure logic, no UI.
- `AppDelegate.swift` — Creates `NSStatusItem` + `NSMenu`, observes `AppState.displayLabel` via Combine to update the menu bar title. Handles menu actions (login toggle, open options, quit).
- `OptionsWindowController.swift` — Manages a single `NSPanel` instance. Creates it on first use, brings to front on subsequent calls. Hosts `OptionsView` via `NSHostingController`.
- `OptionsView.swift` — SwiftUI form: text field bound to local state, three buttons (Hostname/Cancel/Save) that call back to `AppState` and dismiss.
- `BarLabelApp.swift` — Minimal `@main` struct that wires `NSApplicationDelegateAdaptor` to `AppDelegate`. No `WindowGroup` (menu bar-only app).

---

### Task 1: Create Xcode Project Structure

**Files:**
- Create: `BarLabel/Info.plist`
- Create: `BarLabel/Assets.xcassets/Contents.json`
- Create: `BarLabel.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create the directory structure**

```bash
mkdir -p BarLabel/Assets.xcassets
mkdir -p BarLabel.xcodeproj
```

- [ ] **Step 2: Create Info.plist**

Create `BarLabel/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

`LSUIElement = true` makes this a menu bar-only app (no Dock icon, no main menu bar).

- [ ] **Step 3: Create Assets.xcassets/Contents.json**

Create `BarLabel/Assets.xcassets/Contents.json`:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Create project.pbxproj**

Create `BarLabel.xcodeproj/project.pbxproj` with a complete Xcode project file. This is a standard pbxproj for a macOS app target with:
- All 5 Swift source files referenced (BarLabelApp.swift, AppDelegate.swift, AppState.swift, OptionsView.swift, OptionsWindowController.swift)
- Assets.xcassets and Info.plist referenced
- macOS 13.0 deployment target
- Swift 5.0 language version
- ServiceManagement framework linked
- Product name: BarLabel
- Bundle identifier: com.barlabel.app

**Note:** The pbxproj file is large and mechanical. Generate a valid, complete pbxproj. Use unique 24-character hex strings for each PBXObject UUID. Include all standard build settings for a macOS app.

- [ ] **Step 5: Verify files exist**

```bash
ls -la BarLabel/Info.plist BarLabel/Assets.xcassets/Contents.json BarLabel.xcodeproj/project.pbxproj
```

Expected: all three files exist.

- [ ] **Step 6: Commit**

```bash
git add BarLabel/Info.plist BarLabel/Assets.xcassets/Contents.json BarLabel.xcodeproj/project.pbxproj
git commit -m "feat: create Xcode project structure with Info.plist and asset catalog"
```

---

### Task 2: Implement AppState

**Files:**
- Create: `BarLabel/AppState.swift`

This is the core data model — no UI dependencies, pure logic + UserDefaults + Combine.

- [ ] **Step 1: Create AppState.swift**

Create `BarLabel/AppState.swift`:

```swift
import Foundation
import Combine

final class AppState: ObservableObject {
    private static let customLabelKey = "customLabel"

    @Published var customLabel: String? {
        didSet {
            if let customLabel {
                UserDefaults.standard.set(customLabel, forKey: Self.customLabelKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.customLabelKey)
            }
        }
    }

    var displayLabel: String {
        customLabel ?? ProcessInfo.processInfo.hostName
    }

    init() {
        self.customLabel = UserDefaults.standard.string(forKey: Self.customLabelKey)
    }

    func resetToHostname() {
        customLabel = nil
    }
}
```

Key design points:
- `customLabel` is `String?` — nil means "use hostname"
- `didSet` persists to UserDefaults on every change (including removal)
- `displayLabel` is a computed property, always returns the right value
- `resetToHostname()` sets `customLabel = nil`, which triggers `didSet` to remove the key

- [ ] **Step 2: Verify file exists and syntax looks correct**

```bash
cat BarLabel/AppState.swift
```

Expected: file contents match above.

- [ ] **Step 3: Commit**

```bash
git add BarLabel/AppState.swift
git commit -m "feat: add AppState with UserDefaults persistence and hostname fallback"
```

---

### Task 3: Implement OptionsView

**Files:**
- Create: `BarLabel/OptionsView.swift`

SwiftUI view for the options dialog. Uses local `@State` for the text field so edits don't immediately affect the menu bar.

- [ ] **Step 1: Create OptionsView.swift**

Create `BarLabel/OptionsView.swift`:

```swift
import SwiftUI

struct OptionsView: View {
    @ObservedObject var appState: AppState
    var onDismiss: () -> Void

    @State private var labelText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Display Label:")
                .font(.headline)

            TextField("Enter label", text: $labelText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Hostname") {
                    appState.resetToHostname()
                    onDismiss()
                }

                Spacer()

                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    appState.customLabel = labelText
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 350)
        .onAppear {
            labelText = appState.displayLabel
        }
    }
}
```

Key design points:
- `@State private var labelText` — local edit buffer, not bound to AppState
- `.onAppear` seeds the text field with the current display label
- Save writes local text to `appState.customLabel`
- Hostname calls `appState.resetToHostname()` (deletes the key)
- Cancel just dismisses without touching state
- `.keyboardShortcut(.cancelAction)` = Esc, `.defaultAction` = Enter

- [ ] **Step 2: Verify file exists**

```bash
cat BarLabel/OptionsView.swift
```

- [ ] **Step 3: Commit**

```bash
git add BarLabel/OptionsView.swift
git commit -m "feat: add OptionsView with Save, Cancel, and Hostname buttons"
```

---

### Task 4: Implement OptionsWindowController

**Files:**
- Create: `BarLabel/OptionsWindowController.swift`

Manages a single `NSPanel` instance. If the window is already open, brings it to front.

- [ ] **Step 1: Create OptionsWindowController.swift**

Create `BarLabel/OptionsWindowController.swift`:

```swift
import AppKit
import SwiftUI

final class OptionsWindowController {
    private var panel: NSPanel?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func showOptionsPanel() {
        if let panel, panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Options"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.hidesOnDeactivate = false

        let hostingController = NSHostingController(
            rootView: OptionsView(appState: appState) { [weak panel] in
                panel?.close()
            }
        )
        panel.contentViewController = hostingController
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = panel
    }
}
```

Key design points:
- `panel` is retained as an instance property — reused if already visible
- `isReleasedWhenClosed = false` prevents deallocation on close
- `level = .floating` keeps it above other windows
- `hidesOnDeactivate = false` keeps it visible when app loses focus
- `onDismiss` closure calls `panel?.close()` — captured weakly to avoid retain cycle
- `NSApp.activate(ignoringOtherApps: true)` ensures the panel gets focus (menu bar apps aren't normally active)

- [ ] **Step 2: Verify file exists**

```bash
cat BarLabel/OptionsWindowController.swift
```

- [ ] **Step 3: Commit**

```bash
git add BarLabel/OptionsWindowController.swift
git commit -m "feat: add OptionsWindowController with NSPanel and singleton management"
```

---

### Task 5: Implement AppDelegate

**Files:**
- Create: `BarLabel/AppDelegate.swift`

This is the largest file. Creates the status item, builds the menu, handles all menu actions, observes AppState for title updates.

- [ ] **Step 1: Create AppDelegate.swift**

Create `BarLabel/AppDelegate.swift`:

```swift
import AppKit
import Combine
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let appState = AppState()
    private var optionsWindowController: OptionsWindowController!
    private var cancellable: AnyCancellable?
    private var loginItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        optionsWindowController = OptionsWindowController(appState: appState)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = appState.displayLabel

        buildMenu()

        cancellable = appState.$customLabel
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.statusItem.button?.title = self.appState.displayLabel
            }
    }

    private func buildMenu() {
        let menu = NSMenu()

        loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.target = self
        updateLoginCheckmark()
        menu.addItem(loginItem)

        let optionsItem = NSMenuItem(title: "Options...", action: #selector(openOptions), keyEquivalent: "")
        optionsItem.target = self
        menu.addItem(optionsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateLoginCheckmark() {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Login item toggle failed: \(error)")
        }
        updateLoginCheckmark()
    }

    @objc private func openOptions() {
        optionsWindowController.showOptionsPanel()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

Key design points:
- `appState` is created here and passed to `OptionsWindowController` — single instance shared everywhere
- Combine subscription on `$customLabel` updates the status item title reactively
- `loginItem` is stored so `updateLoginCheckmark()` can toggle the checkmark state
- Menu items use `target = self` — required for `NSMenuItem` action dispatch when there's no responder chain (menu bar app)
- `SMAppService` errors are logged silently; checkmark always reads from `.status` for accuracy

- [ ] **Step 2: Verify file exists**

```bash
cat BarLabel/AppDelegate.swift
```

- [ ] **Step 3: Commit**

```bash
git add BarLabel/AppDelegate.swift
git commit -m "feat: add AppDelegate with status item, menu, and login item toggle"
```

---

### Task 6: Implement BarLabelApp (Entry Point)

**Files:**
- Create: `BarLabel/BarLabelApp.swift`

Minimal `@main` struct. No `WindowGroup` — this is a menu bar-only app.

- [ ] **Step 1: Create BarLabelApp.swift**

Create `BarLabel/BarLabelApp.swift`:

```swift
import SwiftUI

@main
struct BarLabelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

Key design points:
- `@NSApplicationDelegateAdaptor` bridges the SwiftUI lifecycle to our AppKit `AppDelegate`
- `Settings { EmptyView() }` provides the required `Scene` conformance without creating a visible window
- All actual UI is managed by `AppDelegate` via `NSStatusItem` and `NSPanel`

- [ ] **Step 2: Verify file exists**

```bash
cat BarLabel/BarLabelApp.swift
```

- [ ] **Step 3: Commit**

```bash
git add BarLabel/BarLabelApp.swift
git commit -m "feat: add BarLabelApp entry point with NSApplicationDelegateAdaptor"
```

---

### Task 7: Update project.pbxproj with All Source Files

**Files:**
- Modify: `BarLabel.xcodeproj/project.pbxproj`

After all Swift files are created, verify the pbxproj references every file correctly. If Task 1 already included all files, this is a verification-only step.

- [ ] **Step 1: Verify all source files are referenced in pbxproj**

Check that `project.pbxproj` contains references to:
- `BarLabelApp.swift`
- `AppDelegate.swift`
- `AppState.swift`
- `OptionsView.swift`
- `OptionsWindowController.swift`
- `Assets.xcassets`
- `Info.plist`
- `ServiceManagement.framework` (or framework build setting)

```bash
grep -c "BarLabelApp.swift\|AppDelegate.swift\|AppState.swift\|OptionsView.swift\|OptionsWindowController.swift\|Assets.xcassets\|Info.plist" BarLabel.xcodeproj/project.pbxproj
```

Expected: multiple matches (each file appears in PBXFileReference, PBXBuildFile, PBXSourcesBuildPhase, etc.)

- [ ] **Step 2: Fix any missing references if needed**

If any file is missing from the pbxproj, add the appropriate PBXFileReference, PBXBuildFile, and source/resource build phase entries.

- [ ] **Step 3: Commit (if changes were made)**

```bash
git add BarLabel.xcodeproj/project.pbxproj
git commit -m "fix: ensure all source files are referenced in Xcode project"
```

---

### Task 8: Final Review and Push

- [ ] **Step 1: Verify all files exist**

```bash
ls -la BarLabel/BarLabelApp.swift BarLabel/AppDelegate.swift BarLabel/AppState.swift BarLabel/OptionsView.swift BarLabel/OptionsWindowController.swift BarLabel/Info.plist BarLabel/Assets.xcassets/Contents.json BarLabel.xcodeproj/project.pbxproj
```

Expected: all 8 files exist.

- [ ] **Step 2: Review git log**

```bash
git log --oneline -10
```

Expected: commits for project structure, AppState, OptionsView, OptionsWindowController, AppDelegate, BarLabelApp.

- [ ] **Step 3: Push to remote**

```bash
git push -u origin claude/install-swiftui-agent-skill-rmyHV
```

- [ ] **Step 4: Run SwiftUI review skill**

Use `/swiftui-pro` to review all Swift files for best practices.
