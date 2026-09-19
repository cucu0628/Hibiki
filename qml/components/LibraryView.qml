import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    signal downloadRequested()

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    VellumPanel {
        anchors.fill: parent
        title: Tracks.count === 0 ? "Welcome to Hibiki" : "Library"
        trailing: Tracks.scanning ? "Scanning…"
                : Tracks.count > 0
                    ? Tracks.count + (Tracks.count === 1 ? " track" : " tracks")
                    : ""

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 1100
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                VellumField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.maximumWidth: 380
                    visible: Tracks.count > 0
                    indicator: "search"
                    placeholderText: "Search title, artist, album"
                    onTextChanged: Tracks.searchText = text
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: Tracks.scanning
                    text: "Scanning…"
                    color: Theme.accent
                    font.pixelSize: 12
                    opacity: 0.8
                }

                AccentButton {
                    text: "Rescan"
                    iconText: "refresh"
                    outlined: true
                    enabled: !Tracks.scanning
                    onClicked: Tracks.rescan()
                }
            }

            ListView {
                id: trackList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: 1100
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                clip: true
                model: Tracks
                reuseItems: true
                cacheBuffer: 400
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    id: libraryScroll
                    width: 14
                    policy: trackList.contentHeight > trackList.height
                        ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    interactive: true
                    minimumSize: 0.08

                    contentItem: Rectangle {
                        implicitWidth: 8
                        radius: width / 2
                        color: Theme.accent
                        opacity: libraryScroll.pressed ? 1
                               : libraryScroll.hovered ? 0.85 : 0.62
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    background: Rectangle {
                        implicitWidth: 14
                        color: "transparent"

                        Rectangle {
                            width: 4
                            height: parent.height
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: width / 2
                            color: Theme.surfaceHighest
                        }
                    }
                }

                Connections {
                    target: Player
                    function onTrackChanged() {
                        if (Player.currentIndex < 0)
                            return
                        Qt.callLater(function() {
                            trackList.positionViewAtIndex(Player.currentIndex, ListView.Contain)
                        })
                    }
                }

                delegate: Rectangle {
                    id: row
                    required property int index
                    required property string title
                    required property string artist
                    required property string album
                    required property string coverPath
                    required property int duration
                    readonly property bool current: index === Player.currentIndex

                    width: ListView.view.width - (libraryScroll.visible ? 18 : 0)
                    height: 66
                    radius: Theme.cornerRadius
                    color: row.current ? Theme.primaryContainer
                         : rowMouse.containsMouse ? Theme.surfaceHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: 155 } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 0
                        color: Theme.accent
                        opacity: row.current ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.leftMargin: 12
                        spacing: 12

                        Text {
                            Layout.preferredWidth: 22
                            text: String(row.index + 1).padStart(2, "0")
                            color: row.current ? Theme.accent : Theme.muted
                            font.family: "monospace"
                            font.pixelSize: 8
                        }

                        Artwork {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            decodeSize: 128
                            source: row.coverPath ? "file://" + row.coverPath : ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: row.title
                                color: Theme.foreground
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.artist || row.album || "Unknown artist"
                                color: Theme.muted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: root.formatDuration(row.duration)
                            color: Theme.muted
                            font.pixelSize: 10
                        }

                        IconButton {
                            text: row.current && Player.playing ? "pause" : "play_arrow"
                            primary: row.current
                            buttonWidth: 38
                            buttonHeight: 38
                            iconSize: 16
                            description: row.current && Player.playing ? "Pause" : "Play"
                            onClicked: row.current ? Player.toggle() : Player.playTrack(row.index)
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        anchors.rightMargin: 50
                        hoverEnabled: true
                        onDoubleClicked: Player.playTrack(row.index)
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(trackList.width - 40, 460)
                    height: 230
                    radius: Theme.cornerRadius * 2
                    color: Theme.surfaceHigh
                    visible: trackList.count === 0

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 48
                        spacing: 10

                        Rectangle {
                            width: 64
                            height: 64
                            radius: 32
                            color: Theme.primaryContainer
                            anchors.horizontalCenter: parent.horizontalCenter

                            DmsIcon {
                                anchors.centerIn: parent
                                text: Tracks.searchText ? "search_off" : "library_music"
                                color: Theme.accent
                                filled: true
                                iconSize: 32
                            }
                        }

                        Text {
                            width: parent.width
                            text: Tracks.searchText ? "No matching tracks" : "Your library is empty"
                            color: Theme.foreground
                            font.pixelSize: 19
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            width: parent.width
                            text: Tracks.searchText
                                ? "Try another title, artist, or album."
                                : "Download a track or playlist to start listening."
                            color: Theme.muted
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                        AccentButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: !Tracks.searchText
                            text: "Open downloads"
                            iconText: "download"
                            onClicked: root.downloadRequested()
                        }
                    }
                }
            }
        }
    }
}
