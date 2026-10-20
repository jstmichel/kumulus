# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT

ecm_add_tests(
    versiontest.cpp
    LINK_LIBRARIES kumulus-core Qt6::Test
)
target_compile_definitions(versiontest PRIVATE KUMULUS_EXPECTED_VERSION="${PROJECT_VERSION}")
