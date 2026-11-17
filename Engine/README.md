# KOKBORI Engine — first playable prototype

A small original Godot 4 project intended as the future 3D runtime for KOKBORI RP on iOS.

## Current prototype
- Third-person character with a spring-arm camera.
- Basic walking and collision.
- Touch joystick for mobile and WASD/arrow-key input for desktop.
- Procedurally generated placeholder city blocks, roads, sidewalks, and a Baiterek-inspired landmark.
- Mobile renderer preset.

## Run locally
1. Install Godot 4.3 or newer.
2. Import `project.godot` from this folder.
3. Run the main scene.

## iPhone build
Install the Godot iOS export templates, configure an iOS export preset in Godot, then export an Xcode project and sign it with an Apple development team. This repository does not yet contain signing credentials or a finished iOS export preset.

## Not implemented yet
This is a first playable single-player prototype, not a complete CRMP client. It does not include GTA/CRMP proprietary assets, multiplayer networking, server protocol compatibility, accounts, vehicles, missions, or a production-quality Astana map. The city geometry is original placeholder geometry and will need to be replaced with detailed, licensed assets and optimized collision meshes.
