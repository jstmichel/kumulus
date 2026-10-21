<!--
SPDX-FileCopyrightText: 2026 Kumulus contributors
SPDX-License-Identifier: MIT
-->

# Coding guidelines

How Kumulus code is written and reviewed. The KDE guidelines linked at the top of each section
are the base; this document only states where Kumulus is stricter or more specific. Every rule
can be checked on a diff: a change that breaks one is fixed before it is merged.

## General

Base: [KDE Frameworks Coding Style](https://community.kde.org/Policies/Frameworks_Coding_Style).

- Format C++ with the repository's `.clang-format`; `scripts/check-format.sh` passes.
- C++20, Qt 6 and KDE Frameworks 6. A new dependency is added to `scripts/check-deps.sh` in
  the same change.
- Every source file starts with an SPDX header:

  ```cpp
  // SPDX-FileCopyrightText: 2026 Kumulus contributors
  // SPDX-License-Identifier: MIT
  ```

- Identifiers, comments and log messages are in English; user-visible strings are translated
  (see [QML](#qml) and [C++](#c)).
- No personal data anywhere in code or tests: no Apple ID, real path with a name, or account
  id. Use `user@example.com`, `/home/user`.
- Layers stay separate: `src/core` (`libkumulus`) has no QML dependency; `kumulusd` and
  `kumulusctl` use nothing specific to Plasma; the app and the CLI reach the service only
  through the D-Bus proxy in `libkumulus`.

## C++

Base: [KDE Library Code Policy](https://community.kde.org/Policies/Library_Code_Policy),
[Qt object trees and ownership](https://doc.qt.io/qt-6/objecttrees.html).

`libkumulus` is a static, internal library: it has no ABI to keep, so no d-pointers and no
export macros.

### Names and files

- All project code lives in the `Kumulus` namespace.
- Classes and enums `UpperCamelCase`; functions and variables `lowerCamelCase`; members `m_`,
  static members `s_`; enums are `enum class`.
- One class per header/source pair, named after the class in lowercase: `SyncScheduler` in
  `syncscheduler.h` and `syncscheduler.cpp`.
- Headers use `#pragma once`. A source file includes its own header first, then Qt and KDE,
  then the standard library.

### Qt idioms

- Every `QObject` subclass has `Q_OBJECT`. A property seen from QML or D-Bus is a
  `Q_PROPERTY` with a `NOTIFY` signal.
- Qt keywords are disabled (`QT_NO_KEYWORDS`): write `Q_SIGNALS`, `Q_SLOTS`, `Q_EMIT`.
- Connect with member-function pointers, never `SIGNAL()`/`SLOT()` strings. A lambda
  connection always passes a context object, so it dies with it:

  ```cpp
  // ✅
  connect(reply, &QNetworkReply::finished, this, [this, reply] { onReply(reply); });
  // ❌ no context: the lambda can run after `this` is deleted
  connect(reply, &QNetworkReply::finished, [this, reply] { onReply(reply); });
  ```

- String literals are `QStringLiteral("…")`; implicit casts from `const char *` are disabled
  (`QT_NO_CAST_FROM_ASCII`).
- `auto` only when the type is obvious from the right-hand side. Mark overrides `override`,
  single-argument constructors `explicit`.

### Ownership

- A `QObject` has a parent, or is held by a `std::unique_ptr`. No naked `new` without a parent,
  no `delete` on a `QObject` that may be inside one of its own signals: use `deleteLater()`.
- A non-owning pointer to a `QObject` that can die first is a `QPointer`.
- A `QNetworkReply` is released with `deleteLater()` in its `finished` handler.

### Asynchronous work

The service and the app never block their event loop.

- No `waitForFinished()`, `waitForReadyRead()`, nested `QEventLoop::exec()`, `sleep()` or
  blocking D-Bus call (`QDBus::Block`) in `src/`. The CLI may wait, through the same
  asynchronous API.
- RC calls go through `QNetworkAccessManager`; D-Bus calls use `QDBusPendingCallWatcher`.

  ```cpp
  // ✅
  auto *watcher = new QDBusPendingCallWatcher(m_proxy->SyncNow(pairId), this);
  connect(watcher, &QDBusPendingCallWatcher::finished, this, &Client::onSyncNowFinished);
  // ❌ blocks until the service answers
  m_proxy->SyncNow(pairId).waitForFinished();
  ```

- Delays and intervals (debounce, probe, safety net) come from settings or a constructor
  argument, never a constant buried in a function, so tests can shorten them.

### Errors and logging

- Never swallow an error: return it or emit it, and log it.
- Log with a category per module, `Q_LOGGING_CATEGORY` named `kumulus.<module>`
  (`kumulus.scheduler`); no uncategorized `qDebug()`.
- Never log or pass on a command line the RC credentials, a password, a 2FA code, a session
  cookie or a token.
- A message shown to the user is translated with `i18n`/`i18nc` where it is shown; the core
  reports the error, the UI words it.

## QML

Base: [Kirigami](https://develop.kde.org/docs/getting-started/kirigami/),
[KDE HIG](https://develop.kde.org/hig/),
[Kirigami colors and themes](https://develop.kde.org/docs/getting-started/kirigami/style-colors/),
[Qt Quick best practices](https://doc.qt.io/qt-6/qtquick-bestpractices.html).

- QML presents; C++ decides. No business logic, network or file access in QML; JavaScript is
  limited to UI glue (formatting a binding, toggling a view).
- C++ types reach QML through `QML_ELEMENT` / `QML_SINGLETON` in an `ecm_add_qml_module`; no
  `qmlRegisterType`, no context properties.
- Prefer Kirigami and Kirigami Addons components (`Kirigami.Page`, `FormCard`) over custom
  ones.
- Styling only uses theme tokens: colors from `Kirigami.Theme`, sizes and spacing from
  `Kirigami.Units`. No hex colors, no pixel numbers.

  ```qml
  // ✅
  color: Kirigami.Theme.negativeTextColor
  spacing: Kirigami.Units.largeSpacing
  // ❌
  color: "#da4453"
  spacing: 12
  ```

- Icons by theme name (`icon.name: "folder-sync"`), never by file path.
- Every user-visible string uses `i18nc("context", "Text")` (`i18ncp` for plurals), including
  tooltips and accessible names.
- Every interactive control is reachable with the keyboard, in visual order, and has an
  accessible name: its text, or `Accessible.name` when it shows only an icon. Base:
  [KDE HIG accessibility](https://develop.kde.org/hig/accessibility/),
  [Qt Quick accessibility](https://doc.qt.io/qt-6/accessible-qtquick.html).
- Properties are typed (`property string`, not `property var`, when a type exists); delegates
  use `required property`.

## Tests

Base: [Qt Test overview](https://doc.qt.io/qt-6/qtest-overview.html).

- One test file per module, `<module>test.cpp`, class `<Module>Test`, added with
  `ecm_add_tests`. `QTEST_GUILESS_MAIN` unless the test needs a GUI.
- Each test function names the requirement it covers, as `#<spec> R<n>`:

  ```cpp
  // #4 R3: requests during a run collapse into one follow-up run.
  void coalescesRequestsDuringRun();
  ```

  A regression test with no requirement names the issue it reproduces (`// #123`).
- Tests never touch the real home, `rclone.conf`, keychain, network or devices: a fake RC
  server, `QTemporaryDir` for local trees, temporary `XDG_*` folders set before the code under
  test runs, `QStandardPaths::setTestModeEnabled(true)`.
- The offscreen platform comes from the CTest preset; a test does not set it itself.
- No sleeping: wait with `QSignalSpy::wait()` or `QTRY_COMPARE`, and shorten intervals through
  their setting (see [Asynchronous work](#asynchronous-work)).
- A UI page's test checks its focus order, keyboard activation and accessible names.

## CMake

Base: [ECM](https://api.kde.org/ecm/),
[building KDE software with CMake](https://develop.kde.org/docs/getting-started/building/cmake-build/).

- Targets only: `target_include_directories`, `target_link_libraries`,
  `target_compile_definitions`; no global `include_directories`, `add_definitions` or
  `link_libraries`.
- Sources are listed explicitly; no `file(GLOB)` for build sources.
- Minimum versions live in the top-level `find_package` calls and match
  `scripts/check-deps.sh`.
- Install paths use the `KDEInstallDirs` variables (`KDE_INSTALL_BINDIR`, …), never a
  hard-coded path.
- Each `CMakeLists.txt` starts with the SPDX header and, when it defines a target, a one-line
  comment saying what the target is.

## Comments

Base: [KDE API documentation](https://community.kde.org/Guidelines_and_HOWTOs/API_Documentation).

- A comment says why, not what the next line does.
- Each class and public function declared in a `src/core` header has a one-line `//` comment
  saying what it does or returns.
- No commented-out code. A `TODO` names its issue: `// TODO(#123): …`.
- A workaround names its cause and, when there is one, its issue:
  `// Apple answers GOAWAY under load; the next run resumes (#123).`
