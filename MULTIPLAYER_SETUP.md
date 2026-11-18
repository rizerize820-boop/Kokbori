# KOKBORI RP multiplayer setup

## What this starter provides
- A basic Pawn gamemode skeleton using standard SA-MP natives.
- A Unity TCP gateway client starter in the Unity project.
- A versioned message contract describing a future Unity-to-server adapter.

## What it does NOT provide yet
- A working Unity-to-PAWNO network bridge.
- Account registration, secure password storage, or database persistence.
- A built iOS app, signed IPA, deployed server, or tested multiplayer session.
- A verified connection to the previously supplied server endpoint.

## Critical compatibility boundary
The Unity TCP starter speaks newline-delimited JSON to a dedicated gateway. A stock SA-MP/open.mp game server speaks its own RakNet-based protocol to compatible SA-MP clients. They are not interchangeable. Do not configure Unity's TCP component to connect directly to the ordinary SA-MP port.

## Next required server information
Provide the existing server's:
- exact runtime and version (SA-MP 0.3.7, open.mp, or fork);
- gamemode source and its includes;
- plugins folder and server config (remove passwords/secrets first);
- database schema with credentials removed.

Then the adapter can be implemented against the actual installed networking API. The server must be backed up before replacing any gamemode files.
