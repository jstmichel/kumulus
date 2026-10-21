# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT

# kumulusd: the background service. Nothing specific to Plasma here (#6 R12).
add_executable(kumulusd
    main.cpp
)
target_link_libraries(kumulusd
    PRIVATE
        kumulus-core
        KF6::CoreAddons
        KF6::Crash
        KF6::I18n
)

install(TARGETS kumulusd ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
