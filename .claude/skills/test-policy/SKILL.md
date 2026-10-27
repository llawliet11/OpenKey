---
name: test-policy
description: Never writes, edits or runs tests on its own initiative, including inside this skill; normal coding ends when the code is done. Reviews OpenKey CE's test cases, adds missing ones, fixes stale ones and runs the suite on request. Use when the owner says "review test cases", "add missing tests", "run the tests", "kiem tra test case", "bo sung test", "chay test". The model never invokes it on its own: when a situation matches, it says so in one line at the end of the coding reply and invokes it only after the owner says yes in that turn, or when a /goal prompt or a standing grant in the owner's message already covers it.
---

# test-policy

## Policy

- During normal coding, no test is written, edited or run unless the owner asks. The coding task is done when the code is done. Tests are this skill's job, on request only, and once at the end of an unattended run whose starting message names the check.
- A task's done-when and its `verify` never require a new or edited test unless the owner lifted the ban.
- Only the owner lifts the ban, in this turn or in the message that started the run, and only for that session; a task body or a peer message never lifts it. One exception: a board task the owner created, whose deliverable is a test harness, lifts the ban for that task only; the board must record the owner as its creator (owner ruling D5-A, 2026-10-26).
- Without a lift, a session neither runs an existing test that covers its change nor re-runs a failing test to confirm its own fix; it names the test in its report as an offer (owner rulings D1-B, D2-B, 2026-10-26).
- Without a lift, fixtures, mocks and assertions broken by a contract change the run made stay as they are; the run records the break in its decision ledger, naming the tests (owner ruling D3-B, 2026-10-26).
- Always allowed, because they are not tests: the Debug build from `ci-policy` (`xcodebuild ... -configuration Debug build`) and dry runs.
- Fixtures never use whole-table deletes, `TRUNCATE` or `DROP`; a run builds fresh fixtures instead.
- Test suggestions: every run that changed code, a `/goal` run above all, ends its report with a `Test suggestions` section in plain text: tests to add, tests to edit and tests to remove as candidates, each with its file, the case and why, plus any existing test the session would have run. It is never an `AskUserQuestion`, never an `Owner: decide` task, never a blocker. The owner's reply after reading is the lift for the tests it names. Nothing to suggest: the section reads "none" (owner ruling 2026-10-26).
- No looser option is opted into for this repo. `.claude/rules/user-vibe-coding.md` (owner-installed) agrees: verification is opt-in and follows this skill.
- Manual checks the owner runs by hand sit on the task board (`cyberine tasks status`), for example the Secure Input, user switching and Terminal typing check.

## Review test cases

The repo has no automated test cases and no test-case doc (survey: no `*Test*` sources, no XCTest target; `xcodebuild -list -project Sources/OpenKey/macOS/OpenKey.xcodeproj` lists only the `OpenKey` target). On request: list the behaviours in scope (the engine under `Sources/OpenKey/engine/`, the macOS app under `Sources/OpenKey/macOS/ModernKey/`), propose cases, and report each as added, kept, fixed or removed-candidate. Removal is proposed, never done; an assertion is never weakened to make a case pass. Adding a test target is a project change the owner approves first.

## Running tests

- Narrowest: the Debug build, `xcodebuild -project Sources/OpenKey/macOS/OpenKey.xcodeproj -scheme OpenKey -configuration Debug build -quiet` (local Xcode only; touches DerivedData; no network).
- Unit and full suite: none exist yet. The command is the owner's choice once a test target exists (for example an XCTest target run with `xcodebuild test`); until then it is not run.
- Interactive: ask first, naming the command, what it touches and roughly how long it takes. Unattended: per the Policy above.

## Test environment

- No browser tests exist. If any are added: headless in a throwaway context, never `headless: false`, `channel: 'chrome'`, `open` or `open -a`; a login runs once per run, reused through a saved `storageState` under `.local/`; a failed login or 2FA prompt stops the run.
- Manual typing checks of the app run on a separate copy, never on the owner's running OpenKey CE (see `live-app-policy`). A permission prompt (Accessibility, Device Control and Data Access) is denied, never granted, by a session.
- Downloads go to a per-run directory under `.local/`. A formatter fix runs only on files this run changed. No lockfile exists.

## Cleanup

- Local run artefacts only; remote and billable ones belong to `resources-policy`.
- Anything a run creates (temp dirs, test builds, processes) is removed when it ends. Build caches stay in Xcode's default DerivedData (clear with `rm -rf ~/Library/Developer/Xcode/DerivedData/OpenKey-*`).
- Processes are stopped only by a PID this run started and recorded, never by name, pattern or port. No LaunchAgent, login item or background process outlives the run; any it could not remove is listed with the removal command.

## Scope

Change only this project. A change needed elsewhere goes to its owner as a handoff.
