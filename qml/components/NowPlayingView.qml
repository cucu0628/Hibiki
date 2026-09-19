import QtQuick
import QtQuick.Layouts

Item {
    id: root

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: Theme.cornerRadius
        clip: true

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 540)
            height: Math.min(parent.height - 40, 620)
            spacing: 10

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 180
                Layout.maximumHeight: 290

                VisualizerArtwork {
                    readonly property int side: Math.min(parent.width * 0.62, parent.height - 8, 270)
                    width: side
                    height: side
                    anchors.centerIn: parent
                    decodeSize: 512
                    source: Player.coverUrl
                    playing: Player.playing
                    levels: Player.visualizerLevels
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: Player.title || "No track selected"
                    color: Theme.foreground
                    font.pixelSize: Player.title.length > 42 ? 18 : 22
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
                Text {
                    Layout.fillWidth: true
                    text: Player.artist || "Select a track from your library"
                    color: Theme.muted
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Player.album || " "
                    color: Theme.muted
                    opacity: 0.72
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 24
                Layout.topMargin: 8
                spacing: 1

                VellumSlider {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    from: 0
                    to: Math.max(1, Player.duration)
                    value: Player.position
                    wheelStep: 5000
                    onMoved: value => Player.seek(value)
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.formatDuration(Player.position)
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Player.duration > 0 ? root.formatDuration(Player.duration) : "--:--"
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 12

                IconButton {
                    text: "shuffle"
                    active: Player.shuffle
                    description: "Shuffle"
                    onClicked: Player.shuffle = !Player.shuffle
                }
                IconButton {
                    text: "skip_previous"
                    buttonWidth: 48
                    buttonHeight: 48
                    iconSize: 22
                    description: "Previous"
                    onClicked: Player.previous()
                }
                IconButton {
                    text: Player.playing ? "pause" : "play_arrow"
                    primary: true
                    buttonWidth: 62
                    buttonHeight: 62
                    iconSize: 27
                    description: Player.playing ? "Pause" : "Play"
                    onClicked: Player.toggle()
                }
                IconButton {
                    text: "skip_next"
                    buttonWidth: 48
                    buttonHeight: 48
                    iconSize: 22
                    description: "Next"
                    onClicked: Player.next()
                }
                IconButton {
                    text: Player.repeatMode === 1 ? "repeat_one" : "repeat"
                    active: Player.repeatMode > 0
                    description: Player.repeatMode === 0 ? "Repeat off"
                               : Player.repeatMode === 1 ? "Repeat track" : "Repeat all"
                    onClicked: Player.repeatMode = (Player.repeatMode + 1) % 3
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 48
                Layout.rightMargin: 48
                Layout.topMargin: 8
                implicitHeight: 48
                radius: height / 2
                color: Theme.surfaceHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    DmsIcon {
                        text: Player.volume <= 0 ? "volume_off" : Player.volume < 0.5 ? "volume_down" : "volume_up"
                        color: Theme.foreground
                        iconSize: 19
                    }
                    VellumSlider {
                        Layout.fillWidth: true
                        from: 0
                        to: 1
                        value: Player.volume
                        wheelStep: 0.05
                        onMoved: value => Player.volume = value
                    }
                    Text {
                        Layout.preferredWidth: 34
                        text: Math.round(Player.volume * 100) + "%"
                        color: Theme.muted
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
