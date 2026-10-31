import asyncio
import json
import math
import os
import re
import time
import uuid

from websockets.asyncio.server import serve

rooms = {}
MAX_MESSAGE_BYTES = 4096
MAX_ROOM_PLAYERS = 16
MAX_ROOMS = 128
MOVE_INTERVAL_SECONDS = 1 / 15
ROOM_PATTERN = re.compile(r"[^A-Z0-9_-]+")
PLAYER_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")


async def send_json(ws, payload):
    await ws.send(json.dumps(payload, separators=(",", ":"), ensure_ascii=False))


async def broadcast(room):
    players = list(rooms.get(room, {}).values())
    if not players:
        return
    public_players = [
        {key: value for key, value in player.items() if key not in {"_ws", "_last_move"}}
        for player in players
    ]
    message = json.dumps({"type": "state", "players": public_players}, separators=(",", ":"), ensure_ascii=False)
    sockets = [player["_ws"] for player in players if player.get("_ws")]
    if sockets:
        await asyncio.gather(*(ws.send(message) for ws in sockets), return_exceptions=True)


def clean_text(value, fallback, limit):
    if not isinstance(value, str):
        return fallback
    cleaned = "".join(char for char in value if char.isprintable()).strip()
    return cleaned[:limit] or fallback


def finite_number(value):
    if isinstance(value, bool):
        return None
    try:
        number = float(value)
    except (TypeError, ValueError, OverflowError):
        return None
    return number if math.isfinite(number) else None


async def handler(ws):
    player_id = None
    room = None
    player = None
    try:
        async for raw in ws:
            if not isinstance(raw, str) or len(raw.encode("utf-8")) > MAX_MESSAGE_BYTES:
                continue
            try:
                data = json.loads(raw)
            except (json.JSONDecodeError, TypeError):
                continue
            if not isinstance(data, dict):
                continue

            kind = data.get("type")
            if kind == "join" and player is None:
                requested_room = clean_text(data.get("room"), "IRON-01", 12).upper()
                room = ROOM_PATTERN.sub("", requested_room)[:12] or "IRON-01"
                if room not in rooms and len(rooms) >= MAX_ROOMS:
                    await send_json(ws, {"type": "error", "message": "現在ルーム数が上限に達しています。"})
                    await ws.close(code=1008, reason="server room limit")
                    return
                room_players = rooms.setdefault(room, {})
                if len(room_players) >= MAX_ROOM_PLAYERS:
                    await send_json(ws, {"type": "error", "message": f"このルームは満員です（最大{MAX_ROOM_PLAYERS}人）。"})
                    await ws.close(code=1008, reason="room full")
                    return

                requested_id = data.get("id", "")
                if not isinstance(requested_id, str) or not PLAYER_ID_PATTERN.fullmatch(requested_id):
                    requested_id = str(uuid.uuid4())
                if requested_id in room_players:
                    await send_json(ws, {"type": "error", "message": "同じプレイヤーIDがすでに接続しています。"})
                    await ws.close(code=1008, reason="duplicate player id")
                    return

                player_id = requested_id
                player = {
                    "id": player_id,
                    "name": clean_text(data.get("name"), "Operator", 16),
                    "x": 0.0,
                    "z": 10.0,
                    "yaw": 0.0,
                    "_ws": ws,
                    "_last_move": 0.0,
                }
                room_players[player_id] = player
                await send_json(ws, {"type": "notice", "message": f"ルーム {room} に参加しました"})
                await broadcast(room)

            elif kind == "move" and player is not None and room is not None:
                now = time.monotonic()
                if now - player["_last_move"] < MOVE_INTERVAL_SECONDS:
                    continue

                x = finite_number(data.get("x"))
                z = finite_number(data.get("z"))
                yaw = finite_number(data.get("yaw"))
                if x is None or z is None or yaw is None:
                    continue

                player["x"] = max(-19.0, min(19.0, x))
                player["z"] = max(-19.0, min(19.0, z))
                player["yaw"] = math.remainder(yaw, math.tau)
                player["_last_move"] = now
                await broadcast(room)

    except Exception:
        pass
    finally:
        if room and player_id:
            room_players = rooms.get(room)
            if room_players:
                room_players.pop(player_id, None)
                if not room_players:
                    rooms.pop(room, None)
                else:
                    await broadcast(room)


async def main():
    port = int(os.environ.get("PORT", "8765"))
    async with serve(handler, "0.0.0.0", port, ping_interval=20, ping_timeout=20,
                     max_size=MAX_MESSAGE_BYTES, max_queue=16):
        print(f"Operation: Iron Veil WebSocket server listening on port {port}")
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
