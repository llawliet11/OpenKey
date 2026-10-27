---
name: ci-policy
description: Never adds always-on CI, pipelines, background sweeps or release checks unless the owner asks; during development runs only the build the current task needs, and removes every build output, temp dir and process a run creates. Holds the on-demand promotion and release check for OpenKey CE (macOS). Use when the owner says "run full checks", "release check", "promote to master", "chay full check", "kiem tra truoc khi release", "them CI". The model never invokes it on its own: when a situation matches, it says so in one line at the end of the coding reply and invokes it only after the owner says yes in that turn, or when a /goal prompt or a standing grant in the owner's message already covers it.
---

# ci-policy

## Policy

- No CI runs continuously in the normal dev flow. Promotion-grade verification (full build, release build, signing checks) runs only when promoting to `master`, preparing a release, or on explicit request, as an on-demand command, never after each change or commit.
- `.github/workflows/msbuild.yml` runs only by hand (`workflow_dispatch`), per the owner's decision of 2026-10-27 (D1-A: the Windows build is not needed). It is never triggered by a session unless the owner asks in that turn.
- Interactive session: before a check, name the exact command, what it touches (Xcode build cache, network for notarization) and roughly how long it takes, and wait for the owner's yes.
- Unattended run (`/goal`, a standing grant, `cyberine autopilot`, `cyberine run`, and every agent they spawn): per task, run the narrowest check below that covers the change, without asking. The promotion check runs once on the integrated state before the run ends only when the starting message names it, and only in the driving session or its review step; otherwise it is offered as plain text in the end-of-run report. Release steps (signing with notarization submit, tag, GitHub Release, `version.json` bump on `master`) are never run unattended unless the owner lifted that gate for the session; this repo has no owner-written tracked rule that pre-authorizes them.
- `.claude/rules/user-vibe-coding.md` (owner-installed, gitignored) pre-authorizes commit, push and merge in this repo; it does not cover releases or deploys, and it says a push that auto-deploys is stated as a deploy first.

## Promotion check

Run from the repo root, narrowest first. There is no lint, typecheck-only or test target in this repo (see `test-policy`).

1. Debug build of the app (compile check, active arch only, Xcode's default DerivedData):
   `xcodebuild -project Sources/OpenKey/macOS/OpenKey.xcodeproj -scheme OpenKey -configuration Debug build -quiet`
2. Universal Release build, the same build `release.sh` makes, without signing:
   `cd Sources/OpenKey/macOS && xcodebuild -project OpenKey.xcodeproj -scheme OpenKey -configuration Release -derivedDataPath build/dd ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build -quiet`

Release steps, each needing the owner's word in that turn:

3. Sign, notarize, staple, package: `NOTARY_PROFILE=<notarytool profile> Sources/OpenKey/macOS/release.sh`. It deletes and recreates `Sources/OpenKey/macOS/build/`, signs with the first `Developer ID Application` identity in the keychain (or `DEVELOPER_ID_IDENTITY`), submits the app zip and the DMG to Apple notarization (`xcrun notarytool submit --wait`), staples both, checks with `spctl`, and prints SHA-256 of `OpenKey-CE-<version>.zip` and `.dmg`. Signing, notarization and timestamping are release mechanics: no retention rule.
4. Tag `v<version>-ce` and publish a GitHub Release with the DMG and ZIP. The repo has no script for this step: the command is the owner's choice. Release notes drafts live in `.local/releases/`.
5. Bump `latestMacCEVersion` (`versionName`, `versionCode`) in `version.json` on `master`. The installed app reads `https://raw.githubusercontent.com/llawliet11/OpenKey/master/version.json` (`Sources/OpenKey/macOS/ModernKey/OpenKeyManager.m`, update check) and prompts every user whose `CFBundleVersion` is lower, so this push is a publish to users, stated as such before it happens.

## Existing CI

List it with `ls .github/workflows`.

- `.github/workflows/msbuild.yml` (MSBuild): triggers on `workflow_dispatch` only. Builds the Windows solution under `Sources/OpenKey/win32/OpenKey` (x86 and x64) on `windows-latest`, uploads the artifact `OpenKey` with `retention-days: 1`, then an `attest` job writes build provenance (`actions/attest-build-provenance`). It does not build the macOS app that OpenKey CE ships. No conflict with the policy.
- No hooks run checks on change: no `.husky`, `lefthook`, `pre-commit` config, and no `package.json`.

## Cleanup

- Local run artefacts only; remote and billable ones belong to `resources-policy`.
- Build output lives in one reused place per kind: Xcode's default DerivedData for Debug builds (clear with `rm -rf ~/Library/Developer/Xcode/DerivedData/OpenKey-*`), and `Sources/OpenKey/macOS/build/` for Release builds (gitignored; `release.sh` recreates it each run). Never a new derived-data path per run, branch or worktree.
- `Sources/OpenKey/macOS/build/` can hold the last shipped DMG and ZIP: check before removing it (`ls Sources/OpenKey/macOS/build`).
- Anything a run creates for itself (temp dirs, worktrees, processes) is removed when it ends. Processes are stopped only by a PID this run started and recorded, never by name, pattern or port. No LaunchAgent, login item, cron entry or `caffeinate` outlives the run; the end-of-run report lists any it could not remove, with the removal command. A removal a guard blocks is reported with the exact command.
- This repo has no Docker setup; if one is added, Docker commands act only on this run's compose project, throwaway stacks go down with `docker compose down -v`, and `docker system prune` / `docker volume prune` are never run.

## Scope

Change only this project. A change needed elsewhere goes to its owner as a handoff.
