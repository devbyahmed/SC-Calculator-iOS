# SC Calculator

A private iPhone app disguised as a calculator.

The app is named **SC Calculator** on your Home Screen. Inside the project the code is still called `Numo` (folders, Xcode target, `.ipa`); nobody sees that name.

- **Outside:** SC Calculator is a full scientific calculator: whole expressions, brackets, trig (degrees/radians), logs, powers and roots, factorial, EE, Ans, and a history of past calculations.
- **Inside:** type your secret code and press **=**, then Face ID opens **Apps**: your hidden apps in a Home Screen–style grid, sorted into groups, each one tap to open.
- **Design:** built from Apple's own components (system colors, San Francisco, grouped lists, sheets, toolbars) following the Human Interface Guidelines, so it picks up Liquid Glass on iOS 26.
- **Decoy code:** a second code opens a separate, harmless-looking space.
- **Disguise icons:** Calculator, Notes, Weather or Compass, switchable in Settings.
- **Hide Guide:** step-by-step help to hide apps with iOS's own **Hide and Require Face ID**, and to hide them on a schedule with Focus.

Built for personal use with a **free Apple ID** (no $99 developer account).

---

## How the hiding works (and why)

With a free Apple ID, an app is not allowed to hide other apps. That needs Apple's Screen Time permission, which only paid developer accounts can use. So the work is split:

| Who | Does what |
| --- | --- |
| **iOS 18+** (free, built in) | Long-press an app → **Require Face ID** → **Hide and Require Face ID**. The app vanishes from the Home Screen and search, and its notifications are hidden. |
| **Focus modes** (free, built in) | Hide whole Home Screen pages on a schedule, e.g. weekdays 9–6, or with one tap from Control Center. |
| **SC Calculator** | The disguise: a calculator with your code, Face ID, a decoy space, and one-tap tiles that open your hidden apps. |

Tiles open apps through their link (e.g. `whatsapp://`). For apps without a link, the tile runs a Shortcut that has a single **Open App** action. Both are explained in the app's Hide Guide.

---

## Build and install on your iPhone (free Apple ID)

You need: a Mac with **Xcode 16 or newer** (Xcode 26 gives the full Liquid Glass look), an iPhone on **iOS 18+**, and a USB cable.

### 1. Copy the project to your Mac
Copy the whole `Numo` folder over, for example with a USB stick, a cloud drive, or a private Git repository.

### 2. Generate the Xcode project
```bash
brew install xcodegen
```
```bash
cd ~/path/to/Numo && xcodegen
```
This creates `Numo.xcodeproj`. If you change `project.yml`, run `xcodegen` again.

### 3. Set up signing
1. Open `Numo.xcodeproj` in Xcode.
2. **Xcode › Settings › Accounts**: add your Apple ID. This creates a free "Personal Team".
3. Select the **Numo** target › **Signing & Capabilities**:
   - **Team:** *Your Name (Personal Team)*
   - **Bundle Identifier:** change `com.example.numo` to something unique, e.g. `com.yourname.numo`. To keep this setting, also change it in `project.yml`.

### 4. Run it on your iPhone
1. Plug in the iPhone and choose it as the run destination in Xcode.
2. On the iPhone: **Settings › Privacy & Security › Developer Mode** › On (the phone restarts).
3. Press **Run** (▶) in Xcode.
4. The first time, the iPhone will say the developer isn't trusted: go to **Settings › General › VPN & Device Management**, tap your Apple ID, then **Trust**.

### 5. Every 7 days
Apps installed with a free Apple ID stop opening after 7 days. Plug in and press **Run** again. Your codes, tiles and groups are kept.
Free accounts can also have only **3** of their own apps installed at a time.

### Optional: sideload an `.ipa` instead
To install without Xcode each week, build an unsigned `.ipa` on the Mac:
```bash
sh scripts/build-ipa.sh
```
Then install `build/Numo.ipa` with a sideloading tool such as **SideStore** or **AltStore**. These sign it with your free Apple ID, and SideStore can renew the 7-day signing on the phone itself. Free-account limits still apply.

---

## First launch

1. SC Calculator shows a welcome screen. Pick a **secret code** (4–8 digits) and confirm it.
2. Optionally set a **decoy code**.
3. From then on SC Calculator opens as a calculator. Type your code and press **=** to get in.
4. Open **Hide Guide** in Apps and hide your apps.
5. To set up the decoy space: lock, type the decoy code, and add a few harmless apps so it looks real.

SC Calculator locks itself whenever you leave the app. The 🔒 button locks it right away.

---

## Project layout

```
project.yml                 XcodeGen spec (bundle id, icons, Info.plist)
Numo/
  App/                      App entry, screen switching, lock/unlock
  Calculator/               Calculator engine + disguise screen
  Setup/                    First-run flow, code entry keypad
  Vault/                    Apps screen, tile editor, Hide Guide
  Settings/                 Icon picker, codes, groups, erase
  Services/                 Keychain codes, Face ID, icon switching, storage
  Models/                   Tiles, groups, popular app links
  Design/                   Apple system styling
  Assets.xcassets/          App icons (generated by scripts/make-icons.ps1)
scripts/
  build-ipa.sh              Unsigned .ipa for sideloading (run on Mac)
  make-icons.ps1            Redraws the disguise icons (run on Windows)
```

**Security notes:** codes are stored only as salted SHA-256 hashes in the Keychain (this device only). Tiles are saved with iOS file protection. Face ID falls back to your iPhone passcode.

---

## If you get a paid developer account later

With the paid account ($99/yr), SC Calculator could hide and unhide apps itself through Apple's Screen Time API, including automatic schedules. That would be added as a new module; nothing here needs to be rewritten.
