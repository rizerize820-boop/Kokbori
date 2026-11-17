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

An iOS export preset is included. It targets iPhone (iOS 16+) and exports an **unsigned Xcode project**; no certificate, private key, provisioning profile, or password is stored in this repository.

1. Open **Actions → Export KOKBORI iOS Xcode Project → Run workflow**.
2. Enter your 10-character Apple Team ID in the workflow input. This is an identifier, not a signing certificate or private key.
3. Download the `KOKBORI-iOS-Xcode-Project` artifact and extract it.
4. Open the generated `.xcodeproj` in Xcode on a Mac, select your own signing team/profile, and build/install it from your Mac.

The workflow does not sign the app and does not create a ready-to-install IPA. You perform signing locally in Xcode with your own credentials. The iOS export requires macOS/Xcode and the matching Godot 4.3 export templates.

## Not implemented yet
This is a first playable single-player prototype, not a complete CRMP client. It does not include GTA/CRMP proprietary assets, multiplayer networking, server protocol compatibility, accounts, vehicles, missions, or a production-quality Astana map. The city geometry is original placeholder geometry and will need to be replaced with detailed, licensed assets and optimized collision meshes.

## iPhone browser playtest

A Web export preset is included in `export_presets.cfg`. GitHub Actions can package a browser build without an Apple Team ID:

1. Open the repository's **Actions** tab.
2. Select **Build KOKBORI Web Playtest** and run the workflow (or wait for a push to `Engine/**`).
3. Download the `KOKBORI-Web-Playtest` artifact and extract it.
4. Host the extracted files on a static HTTPS host, then open its `index.html` URL in Safari on the iPhone.

The web build is a browser test build, not an installed iOS app. Browser support and touch behavior still need to be tested on the actual iPhone. This workflow does not publish the build to a public website automatically.

