# Godot exports — Operation: Iron Veil

The repository contains two clients with different purposes:

- **Godot prototype**: open `project.godot` from the repository root in Godot 4.x.
- **Browser edition**: the Three.js client in `web/`, which can be published as static files (for example, with GitHub Pages).

They are currently separate implementations. Exporting the Godot project does not automatically package or update the Three.js browser edition, and gameplay features are not automatically shared between them.

## Run the Godot prototype

1. Install a compatible Godot 4.x editor. The project currently declares Godot 4.2 compatibility.
2. Download or clone the repository and open its root `project.godot`.
3. Let Godot import the project, then press **F6** to run the current scene or **F5** to run the configured main scene.
4. Fix any project/import/runtime errors shown by the editor before exporting.

## Export a Windows executable

1. In Godot, open **Editor → Manage Export Templates** and install the export templates matching the editor version.
2. Open **Project → Export** and add a **Windows Desktop** preset.
3. Choose an output path such as `build/Operation-Iron-Veil.exe`.
4. Select **Export Project** (not Export PCK/ZIP), then run the generated executable on Windows.
5. Test it on a second Windows machine or a clean user account before distributing it.

For an unsigned indie build, Windows may show a SmartScreen warning. Code signing is optional for local testing but is needed for a more polished public release experience.

## Export a Godot Web build

1. Install the matching Godot export templates.
2. In **Project → Export**, add a **Web** preset and export to a separate folder such as `build/web/`.
3. Host the entire exported folder over HTTPS. Do not upload only the HTML file: the JavaScript loader, WebAssembly, PCK and supporting files must stay together.
4. Test the hosted build in current desktop and mobile browsers.

Web export availability and compatibility depend on the Godot version and project features. Browser builds have additional limits around threads, audio autoplay, file access and networking. If Web export fails, check the editor's export error output and project compatibility first.

## Publish the existing Three.js browser edition

The separate browser client is in `web/`. It can be hosted as static files using GitHub Pages; see the root README for setup. The Python WebSocket multiplayer server is **not** hosted by GitHub Pages and must be deployed separately to a service that supports persistent secure WebSocket connections.

## Build automation and release policy

A future GitHub Actions workflow can produce the Windows and Web artifacts automatically, but it should only be enabled after the Godot project imports, runs and exports successfully. CI output is not proof that gameplay works; test exported builds and multiplayer separately.

## Current limitations

- Godot and Three.js are separate codebases, so fixes may need to be implemented twice until a shared design/data layer is introduced.
- The current Godot prototype is not yet confirmed feature-equivalent to the browser version.
- The project should not be described as AAA-ready or as supporting stable 15-player matches until performance and network tests have passed.
