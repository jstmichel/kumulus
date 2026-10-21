# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT

ecm_add_tests(
    versiontest.cpp
    aboutdatatest.cpp
    LINK_LIBRARIES kumulus-core Qt6::Test
)
target_compile_definitions(versiontest PRIVATE KUMULUS_EXPECTED_VERSION="${PROJECT_VERSION}")
target_compile_definitions(aboutdatatest PRIVATE KUMULUS_EXPECTED_VERSION="${PROJECT_VERSION}")

ecm_add_test(clitest.cpp
    TEST_NAME clitest
    LINK_LIBRARIES Qt6::Test
)
add_dependencies(clitest kumulusctl)
target_compile_definitions(clitest PRIVATE
    KUMULUS_EXPECTED_VERSION="${PROJECT_VERSION}"
    KUMULUSCTL_PATH="$<TARGET_FILE:kumulusctl>"
)
