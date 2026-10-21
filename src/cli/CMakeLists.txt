# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT

# kumulusctl: the command-line client of kumulusd. Nothing specific to Plasma here (#6 R12).
add_executable(kumulusctl
    main.cpp
)
target_link_libraries(kumulusctl
    PRIVATE
        kumulus-core
        KF6::CoreAddons
        KF6::I18n
)

install(TARGETS kumulusctl ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
