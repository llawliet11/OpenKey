---
name: resources-policy
description: Never creates, deletes or scales a remote or billable resource on its own initiative; every artefact this project's code creates on a paid or quota system carries a retention rule; cleanup is a dry run unless the owner says apply in that turn. Inventories OpenKey CE's billable artefacts and checks them against the plan quota. Use when the owner says "check costs", "audit resources", "clean up artifacts", "kiem tra chi phi", "kiem tra quota", "don artifact". The model never invokes it on its own: when a situation matches, it says so in one line at the end of the coding reply and invokes it only after the owner says yes in that turn, or when a /goal prompt or a standing grant in the owner's message already covers it.
---

# resources-policy

## Policy

- A billable artefact costs money per unit or per unit of time, or counts against a plan quota: database branches, buckets and stored objects, preview and production deploys, tunnels, tokens, test tenants, queues, CI artifact storage, and schedules that wake a metered backend.
- Release mechanics are not billable artefacts: code signing, Apple notarization (`xcrun notarytool`), timestamp servers, build-provenance attestations, and GitHub Release uploads. `ci-policy` names them in its release steps.
- Every billable artefact the project's code creates ships with its retention rule in the same change: who deletes it, when, and how many are kept.
- Payment providers: none found by the survey. A live key (`sk_live_`, `pk_live_`, a PayPal live client) found later is reported by key name only and never used.
- A unit the console shows as idle still counts when the plan bills per unit; compare the count with the plan's included quota.
- A schedule or keep-alive is judged by what it wakes on a metered backend. The app's update check fetches a static file from `raw.githubusercontent.com` and wakes no metered backend.
- When the plan or provider changes, re-read every choice justified by the old plan's limits.
- After a burst of pushes or an unattended board run, the cost check runs before the next one.
- A feature that spends the user's LLM quota ships with a cap and runs only on an explicit user action (none exists today).
- Deleting a live remote resource, and deploying, is a destructive remote action: dry run by default; apply only in an interactive session on the owner's word in that turn, never in an unattended run; always keep the newest N.
- Unattended runs: the read-only cost check runs once before the run ends only when the starting message names it, plus at most a dry run. A cleanup it would propose becomes an `Owner:` task through `cyberine tasks`, never a question and never an apply. No owner-written tracked rule here pre-authorizes remote deletion.

## Inventory

| Artefact | Created at | Deleter, when | Keep-N | Quota / price | Plan basis |
|---|---|---|---|---|---|
| GitHub Actions artifact `OpenKey` (Windows build output) | `.github/workflows/msbuild.yml`, step `Upload a Build Artifact`, only on a manual `workflow_dispatch` run | GitHub deletes it after `retention-days: 1` (owner decision D2, 2026-10-27: keep as little as possible) | 0 after one day | Owner: decide (Actions storage is quota-counted on private repos) | Owner: decide |
| GitHub Actions minutes (`windows-latest` build, `ubuntu-latest` attest) | same workflow, manual runs only | not an artefact to delete | n/a | Owner: decide | Owner: decide |

No database, bucket, deploy, tunnel, token, queue or schedule is created by the repo's code (survey of `Sources/`, `.github/`, `release.sh`).

## Cost check

No scripted cost check exists in the repo, and the repo calls no provider CLI for these resources (`release.sh` calls only Apple tooling). The command that lists Actions artifacts and their storage against the plan quota is the owner's choice (Owner: decide); until it exists the check reports "unread", never a pass. When written, it prints counts and names only, a named reason when the `gh` token is missing or auth fails, and treats empty output as "unread".

Dry-run cleanup: none scripted. Apply: none scripted; any deletion follows the Policy above.

## Cleanup

- Local run artefacts only here; this skill owns remote and billable ones.
- Anything a run creates for itself (temp dirs, worktrees, processes) is removed when it ends. Processes are stopped only by a PID this run started and recorded, never by name, pattern or port. No LaunchAgent, login item, cron entry or `caffeinate` outlives the run; any it could not remove is listed with the removal command.

## Scope

Change only this project. A change needed elsewhere goes to its owner as a handoff.
