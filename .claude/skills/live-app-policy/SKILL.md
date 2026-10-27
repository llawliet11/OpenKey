---
name: live-app-policy
description: Never quits, relaunches, focuses, resizes or reinstalls the owner's running OpenKey CE more than once per task without the owner's yes in that turn; repeated launches for measurement or debugging run on a separate copy. States how a session builds, installs, relaunches and measures the app without breaking the owner's typing. Use when the owner says "relaunch the app", "install and restart", "measure startup time", "khoi dong lai app", "cai lai app", "do thoi gian mo app". The model never invokes it on its own: when a situation matches, it says so in one line at the end of the coding reply and invokes it only after the owner says yes in that turn, or when a /goal prompt or a standing grant in the owner's message already covers it.
---

# live-app-policy

## Policy

- OpenKey CE is the owner's Vietnamese input method: while it runs, every keystroke the owner types passes through it. The installed, running instance is a shared, in-use resource, not a test binary. Quitting, relaunching, stealing focus from, resizing or moving its windows, reinstalling it, and writing to its defaults domain all touch it.
- One relaunch per install, announced in the reply before it happens, is free when the task asks for an install. Anything more (a measurement loop, a debug cycle, a bisect) needs the owner's yes in that turn with a stated count and time window ("6 relaunches, until 15:10"); in an unattended run it is never done on the owner's instance.
- Disruption budget: at most 2 owner-instance relaunches per turn, unless the owner raises it in that turn. At the cap, stop that line of work and report.
- Repeated launches run on a copy with its own bundle id, app name, install path and defaults domain. The copy is the Debug build `OpenKey CE Dev` (see `## Separate copy`).
- An owner-ordered install on the owner's instance follows one path: the owner's word in this turn; a backup of `/Applications/OpenKey CE.app` and of its defaults (`defaults export com.nghia-pham.openkey-ce .local/live-app/<date>-defaults.plist`); an identity check of the new build (`CFBundleIdentifier`, `CFBundleShortVersionString`, `CFBundleVersion` via `/usr/libexec/PlistBuddy`); a quit by PID; the relaunch; a check that the running PID is the new binary; and the rollback command (restore the backed-up `.app`) stated before starting.
- cyberine-devguard's `live_guard` backs this up: broad `pkill`/`killall` are denied, narrower kills by name or port ask, and relaunches past its limit are denied. Work with recorded PIDs.
- Runs that take the owner's mouse, keyboard or screen (computer use, UI automation, typing tests, screen recording) need the owner away and a go-ahead in that turn.
- A session never grants or resets the Accessibility (Device Control and Data Access) permission, and never runs `tccutil reset` for this bundle id: the owner's typing stops until they grant it again.
- Launching any build of this app can quit another app the owner runs: on launch it offers to quit the original OpenKey (`com.tuyenmai.openkey`, `offerToQuitLegacyOpenKey` in `Sources/OpenKey/macOS/ModernKey/AppDelegate.m`). A session never clicks that button.
- Measure, then reason: plan every variant first and run them together in one announced window; prefer one profile (`sample`, Instruments) over edit, rebuild and relaunch per hypothesis.
- Before changing window, frame or persisted-UI setup code, back up the defaults domain as above, check it after the first launch, and restore from the backup if a launch overwrote it.
- A performance metric ends at something the owner sees (the menu-bar icon shown, a converted character on screen), states that endpoint in the report, and an endpoint change invalidates every earlier comparison.
- Unattended runs: a `/goal` or "do it A-Z" covers the literal request only. A follow-up whose done-when needs repeated launches of the owner's instance becomes an `Owner:` task through `cyberine tasks` with the copy-based plan, never run on the owner's instance.

## App

- Name `OpenKey CE`, bundle id `com.nghia-pham.openkey-ce` for both Debug and Release (`Sources/OpenKey/macOS/OpenKey.xcodeproj/project.pbxproj`, `PRODUCT_BUNDLE_IDENTIFIER`). Version from `MARKETING_VERSION` in the same file.
- Installs at `/Applications/OpenKey CE.app`, by dragging from the DMG that `ci-policy`'s release steps build.
- Build: see `ci-policy` `## Promotion check` (Debug build; Release build; `release.sh` for the signed DMG).
- Launch at login: `SMAppService mainAppService` (`AppDelegate.m`), registered from the app's own setting; no LaunchAgent plist and no helper app.
- Single instance: on launch the app quits itself when another instance with the same bundle id runs for the same user (`applicationDidFinishLaunching` in `AppDelegate.m`).
- Saved state and data: the defaults domain `com.nghia-pham.openkey-ce` (settings and macros); on first launch it imports the original OpenKey's domain (`importLegacyOpenKeySettings` in `Sources/OpenKey/macOS/ModernKey/main.m`).
- Quit and open commands: the repo has no script for either (Owner: decide). Until one exists, a quit is by the PID read and recorded from `pgrep -x "OpenKey CE"`, never by name.

## Separate copy

The Debug configuration builds `OpenKey CE Dev` with bundle id `com.nghia-pham.openkey-ce.dev` (owner decision D3-A, 2026-10-27; `PRODUCT_BUNDLE_IDENTIFIER` and `PRODUCT_NAME` of the Debug config in `Sources/OpenKey/macOS/OpenKey.xcodeproj/project.pbxproj`). It has its own defaults domain `com.nghia-pham.openkey-ce.dev`, its own single-instance check and its own Accessibility grant. Release builds keep the owner's identity.

- Build: the Debug build in `ci-policy` `## Promotion check`. Output: `~/Library/Developer/Xcode/DerivedData/OpenKey-*/Build/Products/Debug/OpenKey CE Dev.app`, run from there, never copied into `/Applications`.
- Launch: `open -n "<that path>"`, recording the PID; quit by that PID.
- Granting the Dev copy Accessibility (Device Control and Data Access) is an owner step; without it the Dev copy shows the permission alert and quits.
- Both apps convert keystrokes when both run with the permission granted, which garbles the owner's typing. A typing test on the Dev copy therefore needs the owner away and their yes in that turn; launch-only checks (start-up, menu bar, settings window) do not.
- On first launch the Dev copy imports the original OpenKey's settings (`com.tuyenmai.openkey`), read-only; it never reads the owner's `com.nghia-pham.openkey-ce` domain.

The copy follows these rules: its visible name carries the `Dev` suffix; it registers no login item; it gets its own Accessibility grant, an owner step; its new bundle id is announced to repos whose allow or deny lists key on bundle ids (computer-use and automation tools); and when its identity changes, the build script deletes the old-identity build output after checking its bundle id.

## Targets

No other live target found: no device, extension, tmux, remote service or disk-write code in the repo (`release.sh` writes only under `Sources/OpenKey/macOS/build/`).

## Cleanup

- Local run artefacts only; remote and billable ones belong to `resources-policy`.
- Backups go to `.local/live-app/` with write-once names (date, topic, host).
- Anything a run creates (copies, temp dirs, processes) is removed when it ends. Processes are stopped only by a PID this run started and recorded, never by name, pattern or port. No login item, LaunchAgent or background process outlives the run; a login item a test build registered is listed in the report with its removal step.

## Scope

Change only this project. A change needed elsewhere goes to its owner as a handoff.
