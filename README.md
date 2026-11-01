# Operation: Iron Veil

**A Yukkuri P Production**

Operation: Iron Veil is a work-in-progress FPS project. The **main game is the Godot project in the repository root**. The Three.js browser edition is a separate, limited prototype and is not the Windows game's main build.

## Main game — Godot

Open the repository root in Godot 4.4.1 or later and run `scenes/main.tscn`.

The main game includes:
- A procedural **1 km × 1 km** battlefield.
- Mountainous terrain, forest clusters, tunnels, a north-south highway, two town districts, factory, airport, farmland, rural compounds and two opposing bases.
- First-person view, a detailed procedural carbine game prop, reload, hit feedback and HUD.
- Human soldier models with patrol, visual detection, pursuit and a simple in-game attack state.
- Offline free-roam; no multiplayer server is required for the Godot game.

### Controls

- WASD / arrow keys: move
- Mouse: look; left click once to capture the mouse, then click to fire
- Shift: sprint
- R: reload
- E: interact
- F: toggle development flight mode
- Space / Ctrl: ascend / descend while flight mode is active
- Esc: pause

### Windows release

The Windows build is exported from Godot, not Electron. The portable executable embeds the project data in the EXE, so it is designed to run as a **single file**.

GitHub Actions builds:
- `Operation-Iron-Veil.exe` — portable standalone game
- `Operation-Iron-Veil-Setup-<version>.exe` — installer containing the same game

The project uses Godot export templates; the build workflow installs them automatically.

## Browser edition — separate prototype

The `web/` folder contains an independent Three.js prototype with a small training arena and optional WebSocket player-position synchronization. It is not the 1 km Godot battlefield and does not contain the Godot soldier AI. Do not use the browser build as a substitute for the main game.

To run the browser prototype locally:

```bash
python -m http.server 8000 --bind 127.0.0.1
```

Then open `http://localhost:8000/web/`. The browser prototype loads Three.js from a CDN and requires internet access. Its multiplayer server is separate from the Godot game.

## Development status

This remains an in-development project, not a finished AAA game. The battlefield and basic enemy behavior are being restored first; animation quality, advanced navigation, richer mission systems, sound, optimization and thorough real-device playtesting still need work.

## License

No license has been selected yet. Choose a license before accepting contributions or redistributing the project publicly.
