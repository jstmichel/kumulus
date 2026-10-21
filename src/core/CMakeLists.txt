# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT

# libkumulus: everything the service, the CLI and the application share. No QML here.
add_library(kumulus-core STATIC
    aboutdata.cpp
    version.cpp
)
target_include_directories(kumulus-core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${PROJECT_BINARY_DIR}
)
target_link_libraries(kumulus-core
    PUBLIC
        Qt6::Core
        KF6::CoreAddons
    PRIVATE
        KF6::I18n
)
