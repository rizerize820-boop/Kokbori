# First playable scene — Astana greybox

1. Create a Unity 3D URP project (Unity 2022.3 LTS recommended).
2. Copy `Unity/Assets/Scripts` into the project's `Assets/Scripts`.
3. Create a Plane named `Ground`, scale it to (8, 1, 8), and add a few Cube primitives as placeholder buildings.
4. Create a Capsule named `Player`; add a CharacterController and KokboriPlayerController.
5. Create a Camera, attach KokboriCameraFollow, and assign Player as its target. Assign that camera transform to the player controller.
6. Create a Canvas (Screen Space Overlay), add a circular joystick background and handle, attach KokboriVirtualJoystick to the background, and assign both RectTransforms.
7. Assign the joystick to KokboriPlayerController. Ensure an EventSystem exists in the scene.
8. Press Play and test keyboard input in the editor; test touch input on a device build.

## Kazakhstan visual direction
Use original or properly licensed assets. Start with a compact greybox inspired by Astana's wide avenues, residential courtyards, river embankment, and recognizable skyline silhouettes. Do not copy Black Russia's maps, UI artwork, models, sounds, or proprietary assets.

## Next milestones
- Third-person animation controller and character customization.
- Vehicle prototype and enter/exit flow.
- Small optimized Astana district.
- Authoritative multiplayer server and persistence (after the offline loop is stable).
