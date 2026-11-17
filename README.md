# KOKBORI RP

Flutter source project for the KOKBORI RP iPhone launcher prototype.

## What's included

- Dark black-and-gold interface with turquoise accents
- Home screen
- Map placeholder
- Player profile screen
- Settings screen
- GitHub Actions workflow for building an unsigned iOS IPA

## Build an IPA with GitHub Actions

1. Open the repository on GitHub.
2. Select **Actions**.
3. Select **Build KOKBORI iOS IPA**.
4. Press **Run workflow** and confirm.
5. When the workflow finishes, open its run and download the artifact named **KOKBORI-RP-unsigned-IPA**.

## Important: signing is still required

The workflow produces an **unsigned** IPA. iPhones normally require an appropriately signed app before installation. For distribution to your own devices or testers, configure Apple signing with a valid Apple Developer account, certificate, and provisioning profile.

## Game client status

This repository contains the launcher UI prototype only. It does not contain a SA-MP/CRMP game engine, multiplayer protocol implementation, or server connection. The Play button is intentionally a placeholder until a compatible game client is legally available and integrated.
