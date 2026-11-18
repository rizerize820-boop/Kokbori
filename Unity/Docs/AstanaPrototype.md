# KOKBORI — Astana prototype

This branch contains a runtime-generated Unity greybox. It is a development prototype, not a finished open-world game.

## What is included

- Central avenue with dashed lane markings and a cross street.
- Ishim river strip and embankment.
- Repeated residential blocks with simple facade windows and courtyards.\n- Sidewalks, a pedestrian crossing, bus-stop shelter and traffic-light props.
- Street lamps, low-poly trees and an original landmark silhouette.
- A custom low-poly sedan with basic arcade driving.
- Third-person character movement and a follow camera.
- Mobile joystick, gas, brake, enter/exit and shop interaction controls.
- Eight capsule pedestrians walking between simple waypoints.
- A placeholder city bus following a rectangular route.
- A mini-market interaction zone with a mobile **SHOP** button.

## Controls

- Move on foot: drag the lower-left joystick.
- Enter or leave the sedan: approach it and tap **ENTER / EXIT**.
- Drive: hold **GAS**; steer with the joystick.
- Slow down or reverse: hold **BRAKE**.
- On desktop Editor/Standalone, character movement also supports the Horizontal/Vertical input axes.

## Current limitations

- The city is a small blockout made from Unity primitive meshes; it is not a geographically accurate Astana map.
- The sedan now uses a custom low-poly mesh plus primitive detail parts; it is still a placeholder, not a production vehicle model.
- Vehicle movement has no wheel physics, traffic, collision damage, fuel, or multiplayer synchronization.
- No CRMP/Black Russia server compatibility, accounts, economy, missions, or production assets are included.
- Pedestrians, bus and shop are greybox placeholders; there is no passenger boarding, NPC dialogue, shop inventory or economy.
- The scripts have been committed to GitHub but have not yet been compiled or run in Unity in this workflow.

## Unity setup

Create or open a Unity 2022 LTS (or compatible) 3D project, copy `Unity/Assets/Scripts` into its `Assets/Scripts` folder, then press Play in an empty scene. The bootstrap script creates the prototype scene at runtime. If the project uses the new Input System only, enable the legacy Input Manager or Active Input Handling = Both for the desktop fallback and legacy UI EventSystem.
