# KOKBORI RP

Native SwiftUI iOS launcher project.

## Project layout

- `Native/project.yml` — XcodeGen project definition.
- `Native/Sources` — SwiftUI app, launcher view model, remote configuration, SA-MP query, external-client URL handoff, and verified resource updater.
- `lib/main.dart` — retained Flutter prototype; it is no longer used by the native IPA workflow.
- `.github/workflows/build-ios-ipa.yml` — builds the native iOS app and packages an unsigned IPA.

## Build an IPA with GitHub Actions

1. Open **Actions** in this repository.
2. Select **Build KOKBORI Native iOS IPA**.
3. Press **Run workflow**.
4. When the run completes, download **KOKBORI-RP-unsigned-IPA** from its Artifacts section.

The workflow installs XcodeGen, generates the Xcode project from `Native/project.yml`, builds for iPhoneOS, and packages the app.

## Configure the launcher

The launcher reads its remote configuration from `launcher/config.json` in this repository over HTTPS. Update that file to change news, servers, manifest URL, or launcher update metadata. The config JSON uses `launcherVersion`, `updateUrl`, `news`, `manifestUrl`, and `servers`.

Manifest entries must contain a relative path, HTTPS URL, 64-character SHA-256 digest, and positive file size. Downloaded files are verified before being moved into the app's Application Support directory.

The initial configuration points to the test server supplied for this project (`80.242.59.112:6709`). Server query results depend on the server using a compatible SA-MP query protocol; a timeout does not prove the game server itself is offline.

## Game client integration

The launcher hands off to an installed external app using the `crmpclient://connect` URL scheme and passes nickname, host, and port. The target game client must register that URL scheme and implement those parameters itself. This repository does not include a SA-MP/CRMP game engine or a compatible multiplayer client. The Astana map cannot be entered until a compatible game runtime is integrated and the server protocol is confirmed.

## Signing

The GitHub Actions artifact is an **unsigned IPA**. Installing it on a normal iPhone requires signing with a valid Apple development/distribution identity and provisioning profile. Building the launcher does not sign or supply the external game client.


## Godot game runtime prototype

The first playable Godot 4 prototype is in [Engine/](Engine/README.md). It contains a third-person player controller, a mobile touch joystick, and a procedurally generated placeholder district inspired by Astana. It is a separate game runtime project and is not yet embedded in the SwiftUI launcher. Multiplayer and CRMP server compatibility are not implemented.
