# KOKBORI RP — Unity to PAWNO integration

This folder defines the first integration milestone for the separate Unity iOS client and the existing SA-MP/open.mp Pawn game server.

## Important compatibility note

A Unity game does not speak the SA-MP/RakNet protocol automatically. A normal Pawn gamemode also cannot accept arbitrary Unity TCP connections using stock SA-MP natives alone. Do not point a generic Unity TCP client at the SA-MP game port and expect it to work.

## Staged architecture

- Unity owns rendering, input, camera, animation, local prediction and UI.
- PAWNO remains authoritative for accounts, money, inventory, jobs, vehicles and roleplay rules.
- A dedicated transport adapter is required between Unity and the Pawn server. It must be implemented using a compatible server plugin/module or a separately hosted gateway. It is not the stock SA-MP RakNet protocol.
- MySQL persists player data. Never store plaintext passwords; use a vetted password hash on the server.

## First milestone

1. Confirm the exact server runtime (SA-MP 0.3.7, open.mp, or another fork) and installed plugins/includes.
2. Confirm the available network plugin/API before writing socket calls in Pawn. Plugin APIs differ; guessing native names creates scripts that do not compile.
3. Implement and test a transport adapter with versioned messages.
4. Add login/register, then spawn, movement, vehicle state, chat and economy in that order.

## Message contract

Every message is UTF-8 JSON with a protocol version and a type discriminator.

Client to server:
- hello: {"v":1,"type":"hello","client":"kokbori-unity"}
- login: {"v":1,"type":"login","name":"...","password":"..."}
- move: {"v":1,"type":"move","x":0,"y":0,"z":0,"heading":0}
- chat: {"v":1,"type":"chat","text":"..."}

Server to client:
- hello_ok: protocol accepted
- login_result: success/failure and server-side player ID
- spawn: authoritative position and heading
- player_state: server-authoritative position/heading for remote players
- chat: sender and message
- error: machine-readable error code

## Security and authority

- The client must never decide its own balance, inventory, job payout, vehicle ownership or permissions.
- Validate coordinates, message sizes, rates and account input on the server.
- Use TLS or a protected private network for any gateway exposed outside the game host.
- Keep server secrets and database credentials out of the Unity project.

## Current limitation

This is an integration contract and a Unity transport starter, not a working live connection. The Pawn transport adapter cannot be completed safely until the actual server version and installed socket/network plugin are known. The supplied server address and port alone do not identify that API.
