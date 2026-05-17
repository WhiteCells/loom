cmake_minimum_required(VERSION 3.20)

project(LoomDesktop VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(QML_MODULE_URI Loom)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Network Qml Quick QuickControls2 Svg Widgets)

qt_standard_project_setup(REQUIRES 6.5)
qt6_policy(SET QTP0004 NEW)

set_source_files_properties(qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
set_source_files_properties(qml/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
    QT_RESOURCE_ALIAS Theme.qml
)
set_source_files_properties(qml/components/ActionButton.qml PROPERTIES QT_RESOURCE_ALIAS components/ActionButton.qml)
set_source_files_properties(qml/components/CodeCard.qml PROPERTIES QT_RESOURCE_ALIAS components/CodeCard.qml)
set_source_files_properties(qml/components/DetailTile.qml PROPERTIES QT_RESOURCE_ALIAS components/DetailTile.qml)
set_source_files_properties(qml/components/DetailValueRow.qml PROPERTIES QT_RESOURCE_ALIAS components/DetailValueRow.qml)
set_source_files_properties(qml/components/FormComboBox.qml PROPERTIES QT_RESOURCE_ALIAS components/FormComboBox.qml)
set_source_files_properties(qml/components/FormTextField.qml PROPERTIES QT_RESOURCE_ALIAS components/FormTextField.qml)
set_source_files_properties(qml/components/Icon.qml PROPERTIES QT_RESOURCE_ALIAS components/Icon.qml)
set_source_files_properties(qml/components/NavButton.qml PROPERTIES QT_RESOURCE_ALIAS components/NavButton.qml)
set_source_files_properties(qml/components/Pill.qml PROPERTIES QT_RESOURCE_ALIAS components/Pill.qml)
set_source_files_properties(qml/components/SettingsNavItem.qml PROPERTIES QT_RESOURCE_ALIAS components/SettingsNavItem.qml)
set_source_files_properties(qml/components/SidebarItem.qml PROPERTIES QT_RESOURCE_ALIAS components/SidebarItem.qml)
set_source_files_properties(qml/components/StatCard.qml PROPERTIES QT_RESOURCE_ALIAS components/StatCard.qml)
set_source_files_properties(qml/components/StyledScrollBar.qml PROPERTIES QT_RESOURCE_ALIAS components/StyledScrollBar.qml)
set_source_files_properties(qml/components/ToggleSwitch.qml PROPERTIES QT_RESOURCE_ALIAS components/ToggleSwitch.qml)
set_source_files_properties(qml/pages/DashboardPage.qml PROPERTIES QT_RESOURCE_ALIAS pages/DashboardPage.qml)
set_source_files_properties(qml/pages/HealthChecksPage.qml PROPERTIES QT_RESOURCE_ALIAS pages/HealthChecksPage.qml)
set_source_files_properties(qml/pages/ProfilesPage.qml PROPERTIES QT_RESOURCE_ALIAS pages/ProfilesPage.qml)
set_source_files_properties(qml/pages/SettingsPage.qml PROPERTIES QT_RESOURCE_ALIAS pages/SettingsPage.qml)
set_source_files_properties(qml/pages/TokenUsagePage.qml PROPERTIES QT_RESOURCE_ALIAS pages/TokenUsagePage.qml)

qt_add_executable(${PROJECT_NAME}
    src/main.cc
    src/profilemanager.cc
    src/profilemanager.h
    src/settingsmanager.cc
    src/settingsmanager.h
)

qt_add_qml_module(${PROJECT_NAME}
    URI ${QML_MODULE_URI}
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/components/ActionButton.qml
        qml/components/CodeCard.qml
        qml/components/DetailTile.qml
        qml/components/DetailValueRow.qml
        qml/components/FormComboBox.qml
        qml/components/FormTextField.qml
        qml/components/Icon.qml
        qml/components/NavButton.qml
        qml/components/Pill.qml
        qml/components/SettingsNavItem.qml
        qml/components/SidebarItem.qml
        qml/components/StatCard.qml
        qml/components/StyledScrollBar.qml
        qml/components/ToggleSwitch.qml
        qml/pages/DashboardPage.qml
        qml/pages/HealthChecksPage.qml
        qml/pages/ProfilesPage.qml
        qml/pages/SettingsPage.qml
        qml/pages/TokenUsagePage.qml
)

file(GLOB LOOM_ICON_FILES
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    CONFIGURE_DEPENDS
    assets/icons/*.svg
    assets/icons/LICENSE
)

qt_add_resources(${PROJECT_NAME} "icon_resources"
    PREFIX "/"
    FILES ${LOOM_ICON_FILES}
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Network
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Svg
        Qt6::Widgets
)

target_compile_definitions(${PROJECT_NAME}
    PRIVATE
        LOOM_QML_MODULE_URI="${QML_MODULE_URI}"
)
