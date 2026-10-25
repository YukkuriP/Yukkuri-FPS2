# Operation: Iron Veil

**A Yukkuri P Production**

Operation: Iron Veil is a work-in-progress cross-platform game project. This repository now contains two separate prototypes:

- **Godot prototype** — native project in the repository root.
- **Browser edition** — lightweight Three.js client in `web/`, plus a Python WebSocket room server in `server/`.

## Browser edition (online movement test)

### Run the browser client locally
From the repository root, start a static web server, for example:

```bash
python -m http.server 8000
```

Then open `http://localhost:8000/web/`.

### Run the multiplayer server locally
Install Python 3.11+ and the dependency:

```bash
pip install -r server/requirements.txt
python server/main.py
```

In the browser lobby, enter `ws://localhost:8765` as the server URL for a local test. For another device on the same network, use the host PC's LAN address and port 8765, if the network/firewall permits it.

For internet play, deploy `server/main.py` to a public Python host that supports long-running WebSocket connections, then enter its secure `wss://` URL. GitHub Pages can host the static browser files, but cannot run the Python multiplayer server itself.

## Browser controls
- WASD / arrow keys: move.
- Mouse: look around on desktop.
- Touch: use the on-screen movement pad; drag the right side of the screen to look around.
- Lobby: enter a player name, room code, and WebSocket URL.

## Current browser prototype status
- Startup credit animation and lobby.
- Lightweight 3D training arena.
- WebSocket room join and player position synchronization.
- Online play requires a separately running/deployed WebSocket server.
- This is an early movement/networking prototype, not a finished shooter. No weapon, damage, match, or anti-cheat systems are implemented.
- Test on actual low-spec Windows PCs and Android browsers before wider release.

## Godot prototype
Open the repository root's `project.godot` in Godot 4.x. See the Godot prototype notes above for current limitations.

## License
No license has been selected yet. Choose a license before accepting contributions or redistributing the project publicly.
