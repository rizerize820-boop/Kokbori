# KOKBORI — Astana prototype

This branch contains a runtime-generated Unity greybox. It is a development prototype, not a finished open-world game.

## What is included

- Central avenue with dashed lane markings and a cross street.
- Ishim river strip and embankment.
- Residential blocks, simple facade windows and courtyards.
- Sidewalks, pedestrian crossing, bus-stop shelter and traffic-light props.
- Street lamps, low-poly trees and an original landmark silhouette.
- Custom low-poly sedan with basic arcade driving.
- Third-person character movement and follow camera.
- Mobile joystick, gas, brake, enter/exit and shop controls.
- Eight capsule pedestrians walking between simple waypoints.
- Placeholder city bus following a rectangular route.
- Mini-market with a test wallet in tenge and purchases of water/snacks.

## Controls

- Move on foot: drag the lower-left joystick.
- Enter or leave the sedan: approach it and tap **ENTER / EXIT**.
- Drive: hold **GAS**; steer with the joystick.
- Slow down or reverse: hold **BRAKE**.
- Approach the mini-market and tap **SHOP** to open the test shop.
- On desktop Editor/Standalone, character movement also supports Horizontal/Vertical input axes.

## Current limitations

- The city is a small blockout made from Unity primitive meshes; it is not a geographically accurate Astana map.
- The sedan is a placeholder, not a production vehicle model.
- Vehicle movement has no wheel physics, traffic, collision damage, fuel, or multiplayer synchronization.
- The bus is decorative route traffic; passengers cannot board it.
- Shop purchases only update prototype counters; there is no persistent save, server economy, or item-use system.
- Pedestrians are simple capsule placeholders.
- No CRMP/Black Russia server compatibility, accounts, missions, or production assets are included.
- The scripts have been committed to GitHub but have not yet been compiled or run in Unity in this workflow.

## Unity setup

Create or open a Unity 2022 LTS (or compatible) 3D project, copy `Unity/Assets/Scripts` into its `Assets/Scripts` folder, then press Play in an empty scene. The bootstrap script creates the prototype scene at runtime. If the project uses the new Input System only, enable the legacy Input Manager or Active Input Handling = Both for the desktop fallback and legacy UI EventSystem.
