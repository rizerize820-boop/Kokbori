# KOKBORI Engine — browser playtest

A small original Godot 4 project intended as the future 3D runtime for KOKBORI RP on iPhone.

## Current prototype
- Third-person character with a spring-arm camera.
- Walking and collision.
- Touch joystick for mobile and WASD/arrow-key input for desktop.
- Procedurally generated placeholder city blocks, roads, sidewalks, a river channel, and a Baiterek-inspired landmark.
- Godot Compatibility renderer, selected so the Web export can run in Safari.
- Web export configured with Progressive Web App support.

## iPhone playtest

The repository workflow **Publish KOKBORI Browser Playtest** builds the Web version and attempts to publish it to GitHub Pages whenever `Engine/**` changes on `unity-foundation` or `main`.

After a successful deployment, open the Pages URL shown in the workflow's **deploy** job on your iPhone:
1. Open the link in Safari.
2. Rotate to landscape if the game view is cramped.
3. Use the on-screen joystick to move.
4. In Safari's Share menu, choose **Add to Home Screen** to create a launcher icon.

The first load may take a little while because the browser downloads the game files. PWA/offline behavior depends on Safari's cache and should be treated as experimental.

If deployment fails because GitHub Pages is not enabled for the repository, the repository owner must enable **Settings → Pages → Build and deployment → GitHub Actions**, then rerun the workflow. No Apple Developer subscription is needed for the browser build.

## Run locally
1. Install Godot 4.3 or newer.
2. Import `project.godot` from this folder.
3. Run the main scene.

## Native iOS build

A native iOS export still requires macOS, Xcode, an Apple Team ID, and signing/provisioning. This repository does not contain signing certificates, private keys, provisioning profiles, or passwords. Do not upload those credentials to GitHub.

## Not implemented yet

This is an early single-player prototype, not a complete CRMP client or online RP game. It does not yet include multiplayer networking, PAWN server integration, accounts, vehicles, missions, or a detailed Astana map. The city geometry is original placeholder geometry and must be expanded with optimized, properly licensed assets.
