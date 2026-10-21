<div align="center">
<br>
<img src="assets/app-icon.svg" width="160" />
</div>

<div align="center">

# Sayboard

</div>

<p align="center">
  This repository contains the complete source code of Sayboard — privacy-first voice keyboard for iPhone and iPad. All speech recognition runs on-device with no servers, no accounts, and no tracking.
</p>

<p align="center">
  <a href="https://apps.apple.com/app/id6760622185">
    <img src="assets/app-store-badge.svg" alt="Download on the App Store" width="180" />
  </a>
</p>

## Features

| Dark Mode                                                          | Light Mode                                                           |
| ------------------------------------------------------------------ | -------------------------------------------------------------------- |
| <img src="assets/keyboard-dark.png" alt="Dark Mode" width="400" /> | <img src="assets/keyboard-light.png" alt="Light Mode" width="400" /> |

- On-device speech recognition with multiple engines (WhisperKit, Moonshine, Parakeet)
- On-device LLM text processing: grammar correction, tone adjustment, rewriting
- Works as a system keyboard for voice dictation in any app
- 90+ languages with automatic language detection
- Fully offline — no internet required
- No analytics, no tracking, no accounts, no data collection

| <img src="assets/screenshot-1.png" alt="Text Processing" width="200" /> | <img src="assets/screenshot-2.png" alt="Privacy & Pricing" width="200" /> | <img src="assets/screenshot-3.png" alt="Writing Style" width="200" /> | <img src="assets/screenshot-4.png" alt="Local AI Models" width="200" /> |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------- |

## Supported Languages

Sayboard supports 90+ languages with automatic language detection:

🇦🇫 🇦🇱 🇦🇩 🇦🇲 🇦🇿 🇧🇩 🇧🇾 🇧🇦 🇧🇬 🇰🇭 <br />
🇨🇳 🇨🇩 🇭🇷 🇨🇿 🇩🇰 🇪🇪 🇪🇹 🇫🇴 🇫🇮 🇫🇷 <br />
🇬🇪 🇩🇪 🇬🇷 🇭🇹 🇭🇰 🇭🇺 🇮🇸 🇮🇳 🇮🇩 🇮🇷 <br />
🇮🇱 🇮🇹 🇯🇵 🇰🇿 🇰🇷 🇱🇦 🇱🇻 🇱🇹 🇱🇺 🇲🇰 <br />
🇲🇬 🇲🇾 🇲🇹 🇲🇳 🇲🇲 🇳🇵 🇳🇱 🇳🇿 🇳🇬 🇳🇴 <br />
🇵🇰 🇵🇭 🇵🇱 🇵🇹 🇷🇴 🇷🇺 🇸🇦 🇷🇸 🇸🇰 🇸🇮 <br />
🇸🇴 🇿🇦 🇪🇸 🇱🇰 🇸🇪 🇹🇯 🇹🇿 🇹🇭 🇹🇲 🇹🇷 <br />
🇺🇦 🇺🇸 🇺🇿 🇻🇦 🇻🇳 🏴󠁧󠁢󠁷󠁬󠁳󠁿 🇿🇼 🏳️ <br />

## Building

### Personal iPhone build from Linux

You can build on GitHub's macOS runner and sign locally on Fedora without owning a Mac.
This route targets **iloader 2.3.10**, including its App Group and bundle ID rewriting.
It builds the unlimited `Release` configuration, not the App Store purchase configuration.

1. Fork this repository, open **Actions → Personal iPhone build → Run workflow**,
   and wait for the build and tests to pass. The workflow uses Xcode 26.2 on `macos-26`;
   building with an older SDK does not require downgrading your phone's iOS.
2. Download and extract the `Sayboard-personal-<revision>` artifact. Check the IPA
   with `sha256sum -c Sayboard.ipa.sha256` from the extracted directory.
   Build logs, effective build settings, source revision, and test results are included.
3. Download the x86_64 Fedora RPM from the
   [official iloader releases](https://github.com/nab138/iloader/releases/tag/v2.3.10),
   then install it with `sudo dnf install ./iloader-linux-x86_64.rpm`.
   Install `usbmuxd` too if it is missing.
4. Connect your unlocked iPhone over USB and accept **Trust This Computer**.
   Enable **Settings → Privacy & Security → Developer Mode**, restarting if requested.
5. Open iloader, sign in with your Apple account, choose **Import IPA**, and select
   `Sayboard.ipa`. Keep the **SayboardKeyboard** extension when installing.
   If an increased-memory option is available, enable it only if provisioning supports it;
   otherwise start with a small speech model under the normal memory budget.
6. If requested, trust your developer identity in **Settings → General → VPN & Device Management**.
   Launch Sayboard, allow microphone access, and follow onboarding to enable the
   keyboard and **Allow Full Access**. Download a small speech model before testing offline.

Apple credentials and certificates stay in your local signing tool; the workflow needs
no Apple secrets. A free account's provisioning profiles expire after seven days.
Use iloader to re-sign and reinstall **before expiry**, keeping the same Apple account
and app identifiers. Do not uninstall the app to refresh it, because that can delete data.

Before relying on the install, verify dictation into Notes, shared settings, offline use,
launch without a debugger, and a re-sign/reinstall that preserves your models and history.
Installation and refresh on a particular iOS release, including iOS 27.2, require a real-device
test. If App Group provisioning fails, the keyboard cannot share transcriptions: keep the
exact iloader error and resolve signing rather than removing the keyboard or shared group.

The `SAYBOARD_SIDELOAD` compilation condition uses iloader's shared group,
`group.<signed app bundle ID>`, in both targets. Other builds retain the original group.
Keyboard detection reads the embedded extension's actual bundle identifier. Use this IPA
with iloader; other signing tools may use a different App Group naming scheme.

#### Transfer to SideStore for refreshes on the iPhone

Use **Sayboard-SideStore.ipa**, not the unsigned `Sayboard.ipa`. The SideStore IPA
declares `group.app.sayboard` in both targets' ad-hoc signatures. SideStore appends
your team ID, producing the same `group.app.sayboard.<team>` shared container as
iloader. Its final app ID must remain `app.sayboard.<team>` and its keyboard ID
`app.sayboard.<team>.keyboard`. Keep the same Apple account and team, keep SideStore's
team-ID suffix enabled, and do not uninstall Sayboard.

The normal build workflow produces both IPA variants. To prepare the SideStore
variant from an already-tested build without recompiling, run **Actions → Prepare
SideStore transfer** and enter the successful **Personal iPhone build** run ID.
This checks the source matches the tested app, verifies its checksum, adds App Group
metadata, verifies the signatures and unchanged app/keyboard instruction sections,
and uploads `Sayboard-SideStore-<revision>`. No Apple credentials are used in CI.

After setting up SideStore, its pairing file, and LocalDevVPN:

1. Copy `Sayboard-SideStore.ipa` to Files on the iPhone using a private transfer
   such as USB or your own file service. Do not use iloader to install this variant;
   import it from SideStore so SideStore tracks and refreshes it.
2. Connect LocalDevVPN, open **SideStore → My Apps → +**, and import the IPA.
   Retain **SayboardKeyboard** and keep the existing bundle IDs and team-ID suffix.
3. Confirm Sayboard replaces the existing app. Check the downloaded model, settings,
   history, and dictation in Notes. Refresh Sayboard once in SideStore and repeat
   the checks before relying on phone-only renewal.
4. Every 5–6 days, connect LocalDevVPN and use **Refresh All**, including SideStore
   itself. A working pairing file and local device connection are required.

If SideStore proposes a different app identity or the shared data disappears, stop
and retain both installs. The original `Sayboard.ipa` remains the rollback artifact:
reinstall it through iloader with the original account without deleting Sayboard.
SideStore authentication and pairing compatibility depend on its version; use the
[official releases](https://github.com/SideStore/SideStore/releases) and check their
current warnings rather than assuming an older Stable release still signs in.

For the same build on a Mac: install XcodeGen, select Xcode, and run
`bash scripts/build-sideload.sh`. The unsigned IPA is written to `build/sideload/Sayboard.ipa`.

### Build directly on a Mac

To get started, you need a [Mac](https://www.apple.com/mac/), [Xcode](https://developer.apple.com/xcode/) 16.4+ (iOS 17.0+ deployment target), and a (free) [Apple Developer Account](https://developer.apple.com/programs/).

### 1. Install Dependencies

1. If your Xcode installation is fresh, make sure that command line tools are selected:

   ```sh
   sudo xcode-select --switch /Applications/Xcode.app
   ```

2. Install the tools needed to build the project:

   ```sh
   brew install xcodegen swiftformat swiftlint
   ```

   (If you don't have [Homebrew](https://brew.sh), see their [official install instructions](https://brew.sh).)

3. Download the llama.cpp XCFramework (required for on-device LLM features):

   ```sh
   ./scripts/bootstrap-llama.sh
   ```

### 2. Setup Project

1. Generate the Xcode project from `project.yml`:

   ```sh
   xcodegen generate
   ```

2. Open `Sayboard.xcodeproj` in Xcode

3. For both the `Sayboard` and `SayboardKeyboard` targets:
   1. Set "Team" to the team of your developer account under Signing & Capabilities

4. Choose `Sayboard` as scheme and a simulator

### 3. Build and Run

1. Build and Run (Cmd+R)

A build you make yourself is the full app: Run, Test and the Release configuration have no purchase screen and no limit on dictation. The App Store version gives 3,000 free words of dictation and then asks for a one-time purchase. That purchase is a way to support Sayboard's development, and if you can't or would rather not pay, building it yourself is free and always will be.

In the `Sayboard` scheme, only Product › Archive uses the `AppStore` configuration, which compiles the purchase code. To archive a build for your own devices, set `config: Release` under `schemes` › `Sayboard` › `archive` in `project.yml` and run `xcodegen generate` again; a change made in Xcode's scheme editor is lost on the next generate. Otherwise the archive treats your install as a free App Store download, and your own bundle ID has no purchase that could unlock it. The `Sayboard StoreKit` scheme builds that App Store version for Run, Profile, Analyze and Archive, and runs the purchase flow locally against `StoreKit/Sayboard.storekit`.

## Bug Reports and Questions

Settings has a Report a Problem section that opens either a prefilled GitHub issue or a prefilled email, whichever you prefer. Both carry the app version, the iOS version and the device identifier, so the report arrives ready to work on.

You can also write directly to [support@sayboard.app](mailto:support@sayboard.app).

Sayboard doesn't collect any analytics or telemetry, so we rely on your feedback to find and fix problems.

## Source Code Release Policy

This source code repository will be updated for every public non-beta release. There will be one commit per released version.

## Contributions

We welcome contributions via GitHub pull requests. For bug fixes and small improvements, feel free to open a PR directly. For larger changes, please open an issue first to discuss the approach.

## License

Sayboard is licensed under the [GNU General Public License v3](LICENSE).

    Copyright (c) 2025 Sayboard
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <https://www.gnu.org/licenses/>.

We are publishing the source code in good faith, with transparency being the main goal. By having users pay for the development of the app, we can ensure that our goals sustainably align with the goals of our users: great privacy and security, no ads, no collection of user data.
