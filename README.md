# Final Fantasy Mobile

Mobile RPG built with Godot 4.3+. Android & iOS target.

## Export — Android APK

1. Install Android SDK + JDK 17
2. In Godot: Editor → Export → Add Android preset
3. Set package name: `com.yourname.ffmobile`
4. Enable "Permissions": `VIBRATE` (optional)
5. Click "Export Project" → select APK

## Export — iOS

1. Requires macOS with Xcode 14+
2. In Godot: Editor → Export → Add iOS preset
3. Set bundle ID + team ID
4. Click "Export Project" → open `.xcodeproj` in Xcode → Archive

## Development

- Engine: Godot 4.3+
- No assets required — all audio procedural, all visuals via ColorRect
- Run from Godot editor: Play (F5)

## Architecture

See `CLAUDE.md` for full architecture overview.
