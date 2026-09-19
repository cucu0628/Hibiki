import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hibiki

ApplicationWindow {
    id: window
    width: 1120
    height: 760
    minimumWidth: 860
    minimumHeight: 600
    visible: true
    title: "Hibiki"
    color: Theme.background
    font.family: DmsFonts.sans

    property int page: 0

    onPageChanged: {
        if (page === 1)
            stageLoader.visited = true
        else if (page === 2)
            downloadsLoader.visited = true
        else if (page === 3)
            settingsLoader.visited = true
    }

    Component.onCompleted: App.windowReady(window)
    onClosing: close => {
        close.accepted = false
        App.hideToTray()
    }

    background: Rectangle { color: Theme.background }

    RowLayout {
        width: Math.min(parent.width - 24, 1320)
        height: Math.min(parent.height - 24, 900)
        anchors.centerIn: parent
        spacing: 12

        Rectangle {
            id: sidebar
            Layout.preferredWidth: 212
            Layout.fillHeight: true
            color: Theme.surface
            radius: Theme.cornerRadius

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 14
                        color: Theme.primaryContainer

                        DmsIcon {
                            anchors.centerIn: parent
                            text: "music_note"
                            color: Theme.accent
                            filled: true
                            iconSize: 24
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "Hibiki"
                            color: Theme.foreground
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Music player"
                            color: Theme.muted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }

                Repeater {
                    model: [
                        { label: "Library", icon: "library_music", index: 0 },
                        { label: "Now playing", icon: "play_circle", index: 1 },
                        { label: "Downloads", icon: "download", index: 2 },
                        { label: "Settings", icon: "settings", index: 3 }
                    ]

                    delegate: Rectangle {
                        id: navChip
                        required property var modelData
                        readonly property bool selected: window.page === modelData.index

                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: height / 2
                        color: navChip.selected ? Theme.primaryContainer
                             : navMouse.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 155; easing.type: Easing.OutCubic } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 13

                            DmsIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: navChip.modelData.icon
                                color: navChip.selected ? Theme.accent : Theme.foreground
                                filled: navChip.selected
                                iconSize: 20
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: navChip.modelData.label
                                color: navChip.selected ? Theme.accent : Theme.foreground
                                font.pixelSize: 13
                                font.weight: navChip.selected ? Font.DemiBold : Font.Normal
                            }
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.page = navChip.modelData.index
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 66
                    radius: Theme.cornerRadius
                    color: Theme.surfaceHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 17
                            color: Theme.primaryContainer

                            DmsIcon {
                                anchors.centerIn: parent
                                text: "palette"
                                color: Theme.accent
                                filled: true
                                iconSize: 18
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "DMS theme"
                                color: Theme.muted
                                font.pixelSize: 10
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Theme.themeName
                                color: Theme.foreground
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.page

                LibraryView { }

                Loader {
                    id: stageLoader
                    property bool visited: false
                    active: visited
                    sourceComponent: NowPlayingView { }
                }

                Loader {
                    id: downloadsLoader
                    property bool visited: false
                    active: visited
                    sourceComponent: DownloadPanel { }
                }

                Loader {
                    id: settingsLoader
                    property bool visited: false
                    active: visited
                    sourceComponent: SettingsView { }
                }
            }

            NowPlayingBar {
                Layout.fillWidth: true
                visible: window.page !== 1
            }
        }
    }
}
