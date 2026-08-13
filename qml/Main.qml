import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hibiki
import "components"

ApplicationWindow {
    id: window
    width: 1080
    height: 720
    minimumWidth: 820
    minimumHeight: 560
    visible: true
    title: "Hibiki"
    color: Theme.background

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
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: sidebar
            Layout.preferredWidth: 196
            Layout.fillHeight: true
            color: Theme.surface

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Theme.outline
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "H"
                            color: Theme.background
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: "HIBIKI"
                            color: Theme.foreground
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "MUSIC PLAYER"
                            color: Theme.muted
                            font.pixelSize: 9
                            font.letterSpacing: 1
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    implicitHeight: 1
                    color: Theme.muted
                    opacity: 0.35
                }

                Repeater {
                    model: [
                        { label: "LIBRARY", icon: "", index: 0 },
                        { label: "NOW PLAYING", icon: "", index: 1 },
                        { label: "DOWNLOADS", icon: "", index: 2 },
                        { label: "SETTINGS", icon: "", index: 3 }
                    ]

                    delegate: Rectangle {
                        id: navChip
                        required property var modelData
                        readonly property bool selected: window.page === modelData.index

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 0
                        color: navChip.selected ? Theme.accent
                             : navMouse.containsMouse ? Theme.hover : "transparent"
                        border.width: 1
                        border.color: navChip.selected ? Theme.accent : Theme.line
                        Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.right: parent.right
                            anchors.rightMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 9

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: navChip.modelData.icon
                                color: navChip.selected ? Theme.background : Theme.accent
                                font.family: "MesloLGS Nerd Font Mono"
                                font.pixelSize: 14
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: navChip.modelData.label
                                color: navChip.selected ? Theme.background : Theme.foreground
                                font.pixelSize: 9
                                font.letterSpacing: 2
                                font.bold: true
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
                    implicitHeight: 1
                    color: Theme.accent
                    opacity: 0.26
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    SectionLabel { text: "THEME" }
                    Text {
                        Layout.fillWidth: true
                        text: Theme.themeName.toUpperCase()
                        color: Theme.foreground
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        text: App.musicDirectory
                        color: Theme.muted
                        font.pixelSize: 8
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            spacing: 14

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.page

                LibraryView { }

                // The secondary pages are only built once they are opened, so
                // the first frame carries just the library.
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

            // The stage page carries its own transport, so the bar would only
            // repeat it there.
            NowPlayingBar {
                Layout.fillWidth: true
                visible: window.page !== 1
            }
        }
    }
}
