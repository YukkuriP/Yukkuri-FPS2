# Operation: Iron Veil — Windows builds

The main Windows game is exported directly from the Godot project. It is not an Electron wrapper around the browser prototype.

## Build locally

1. Install Godot 4.4.1 or later.
2. Install the matching Godot export templates.
3. Open the repository root in Godot.
4. Select **Project → Export** and choose **Windows Desktop**.
5. Export to `release/Operation-Iron-Veil.exe`.

The preset enables an embedded PCK. The portable game is intended to be one standalone EXE.

## Build with GitHub Actions

The **Build Windows App** workflow:
- Installs Godot 4.4.1 and matching export templates.
- Imports and validates the project.
- Exports the Windows x64 game with embedded project resources.
- Builds an installer containing that same standalone EXE.
- Uploads both files as a workflow artifact.
- Publishes a stable GitHub release for a version tag.

## Outputs

- `Operation-Iron-Veil.exe` — portable standalone game.
- `Operation-Iron-Veil-Setup-<version>.exe` — installer.

## Notes

- Windows x64 only.
- The Godot main game is offline-capable and does not need the browser WebSocket server.
- Windows may show a SmartScreen warning because the executable is not code-signed.
- The separate `web/` browser prototype is not the 1 km Godot game.
- Build success does not replace real-device playtesting. Check the game on target Windows PCs before distributing it.
