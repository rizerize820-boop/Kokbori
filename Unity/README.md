# KOKBORI RP — Unity foundation

This branch starts the Unity-based Kazakhstan RP client while keeping the existing Godot prototype on main untouched.

## Scope of this milestone
- Unity project structure and mobile-first C# starter scripts.
- Third-person character movement and camera follow.
- On-screen touch joystick input abstraction.
- A setup guide for creating the first playable Astana greybox scene.

This is a foundation, not a finished Black Russia-scale game. It does not yet include multiplayer, vehicles, a finished city, accounts, economy, or production assets.

## Requirements
- Unity 2022.3 LTS or newer compatible LTS.
- Android Build Support / iOS Build Support modules for local builds.
- iOS installation still requires valid Apple signing and provisioning.

## First scene
Create a 3D URP project, copy the scripts from `Assets/Scripts`, create a Plane for the ground, add a Capsule with a CharacterController, attach `KokboriPlayerController`, and assign a camera with `KokboriCameraFollow`. Add a Canvas with a joystick UI and connect its pointer events to `KokboriVirtualJoystick`.

See `Unity/Docs/FirstScene.md`.
