# Operation: Iron Veil

**A Yukkuri P Production**

Operation: Iron Veil is a work-in-progress cross-platform game project. This repository contains:
- **Godot prototype** — native project in the repository root.
- **Browser edition** — Three.js client in `web/` and a Python WebSocket room server in `server/`.

## Browser edition: local launch, internet multiplayer

The browser game itself is served from your own computer using a local HTTP server. Multiplayer is internet-only and connects to the configured secure WebSocket endpoint (default: `wss://iron-veil-server.onrender.com`). The browser client rejects `ws://` endpoints so it won't connect to a LAN/local multiplayer server.

### Run the game client locally

Install Python 3, open a terminal at the repository root, and run:

```bash
python -m http.server 8000 --bind 127.0.0.1
```

Then open **http://localhost:8000/web/** in your browser. Keep the terminal open while playing; press Ctrl+C to stop the local web server. On Windows, `py -3 -m http.server 8000 --bind 127.0.0.1` can be used if `python` is not recognized.

Do not open `web/index.html` directly as a `file://` URL. JavaScript modules require the local HTTP server. The current client loads Three.js from jsDelivr, so the first load and game startup still require internet access; the game assets are not yet fully vendored for offline use.

### Internet multiplayer server

The default public endpoint is `wss://iron-veil-server.onrender.com`. It is hosted separately from the game client. A free Render instance may sleep during inactivity and take a while to wake up.

If you want to run your own public server, install Python 3.11+ and the dependency:

```bash
pip install -r server/requirements.txt
python server/main.py
```

Deploy it to a public host that supports persistent WebSocket connections and TLS, then set the client URL to its `wss://` address. The browser client intentionally does not accept `ws://` LAN/local endpoints.

## Browser controls

- WASD / arrow keys: move.
- Mouse: look around on desktop.
- Touch: use the on-screen movement pad; drag the right side of the screen to look around.
- Lobby: enter a player name, room code, and secure internet WebSocket URL.

## Current browser prototype status

- Startup credit animation and lobby.
- Lightweight 3D training arena.
- WebSocket room join and player position synchronization.
- Game client served locally; internet multiplayer uses a separate secure WebSocket server.
- This is an early movement/networking prototype, not a finished shooter. No weapon, damage, match, or anti-cheat systems are implemented.
- Test on actual low-spec Windows PCs and Android browsers before wider release.

## Godot prototype

Open the repository root's `project.godot` in Godot 4.x.

## License

No license has been selected yet. Choose a license before accepting contributions or redistributing the project publicly.
