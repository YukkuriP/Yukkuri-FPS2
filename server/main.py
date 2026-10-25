import asyncio
import json
import os
import uuid
from websockets.asyncio.server import serve

rooms = {}

async def send_json(ws, payload):
    await ws.send(json.dumps(payload, separators=(",", ":")))

async def broadcast(room):
    players = list(rooms.get(room, {}).values())
    if not players:
        return
    message = json.dumps({"type": "state", "players": players}, separators=(",", ":"))
    sockets = [p["_ws"] for p in players if p.get("_ws")]
    if sockets:
        await asyncio.gather(*(ws.send(message) for ws in sockets), return_exceptions=True)

async def handler(ws):
    player_id = None
    room = None
    player = None
    try:
        async for raw in ws:
            if len(raw) > 4096:
                continue
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                continue
            kind = data.get("type")
            if kind == "join":
                room = "".join(c for c in str(data.get("room", "IRON-01")).upper() if c.isalnum() or c in "-_")[:12] or "IRON-01"
                player_id = str(uuid.uuid4())
                player = {"id": player_id, "name": str(data.get("name", "Operator"))[:16], "x": 0, "z": 10, "yaw": 0, "_ws": ws}
                rooms.setdefault(room, {})[player_id] = player
                await send_json(ws, {"type": "notice", "message": f"ルーム {room} に参加しました"})
                await broadcast(room)
            elif kind == "move" and player and room:
                try:
                    x = max(-17.0, min(17.0, float(data.get("x", 0))))
                    z = max(-17.0, min(17.0, float(data.get("z", 0))))
                    yaw = float(data.get("yaw", 0))
                except (TypeError, ValueError):
                    continue
                player["x"], player["z"], player["yaw"] = x, z, max(-1000, min(1000, yaw))
                await broadcast(room)
    except Exception:
        pass
    finally:
        if room and player_id:
            rooms.get(room, {}).pop(player_id, None)
            if not rooms.get(room):
                rooms.pop(room, None)
            else:
                await broadcast(room)

async def main():
    port = int(os.environ.get("PORT", "8765"))
    async with serve(handler, "0.0.0.0", port, ping_interval=20, ping_timeout=20, max_size=4096):
        print(f"Operation: Iron Veil WebSocket server listening on port {port}")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())
