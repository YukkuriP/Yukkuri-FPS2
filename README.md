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

Multiplayer requires a separately hosted secure WebSocket server. The default configured address is `wss://iron-veil-server.onrender.com`; availability is not guaranteed, and free hosts may sleep. Enter a room code and select **「オンラインロビーに接続」**. The browser prototype synchronizes player positions and displays other players. Position updates are limited to 15 per second; the server validates numeric input and limits rooms to 16 players. The offline objective mission is single-player.

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
- Optional WebSocket room join and player-position synchronization.
- Procedurally animated remote-player characters with smoothed network movement.
- Three non-combat training drones that patrol around their home positions and observe the player nearby.
- Optional GLB character-model loading with animation clips. If `web/assets/characters/operator.glb` is not present or fails to load, the game safely keeps its procedural character fallback.

### Optional character model

To use a custom model, add a properly licensed, web-compatible GLB file at `web/assets/characters/operator.glb`. The model should be upright with its feet near ground level; embedded animation clips are supported. No third-party model is bundled in this repository, so the fallback character remains active until you supply one.

Still in development:
- The browser edition is a prototype, not a finished AAA game.
- Online match objectives are not synchronized yet; the current online feature is basic player-position synchronization.
- More playtesting is needed on low-spec Windows PCs and Android browsers. Touch look now uses a dedicated pointer-captured control, and movement is blocked by the arena's box obstacles.
- The browser edition loads Three.js from a CDN and is not fully offline with no internet at all.

## Godot prototype

Open the repository root's `project.godot` in Godot 4.x.

## License

No license has been selected yet. Choose a license before accepting contributions or redistributing the project publicly.
