# SPDX-FileCopyrightText: 2026 Kumulus contributors
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.25)

project(kumulus VERSION 0.1.0 LANGUAGES CXX)

set(QT_MIN_VERSION "6.6.0")
set(KF_MIN_VERSION "6.0.0")

find_package(ECM ${KF_MIN_VERSION} QUIET NO_MODULE)
if(NOT ECM_FOUND)
    message(FATAL_ERROR
        "extra-cmake-modules >= ${KF_MIN_VERSION} not found.\n"
        "Arch package: extra-cmake-modules (sudo pacman -S --needed extra-cmake-modules)")
endif()
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDEClangFormat)
include(ECMSetupVersion)
include(ECMAddTests)
include(ECMQmlModule)
include(FeatureSummary)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Required packages are looked up without REQUIRED so that feature_summary can report
# every missing package at once, each with its Arch package name.
set(KUMULUS_QT_COMPONENTS Core Gui Widgets Qml Quick QuickControls2)
if(BUILD_TESTING)
    list(APPEND KUMULUS_QT_COMPONENTS Test)
endif()
find_package(Qt6 ${QT_MIN_VERSION} CONFIG COMPONENTS ${KUMULUS_QT_COMPONENTS})
set_package_properties(Qt6 PROPERTIES
    TYPE REQUIRED
    DESCRIPTION "Arch packages: qt6-base, qt6-declarative"
    PURPOSE "Core library, application window and tests")

find_package(KF6CoreAddons ${KF_MIN_VERSION} CONFIG)
set_package_properties(KF6CoreAddons PROPERTIES
    TYPE REQUIRED DESCRIPTION "Arch package: kcoreaddons" PURPOSE "Application metadata")

find_package(KF6I18n ${KF_MIN_VERSION} CONFIG)
set_package_properties(KF6I18n PROPERTIES
    TYPE REQUIRED DESCRIPTION "Arch package: ki18n" PURPOSE "Translations")

find_package(KF6Crash ${KF_MIN_VERSION} CONFIG)
set_package_properties(KF6Crash PROPERTIES
    TYPE REQUIRED DESCRIPTION "Arch package: kcrash" PURPOSE "Crash handling")

find_package(KF6IconThemes ${KF_MIN_VERSION} CONFIG)
set_package_properties(KF6IconThemes PROPERTIES
    TYPE REQUIRED DESCRIPTION "Arch package: kiconthemes" PURPOSE "Plasma icon integration in the application")

find_package(KF6Kirigami ${KF_MIN_VERSION} CONFIG)
set_package_properties(KF6Kirigami PROPERTIES
    TYPE REQUIRED DESCRIPTION "Arch package: kirigami" PURPOSE "Application user interface")

find_package(KF6KirigamiAddons 1.0 CONFIG)
set_package_properties(KF6KirigamiAddons PROPERTIES
    TYPE RUNTIME DESCRIPTION "Arch package: kirigami-addons" PURPOSE "About page")

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)

ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX KUMULUS
    VERSION_HEADER ${CMAKE_CURRENT_BINARY_DIR}/kumulus_version.h)

add_subdirectory(src)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

file(GLOB_RECURSE KUMULUS_FORMAT_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/src/*.h
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/tests/*.h)
kde_clang_format(${KUMULUS_FORMAT_SOURCES})
