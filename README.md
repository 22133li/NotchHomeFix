# NotchHomeFix

Experimental source-level reimplementation based on static analysis of NotchHome 0.5.0. This is not recovered original source code.

## What it changes

The original binary contains a SpringBoard animation path gated by its own `startedAtHome` state, home-layout checks, and icon geometry. This independent implementation can only track transition callbacks and broaden two runtime eligibility queries. It cannot set the original plugin's private state or reproduce its icon-frame, corner-radius, opacity, and animation-attribute logic. Consequently, a successful build does not establish that non-Home-Screen launches are fixed; this is a prototype for device testing, not a verified fix.

The package targets iOS 15.4 and arm64e, and its GitHub Actions workflow builds a Roothide package. The package conflicts with and replaces `com.tsangbaby.notchhome` to avoid duplicate hooks.

## GitHub build

1. Create an empty GitHub repository and upload the contents of this project archive to its `main` branch.
2. Open Actions and run `Build NotchHomeFix`, or push a commit to `main`.
3. Download the `packages-roothide` artifact from the completed workflow. A release is also created by the workflow.

The workflow uses a macOS runner, Xcode 15.4, iPhoneOS 16.5 SDK, and the Roothide Theos toolchain. A successful CI build only confirms compilation and packaging; it does not confirm SpringBoard runtime compatibility.

## Validation status

- Theos project structure and local references: checked.
- Build and signing: not run in this environment.
- iOS 15.4 / iPhone 13 Pro Max / RootHide runtime test: not run.

Install only after keeping a way to remove the tweak from the jailbreak environment if SpringBoard fails to start. Test Home Screen, folder, Dock, App Library, and Search launches separately.
