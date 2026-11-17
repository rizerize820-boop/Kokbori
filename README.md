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

Before using remote features, replace `https://example.com/launcher/config.json` in `Native/Sources/Config.swift` with the real HTTPS config URL. The config JSON uses `launcherVersion`, `updateUrl`, `news`, `manifestUrl`, and `servers`.

Manifest entries must contain a relative path, HTTPS URL, 64-character SHA-256 digest, and positive file size. Downloaded files are verified before being moved into the app's Application Support directory.

The fallback server addresses are local test placeholders, not public KOKBORI servers.

## Game client integration

The launcher hands off to an installed external app using the `crmpclient://connect` URL scheme and passes nickname, host, and port. The target game client must register that URL scheme and implement those parameters itself. This repository does not include a SA-MP/CRMP game engine or a compatible multiplayer client.

## Signing

The GitHub Actions artifact is an **unsigned IPA**. Installing it on a normal iPhone requires signing with a valid Apple development/distribution identity and provisioning profile. Building the launcher does not sign or supply the external game client.
