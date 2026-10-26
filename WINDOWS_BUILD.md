# Operation: Iron Veil — Windows builds

The project can be packaged as both a portable Windows executable and a conventional installer using Electron and electron-builder.

## Build on Windows

1. Install Node.js 22 LTS from https://nodejs.org/.
2. Download or clone this repository.
3. Open a terminal in the repository root.
4. Run:

```powershell
npm install
npm run dist:win
```

The two x64 outputs are written to `release/`:
- `Operation-Iron-Veil-Portable-0.1.0.exe` — portable executable.
- `Operation-Iron-Veil-Setup-0.1.0.exe` — installer with optional install directory and desktop shortcut.

To run the development build instead, use `npm start`.

## Build from GitHub without installing tools locally

Open the repository's **Actions** tab, choose **Build Windows App**, select **Run workflow**, and start the workflow. When it finishes, open the run and download the `Operation-Iron-Veil-Windows` artifact. The artifact is a ZIP download containing the portable executable and installer.

Pushing a version tag such as `v0.1.0` also triggers the build.

## Important notes

- The build workflow creates Windows x64 packages; it does not commit binary executables to the source repository.
- The game still uses Three.js from a CDN, so internet access is required to load that dependency.
- Online play still requires the WebSocket server configured by the game to be running and reachable. Packaging the client does not host that server.
- These are unsigned development builds. Windows SmartScreen may show a warning because the executable is not code-signed.
- The current game prototype has not been validated on every Windows device. Test the generated files before distributing them widely.
