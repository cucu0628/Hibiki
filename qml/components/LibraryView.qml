import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    VellumPanel {
        anchors.fill: parent
        title: "LIBRARY"
        trailing: Tracks.scanning ? "SCANNING"
                : Tracks.count + (Tracks.count === 1 ? " TRACK" : " TRACKS")

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                VellumField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.maximumWidth: 320
                    indicator: ""
                    placeholderText: "Search title, artist, album"
                    onTextChanged: Tracks.searchText = text
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: Tracks.scanning
                    text: "SCANNING"
                    color: Theme.accent
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    opacity: 0.8
                }

                AccentButton {
                    text: "RESCAN"
                    iconText: ""
                    outlined: true
                    enabled: !Tracks.scanning
                    onClicked: Tracks.rescan()
                }
            }

            ListView {
                id: trackList
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2
                clip: true
                model: Tracks
                reuseItems: true
                cacheBuffer: 400
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    width: 3
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3
                        color: Theme.accent
                        opacity: 0.55
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

                    width: ListView.view.width
                    height: 60
                    radius: 0
                    color: row.current || rowMouse.containsMouse ? Theme.background : "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: Theme.accent
                        opacity: row.current ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        anchors.leftMargin: 14
                        spacing: 11

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
                                color: row.current ? Theme.accent : Theme.foreground
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
                            text: row.current && Player.playing ? "󰏤" : "󰐊"
                            primary: row.current
                            buttonWidth: 38
                            buttonHeight: 32
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

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: trackList.count === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ""
                        color: Theme.accent
                        opacity: 0.45
                        font.family: "MesloLGS Nerd Font Mono"
                        font.pixelSize: 44
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Tracks.searchText ? "No matching tracks"
                            : "Your library is empty\nDownload a YouTube link to begin"
                        color: Theme.muted
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.5
                    }
                }
            }
        }
    }
}
