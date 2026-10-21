# Kumulus — project context

Kumulus is a native KDE cloud sync client built on top of **rclone**. rclone is the engine
(backends, authentication, transfers, bisync, mounts); Kumulus is the brain (accounts,
folder pairs, change detection, scheduling, notifications, user interface).

- Repository: https://github.com/jstmichel/kumulus
- Goal: control rclone fully from a KDE app, starting with iCloud Drive and growing to any
  rclone backend (an account = an rclone remote).
- Deliverables: a background **service** (`kumulusd`), a **tray icon**, a **Kirigami app** to
  create and monitor accounts and sync pairs, and a **CLI** (`kumulusctl`).

## Workflow: spec-driven development with skills

Specifications live in **GitHub issues**, never as files in the repository (global rules
from kirakit's `CLAUDE.md`):

1. `/idea` captures an idea as an issue (`type:idea`, `status:needs-clarification`).
2. `/spec #<n>` turns it into a specification in the same issue: Context, Requirements
   (`R1…`, never renumbered), Design, Tasks, Open questions. Each task becomes a sub-issue
   (`type:task`, "Covers: R…", "Done when").
3. Before working on an issue: `gh issue view <n> --json title,body,parent,subIssues`. Its
   requirements are the acceptance criteria.
4. Implement one sub-issue per pull request (`Closes #<n>`); tests name the requirement they
   cover (`R2`). `/test` runs them, `/commit` commits, `/push` pushes.
5. If the work must diverge from the specification, stop and propose a change to the
   specification instead.

Never create, edit or close an issue without asking first. The roadmap is the specifications
#1–#13 (label `type:feature`), tracked on the project board
https://github.com/users/jstmichel/projects/9 (Status: Backlog → Ready → In progress →
In review → Done; fields Kind = Spec/Task and Phase). A specification moves from
`status:needs-clarification` to `status:specified`, and to Ready on the board, once the user
has validated it.

## Environment

- Workstation: CachyOS (Arch), KDE Plasma 6 on Wayland, shell **fish**, user `jstmichel`.
- rclone from the Arch package (`rclone` ≥ 1.69, needed for the `iclouddrive` backend).
- `fuse3` for mounts.
- Sibling project with the same stack and conventions: https://github.com/jstmichel/kobold

## Technical stack

Native KDE application in **C++20 / Qt 6 / KDE Frameworks 6 / Kirigami**.

- Build: CMake ≥ 3.25 + **extra-cmake-modules** (`KDEInstallDirs`, `KDECMakeSettings`,
  `KDECompilerSettings`, `ECMQmlModule`), presets in `CMakePresets.json` (`dev`, `release`).
- Qt 6: `Core`, `Network` (rclone RC API), `DBus`, `Qml`, `Quick`, `QuickControls2`, `Test`.
- KDE Frameworks 6: `Kirigami`, `KirigamiAddons`, `KCoreAddons` (`KAboutData`), `KI18n`,
  `KConfig` (KConfigXT), `KNotifications`, `KStatusNotifierItem` (tray), `KCrash`,
  `KIconThemes`.
- UI in QML/Kirigami; all logic in C++ exposed with `QML_ELEMENT` / singletons.
- Dependencies: single source of truth in `scripts/check-deps.sh`; CI, the release workflow
  and the PKGBUILDs follow it.

## Architecture

Three executables over one core library:

```
kumulus/
├── CMakeLists.txt
├── src/
│   ├── core/                 # libkumulus, no QML dependency
│   │   ├── rclonedaemon.{h,cpp}     # starts/stops `rclone rcd` (QProcess), health check
│   │   ├── rcclient.{h,cpp}         # JSON calls to the RC API, async jobs, errors
│   │   ├── accountmanager.{h,cpp}   # rclone remotes: list/create/update/delete/reconnect
│   │   ├── syncpair.{h,cpp}         # local path ↔ remote path + options
│   │   ├── syncscheduler.{h,cpp}    # per-pair queue: one running + one pending
│   │   ├── localwatcher.{h,cpp}     # recursive inotify (QSocketNotifier), debounce
│   │   ├── remoteprobe.{h,cpp}      # cheap "did the remote change?" check, per backend
│   │   ├── cloudkitprobe.{h,cpp}    # iCloud Drive probe: CloudKit changes/zone (read-only)
│   │   ├── mountmanager.{h,cpp}     # mount/mount, mount/unmount, mount/listmounts
│   │   └── stats.{h,cpp}            # core/stats, job/status → progress model
│   ├── daemon/               # kumulusd: systemd user service, D-Bus API
│   ├── cli/                  # kumulusctl: doctor, status, sync, pause/resume, accounts
│   └── app/                  # kumulus: Kirigami window + tray icon
├── tests/                    # QtTest: scheduler, watcher, fake RC server
├── data/                     # icons, .desktop, AppStream metainfo, systemd unit, D-Bus service
├── packaging/                # PKGBUILD (checkout) and release/PKGBUILD (release archive)
└── scripts/                  # get-kumulus.sh, install.sh, check-deps.sh
```

- **kumulusd** owns everything (rclone process, watchers, timers, queue) and exposes it on
  the session bus as `me.kodara.Kumulus`. Installed as `kumulusd.service` (systemd user unit,
  `WantedBy=default.target`).
- **kumulus** (GUI + tray) and **kumulusctl** (CLI) are thin D-Bus clients. Closing the
  window never stops a sync; the tray icon stays while the service runs.
- One `rclone rcd` process per daemon. Accounts live in rclone's own config
  (`~/.config/rclone/rclone.conf`): it stays the single source of truth, so the `rclone`
  command line keeps working with the same accounts.
- Kumulus settings (pairs, mounts, intervals) live in `~/.config/kumulusrc` (KConfig).
- Application id: `me.kodara.kumulus` (desktop file, metainfo, app icon).
- **KDE first, desktop-neutral engine** (decided 2026-10-20): the window and tray are
  Kirigami and follow the Plasma theme; no custom visual identity. `kumulusd` and
  `kumulusctl` depend on nothing specific to Plasma (freedesktop notifications, a documented
  D-Bus API), so a native client for another desktop (GTK/libadwaita for GNOME) can be added
  later over the same API.

## User interface

- **Tray icon** (`KStatusNotifierItem`), always present while `kumulusd` runs:
  - icon by state: `kumulus-tray` (idle), `kumulus-tray-syncing`, `kumulus-tray-paused`,
    `kumulus-tray-error`, `kumulus-tray-offline` (white, in `data/icons/`);
  - tooltip: overall state, last sync time, current transfer speed;
  - menu (right click): Open Kumulus, Sync now, Pause / Resume, one line per account with its
    state, Quit (closes the window, the tray and the service). Closing the window only hides
    it.
- **Kirigami window** (`me.kodara.kumulus.svg` app icon):
  - Accounts: list with state (connected, syncing, needs reconnect, error); add an account
    through a wizard driven by rclone's config questions (iCloud: Apple ID, password, 2FA
    code); reconnect; remove.
  - Sync pairs per account: local folder ↔ remote folder, state, last sync, pause, sync now,
    first-sync dry-run preview before the initial resync.
  - Mounts per account (e.g. iCloud Photos, read-only), with a Dolphin Places entry.
  - Activity: live transfers (`core/stats`), recent sync history, errors and conflicts.

## Driving rclone

Use the **remote control server** (`rclone rcd`), not `librclone` (experimental, needs Go +
cgo to build, complicates packaging).

- Start: `rclone rcd --rc-addr 127.0.0.1:<random port>` with `RCLONE_RC_USER` and
  `RCLONE_RC_PASS` set to random values in the child's environment (credentials generated per
  session, kept in memory only, never on the command line, which `/proc` exposes). Never
  `--rc-no-auth`.
- Calls are `POST /<method>` with a JSON body. Long operations use `"_async": true`, then poll
  `job/status`; group stats per pair with `"_group": "<pair id>"`.
- Useful methods:
  - Accounts: `config/listremotes`, `config/get`, `config/providers`, `config/create`,
    `config/update`, `config/delete`, `config/paths`. Interactive flows (2FA, OAuth) use the
    non-interactive config state machine (`opt: { nonInteractive: true, continue: true,
    state, result }`): rclone returns the next question, the UI asks it, the answer is sent
    back. This drives the account wizard, the iCloud 2FA prompt and the 30-day reconnect.
  - Sync: `sync/bisync`, `sync/sync`, `sync/copy`.
  - Listing: `operations/list`, `operations/stat`, `operations/size`, `operations/about`.
  - Mounts: `mount/mount`, `mount/unmount`, `mount/listmounts`, `vfs/refresh`.
  - Progress: `core/stats`, `core/stats-reset`, `job/list`, `job/status`, `job/stop`.
  - Lifecycle: `core/version`, `core/quit`.
- Check method names and parameters against `rclone rc --loopback rc/list` for the installed
  version before relying on them.
- **One exception:** the iCloud Drive remote probe (#5) calls Apple's CloudKit directly,
  read-only, reusing the session cookies rclone stores (read with `config/get`, never
  written). It must fail safe: any unknown answer means "cannot decide", and re-authentication
  stays rclone's job. Everything else goes through the RC API.

## Sync model (reference behavior)

A shell prototype runs on the workstation and is the reference: `~/.local/bin/sync-documents`
(lock + pending flag), `~/.local/bin/documents-watch` (inotify), and the user units
`rclone-documents.service` / `.timer` / `documents-watch.service`. Kumulus must behave the
same, then improve on it.

- **Always two-way (`bisync`)** for a sync pair. Never two one-way syncs: a one-way `sync`
  deletes files that only exist on the other side (race between triggers).
- **Triggers are separate, the engine is single:**
  - local change (recursive inotify) → debounce 5 s → request a sync;
  - remote probe says "changed" → request a sync;
  - safety net: full bisync every hour.
- **Coalescing per pair:** at most one run in progress and one pending. Any number of
  requests during a run collapse into one follow-up run. Example: 0:00 remote trigger starts
  run #1; local triggers at 0:10, 0:20, 0:25 mark the pair pending; run #1 ends at 0:30;
  run #2 starts once and covers all three.
- **Bisync flags:** `--create-empty-src-dirs`, `--conflict-resolve newer`, `--resilient`,
  `--recover`, `--max-lock 2m`, `--checkers 16`, filters file per pair. First run of a pair:
  `--resync --resync-mode newer`, after a dry run shown to the user.
- Ignored by default: `.DS_Store`, `._*`, `.~lock.*`, `~$*`, `.directory`, `*.tmp`,
  `.Trash-*/**`. Changing filters requires a new resync.
- Bisync's safety stop (more than 50 % deletions) surfaces as a notification and is never
  bypassed silently.

Measured on the workstation (iCloud `Documents`, ~1300 entries, 3.2 GB): first copy 22 min;
a run with nothing to transfer ≈ 20–26 s, almost all of it listing the remote.

## Cheap remote change detection (iCloud Drive)

Settled by the experiment #1 (findings on #1, recommendation on #17):

- Drive has **no change feed in rclone**: every bisync lists the full remote tree.
- **Folder metadata is not enough.** Listing a parent gives each child folder
  `ID` = `<drivewsid>#<etag>` and `Size` = `assetQuota` (recursive). The etag is stable when
  nothing changes and an add propagates to every ancestor, but a **rename only changes the
  direct parent's etag**. `ModTime` is synthetic with `stat` (now) and a fixed placeholder
  (`2000-01-01`) in a parent listing. Probing every folder through rclone costs about as much
  as a bisync (87 folders, 18.7 s).
- **CloudKit `changes/zone` works.** Container `com.apple.clouddocs`, zone
  `com.apple.CloudDocs`, endpoint `<ckdatabasews>/database/1/com.apple.clouddocs/production/private/`
  (`ckdatabasews` URL from `setup.icloud.com/setup/ws/1/validate`). It answers with rclone's
  session; `zones/list` gives the current sync token without enumerating; `changes/zone`
  with that token takes one request of 0.3–0.4 s and reports every tested change at any depth
  (add, rename, delete, changes from icloud.com). Records are `content` (data) and
  `structure` (place in the tree, with a `parent` reference). Deletes are soft: the record
  gains `restorePath` (Recently Deleted) rather than `deleted=true`.
- Probe design: `changes/zone` every minute per account, hourly bisync as safety net, token
  persisted; the "verify after sync" pair option decides whether changes during a run trigger
  a follow-up run (#4 R15, #5 R13).
- Still open (#5): how long a sync token stays valid; whether a `structure` record name
  matches the drive id (to map changes to pairs).
- Long term: a `ChangeNotify` for Drive in rclone upstream (Photos already has one) would
  remove the direct call.

## iCloud specifics

- Requires Advanced Data Protection **off** and "Access iCloud Data on the Web" **on**.
- Login: Apple ID + real password (no app-specific password) + 2FA code.
- The trust token lasts about **30 days**; then a reconnect with a new 2FA code. Kumulus
  detects the authentication error and notifies ("Reconnect iCloud").
- Uploads can fail with `http2 GOAWAY` from Apple: transient; with `--resilient --recover`
  the next run continues without a resync.
- Photos is read-only: mount only, never a sync pair.

## Conventions

- **Code:** follow [`docs/coding-guidelines.md`](docs/coding-guidelines.md) (C++, QML, tests,
  CMake, comments); `scripts/check-format.sh` passes. Read it before writing code.
- Code, comments, commit messages and documentation: neutral English. The app is translated
  (`i18n`/`i18nc`); French is kept complete.
- Commits: Conventional Commits, signed; no AI attribution anywhere (kirakit rules).
- No personal data (Apple ID, paths with real names, account ids) in issues either.
- Build and tests: `cmake --preset dev && cmake --build --preset dev && ctest --preset dev`.
