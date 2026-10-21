# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT

# kumulus: the Kirigami window (the tray icon comes with #9).
add_executable(kumulus
    main.cpp
)

ecm_add_qml_module(kumulus URI me.kodara.kumulus)
ecm_target_qml_sources(kumulus SOURCES
    qml/Main.qml
)

target_link_libraries(kumulus
    PRIVATE
        kumulus-core
        Qt6::Widgets
        Qt6::Quick
        Qt6::QuickControls2
        KF6::CoreAddons
        KF6::Crash
        KF6::I18n
        KF6::I18nQml
        KF6::IconThemes
)

install(TARGETS kumulus ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
