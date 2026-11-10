import QtQuick
import QtQuick.Layouts

// Full player: the cover inside its spectrum ring, a serif title, timeline,
// transport and volume. Scales down to a short window by shrinking the ring.
Item {
    id: root

    property real lastVolume: 0.6

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: 10
    }

    ColumnLayout {
        width: Math.min(parent.width - 32, 480)
        height: parent.height - 32
        anchors.centerIn: parent
        spacing: 12

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120

            VisualizerArtwork {
                readonly property int side: Math.min(parent.width, parent.height, 420)
                width: side
                height: side
                anchors.centerIn: parent
                decodeSize: 512
                path: Player.coverPath
                playing: Player.playing
                levels: Player.visualizerLevels
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: Player.title || "Nothing playing"
                textFormat: Text.PlainText
                color: Theme.foreground
                font.family: "serif"
                font.pixelSize: Player.title.length > 40 ? 18 : 21
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
            Text {
                Layout.fillWidth: true
                text: Player.artist || "Pick a track from the library"
                textFormat: Text.PlainText
                color: Theme.muted
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: Player.album.length > 0 && Player.album !== Player.artist
                text: Player.album
                textFormat: Text.PlainText
                color: Theme.outline
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.formatDuration(Player.position)
                color: Theme.muted
                font.family: "monospace"
                font.pixelSize: 10
            }
            VellumSlider {
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, Player.duration)
                value: Player.position
                wheelStep: 5000
                description: "Seek"
                onMoved: value => Player.seek(value)
            }
            Text {
                text: Player.duration > 0 ? root.formatDuration(Player.duration) : "--:--"
                color: Theme.muted
                font.family: "monospace"
                font.pixelSize: 10
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            IconButton {
                glyph: "shuffle"
                active: Player.shuffle
                description: Player.shuffle ? "Shuffle on" : "Shuffle off"
                onClicked: Player.shuffle = !Player.shuffle
            }
            IconButton {
                glyph: "skip_previous"
                buttonWidth: 36
                buttonHeight: 36
                iconSize: 18
                description: "Previous"
                onClicked: Player.previous()
            }
            IconButton {
                glyph: Player.playing ? "pause" : "play_arrow"
                primary: true
                buttonWidth: 52
                buttonHeight: 40
                iconSize: 20
                description: Player.playing ? "Pause" : "Play"
                onClicked: Player.toggle()
            }
            IconButton {
                glyph: "skip_next"
                buttonWidth: 36
                buttonHeight: 36
                iconSize: 18
                description: "Next"
                onClicked: Player.next()
            }
            IconButton {
                glyph: Player.repeatMode === 1 ? "repeat_one" : "repeat"
                active: Player.repeatMode > 0
                description: Player.repeatMode === 0 ? "Repeat off"
                           : Player.repeatMode === 1 ? "Repeat track" : "Repeat all"
                onClicked: Player.repeatMode = (Player.repeatMode + 1) % 3
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: 280
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            IconButton {
                glyph: Player.volume <= 0 ? "volume_off" : Player.volume < 0.35 ? "volume_down"
                     : Player.volume < 0.7 ? "volume_mid" : "volume_up"
                iconSize: 15
                description: Player.volume > 0 ? "Mute" : "Unmute"
                onClicked: {
                    if (Player.volume > 0) {
                        root.lastVolume = Player.volume
                        Player.volume = 0
                    } else {
                        Player.volume = root.lastVolume > 0 ? root.lastVolume : 0.6
                    }
                }
            }
            VellumSlider {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: Player.volume
                wheelStep: 0.05
                fillColor: Theme.foreground
                description: "Volume"
                onMoved: value => Player.volume = value
            }
            Text {
                Layout.preferredWidth: 32
                text: Math.round(Player.volume * 100) + "%"
                color: Theme.muted
                font.family: "monospace"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
