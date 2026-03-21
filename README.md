# 🏷️ Name Tag

A tiny macOS menu bar app that displays your machine's hostname — or a custom label — right in the status bar.

Useful for telling machines apart when you're working across multiple Macs, VMs, or remote desktops.

## What It Does

Name Tag sits in your menu bar and shows a text label. By default it displays your machine's hostname. You can change it to any custom text you like.

**Menu bar:**
```
 Wi-Fi  🔋  Name Tag  [your-hostname]  🔍
```

**Clicking the label reveals a dropdown menu:**
- **Start at Login** — Toggle whether Name Tag launches automatically
- **Options...** — Open the options dialog to change the label
- **Quit** — Exit the app

**Options dialog:**
- Type any text to use as your custom label
- Click **Save** to apply it
- Click **Hostname** to revert to your machine's live hostname
- Click **Cancel** to discard changes

## Install

### Homebrew (recommended)

```bash
brew install --cask greglamb/tap/name-tag
```

### Manual

1. Download `NameTag.dmg` from the [latest release](https://github.com/greglamb/macos-name-tag-app/releases/latest)
2. Open the DMG and drag **NameTag.app** to your Applications folder
3. Launch Name Tag from Applications

## Usage

Once running, Name Tag appears as text in your menu bar. There is no Dock icon and no main window — it lives entirely in the menu bar.

- **Change the label:** Click the text in the menu bar → Options... → type your label → Save
- **Revert to hostname:** Click → Options... → Hostname
- **Start at login:** Click → Start at Login (a checkmark indicates it's enabled)
- **Quit:** Click → Quit

Your custom label is saved automatically and persists across restarts.

## Build from Source

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later

### Build

```bash
git clone https://github.com/greglamb/macos-name-tag-app.git
cd macos-name-tag-app
xcodebuild -project NameTag.xcodeproj -scheme NameTag -configuration Release build
```

The built app will be in the `build/` directory. You can also open `NameTag.xcodeproj` in Xcode and build with Cmd+B.

### Run from Xcode

1. Open `NameTag.xcodeproj` in Xcode
2. Select the **NameTag** scheme
3. Click Run (Cmd+R)

Note: Since this is a menu bar app (`LSUIElement = true`), it won't appear in the Dock. Look for the hostname text in your menu bar.

## License

[MIT](LICENSE)
