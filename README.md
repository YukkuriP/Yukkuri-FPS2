# Operation: Iron Veil

**A Yukkuri P Production**

Operation: Iron Veil is a work-in-progress cross-platform game project. This repository contains:
- **Godot prototype** — native project in the repository root.
- **Browser edition** — Three.js game in `web/` with optional WebSocket multiplayer in `server/`.

## Play the browser edition

### Option A — open the game from your own computer

1. Download the repository ZIP and extract it.
2. Open a terminal in the extracted repository folder.
3. Run:

```bash
python -m http.server 8000 --bind 127.0.0.1
```

4. Open **http://localhost:8000/web/** in your browser.

On Windows, `py -3 -m http.server 8000 --bind 127.0.0.1` may be used if `python` is not recognized. Keep the terminal open while playing; press Ctrl+C to stop the local web server. Do not open `web/index.html` as a `file://` URL because browser JavaScript modules require HTTP.

### Option B — publish it with GitHub Pages

The repository now has a root `index.html` that redirects to the browser game. In GitHub, open **Settings → Pages**, choose **Deploy from a branch**, select the `main` branch and `/(root)`, then save. After GitHub Pages finishes publishing, open:

`https://yukkurip.github.io/Yukkuri-FPS2/`

If Pages has not been enabled for the repository, the URL will not work until the setting is saved. GitHub Pages hosts the static game files; it does not run the Python multiplayer server. The browser loads Three.js from jsDelivr, so internet access is still required for that dependency.

## Game modes

### Offline training

Select **「訓練ミッションを開始（オフライン）」** from the menu. No multiplayer server is needed. Reach the three glowing objective markers in order before the three-minute timer expires. WASD or arrow keys move, Shift sprints, and the mouse controls the view. Touch devices use the on-screen movement pad and drag-to-look area.

### Optional online multiplayer

Multiplayer requires a separately hosted secure WebSocket server. The default configured address is `wss://iron-veil-server.onrender.com`; availability is not guaranteed, and free hosts may sleep. Enter a room code and select **「オンラインロビーに接続」**. The browser prototype currently synchronizes player positions and displays other players; the offline objective mission is currently single-player.

If connection fails, use offline training or check the server and network with the network administrator. Do not attempt to bypass school or organization network restrictions.

To run your own server, install Python 3.11+ and the dependency:

```bash
pip install -r server/requirements.txt
python server/main.py
```

Deploy it to a host that explicitly supports persistent WebSocket connections and TLS, then enter its `wss://` URL. The client intentionally requires secure WebSocket connections.

## Browser prototype status

Implemented:
- Startup title and responsive lobby.
- Offline three-objective timed training mission.
- 3D arena with textured ground, perimeter skyline, structures, lighting, fog, and objective markers.
- Soft directional shadows and improved material response, with capped pixel ratio to limit GPU cost.
- Desktop and touch movement, sprint, mouse/touch look, timer, and mission status.
- Initial offline combat loop: procedural first-person carbine, center-screen hitscan, target damage and elimination, ammo/reserve counter, reload timing, hit confirmation, and touch fire button.
- Optional WebSocket room join and player-position synchronization.
- Procedurally animated remote-player characters with smoothed network movement.
- Procedural human-shaped training soldiers in the browser prototype; they are target dummies, not yet combat-capable AI.
- Optional GLB character-model loading with animation clips. If `web/assets/characters/operator.glb` is not present or fails to load, the game safely keeps its procedural character fallback.

### Optional character model

To use a custom model, add a properly licensed, web-compatible GLB file at `web/assets/characters/operator.glb`. The model should be upright with its feet near ground level; embedded animation clips are supported. No third-party model is bundled in this repository, so the fallback character remains active until you supply one.

Still in development:
- The browser edition is a prototype, not a finished AAA game. Combat is currently a basic hitscan test against procedural human-shaped training targets, not a full enemy AI/combat campaign. Weapon animation, recoil tuning, cover-aware enemy AI, mission variety, effects, and balance still need work.
- Online match objectives are not synchronized yet; the current online feature is basic player-position synchronization.
- More playtesting is needed on low-spec Windows PCs and Android browsers.
- The browser edition loads Three.js from a CDN and is not fully offline with no internet at all.

## Godot prototype

The Godot project is currently in a **map-first exploration phase**. Open the repository root's `project.godot` in Godot 4.7.2. The procedural 1 km × 1 km map includes multi-scale mountain terrain, vertex-colour biomes, a detailed surface noise texture, a highway/tunnel corridor, city blocks and local streets, an underground facility, a factory, an airport, farmland, forest clusters, rural compounds, roadside infrastructure, and objective markers. Terrain normals are generated from neighboring height samples for smoother lighting. Forests use MultiMesh batching to reduce draw calls while retaining per-tree size and colour variation. The current Godot build intentionally has **no active enemy AI and no mission countdown**, so the map can be explored without a timed failure state.

Controls: WASD/arrow keys move, Shift sprints, left-click captures the mouse (subsequent clicks fire), R reloads, F toggles flight mode, Space ascends, Ctrl descends, and Esc opens the pause menu. In flight mode, movement follows the camera direction. The first-person carbine and basic target-hit code remain prototype systems and are not a finished combat loop. Procedural assets are still prototype-quality; visual inspection and runtime performance tests on Windows, including an 8 GB RAM machine, remain necessary. GitHub Actions checks Godot 4.7.2 headless import/script parsing and builds the Windows export, but successful CI does not prove the game has been visually or performance-tested on physical hardware. See [GODOT_EXPORT.md](GODOT_EXPORT.md) for Windows and Web export instructions.

## License

No license has been selected yet. Choose a license before accepting contributions or redistributing the project publicly.
