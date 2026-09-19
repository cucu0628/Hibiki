cmake_minimum_required(VERSION 3.24)

project(Hibiki VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

find_package(Qt6 6.7 REQUIRED COMPONENTS
    Concurrent
    Core
    DBus
    Gui
    Multimedia
    Network
    Qml
    Quick
    QuickControls2
    Sql
    Test
    Widgets
)

qt_standard_project_setup(REQUIRES 6.7)
qt_policy(SET QTP0004 NEW)

qt_add_executable(hibiki
    src/main.cpp
    src/ApplicationController.cpp
    src/ApplicationController.h
    src/DownloadManager.cpp
    src/DownloadManager.h
    src/DiscordPresence.cpp
    src/DiscordPresence.h
    src/LibraryRepository.cpp
    src/LibraryRepository.h
    src/MprisService.cpp
    src/MprisService.h
    src/PlayerController.cpp
    src/PlayerController.h
    src/ThemeManager.cpp
    src/ThemeManager.h
    src/TrackModel.cpp
    src/TrackModel.h
    src/TrayController.cpp
    src/TrayController.h
)

set_source_files_properties(qml/components/DmsFonts.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(hibiki
    URI Hibiki
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/AccentButton.qml
        qml/components/Artwork.qml
        qml/components/DownloadPanel.qml
        qml/components/DmsFonts.qml
        qml/components/DmsIcon.qml
        qml/components/NowPlayingView.qml
        qml/components/VisualizerArtwork.qml
        qml/components/VellumField.qml
        qml/components/VellumPanel.qml
        qml/components/SettingsView.qml
        qml/components/IconButton.qml
        qml/components/LibraryView.qml
        qml/components/NowPlayingBar.qml
        qml/components/VellumCard.qml
        qml/components/VellumSlider.qml
        qml/components/SectionLabel.qml
)

qt_add_resources(hibiki "hibiki_icons"
    PREFIX "/assets"
    BASE assets
    FILES assets/hibiki.svg
)

target_link_libraries(hibiki PRIVATE
    Qt6::Concurrent
    Qt6::Core
    Qt6::DBus
    Qt6::Gui
    Qt6::Multimedia
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Sql
    Qt6::Widgets
)

install(TARGETS hibiki
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)
install(FILES hibiki.desktop DESTINATION share/applications)
install(FILES assets/hibiki.svg DESTINATION share/icons/hicolor/scalable/apps)

enable_testing()

qt_add_executable(hibiki_tests
    tests/tst_library.cpp
    src/LibraryRepository.cpp
    src/LibraryRepository.h
)
target_link_libraries(hibiki_tests PRIVATE Qt6::Core Qt6::Sql Qt6::Test)
target_include_directories(hibiki_tests PRIVATE src)
add_test(NAME hibiki_tests COMMAND hibiki_tests)
