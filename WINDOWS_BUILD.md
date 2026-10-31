# Operation: Iron Veil — Windows builds

The browser edition can be packaged as a portable Windows executable and an installer using Electron and electron-builder.

## Build on Windows

1. Install Node.js 22 LTS.
2. Download or clone this repository.
3. Open a terminal in the repository root.
4. Run:

```powershell
npm install
npm run dist:win
```

The x64 outputs are written to `release/`:
- `Operation-Iron-Veil-Portable-0.2.0.exe` — portable executable.
- `Operation-Iron-Veil-Setup-0.2.0.exe` — installer with optional install directory and shortcuts.

The filenames are generated from the version in `package.json`; update that version before making a new release.

## Build with GitHub Actions

Open the repository's **Actions** tab, choose **Build Windows App**, and select **Run workflow**. The run creates a downloadable artifact named `Operation-Iron-Veil-Windows-0.2.0`. A version tag such as `v0.2.0` also triggers a build and prerelease.

## Important notes

- These are Windows x64 packages. The workflow uploads the build artifact and publishes a prerelease for manual runs and version tags.
- The package contains the browser edition; it does not package the Godot prototype.
- Three.js is loaded from jsDelivr using an import map, so internet access is required.
- Online play requires a separately hosted WebSocket server with TLS. Packaging the client does not host the server.
- These are unsigned development builds. Windows SmartScreen may show a warning because the executable is not code-signed.
- Test generated files on target Windows devices before distributing them.
