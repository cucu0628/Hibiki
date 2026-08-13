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

    VellumPanel {
        anchors.fill: parent
        title: Player.currentIndex >= 0 ? (Player.playing ? "NOW PLAYING" : "PAUSED") : "PLAYER IDLE"
        trailing: Player.album ? Player.album.toUpperCase() : "HIBIKI"
        bodyMargin: 22

        RowLayout {
            id: stage
            anchors.fill: parent
            spacing: 28

            Artwork {
                readonly property int side: Math.max(180, Math.min(stage.height, stage.width * 0.4, 380))

                Layout.preferredWidth: side
                Layout.preferredHeight: side
                Layout.alignment: Qt.AlignVCenter
                decodeSize: 512
                source: Player.coverUrl
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: 5

                    Text {
                        Layout.fillWidth: true
                        text: Player.title || "No track selected"
                        color: Theme.foreground
                        font.pixelSize: 30
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Player.artist || "Select a track from your library"
                        color: Theme.muted
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Player.album || "QUIET HOURS"
                        color: Theme.accent
                        font.pixelSize: 9
                        font.letterSpacing: 2
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.accent
                    opacity: 0.28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    SectionLabel { text: "PLAYBACK" }

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
                            color: Theme.foreground
                            font.pixelSize: 10
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Player.duration > 0
                                ? "-" + root.formatDuration(Math.max(0, Player.duration - Player.position))
                                : "0:00"
                            color: Theme.muted
                            font.pixelSize: 10
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    IconButton {
                        text: "󰒟"
                        active: Player.shuffle
                        buttonWidth: 42
                        buttonHeight: 46
                        iconSize: 19
                        description: "Shuffle"
                        onClicked: Player.shuffle = !Player.shuffle
                    }
                    IconButton {
                        text: "󰒮"
                        buttonWidth: 52
                        buttonHeight: 46
                        iconSize: 21
                        description: "Previous"
                        onClicked: Player.previous()
                    }
                    IconButton {
                        text: Player.playing ? "󰏤" : "󰐊"
                        primary: true
                        buttonWidth: 72
                        buttonHeight: 46
                        iconSize: 26
                        description: Player.playing ? "Pause" : "Play"
                        onClicked: Player.toggle()
                    }
                    IconButton {
                        text: "󰒭"
                        buttonWidth: 52
                        buttonHeight: 46
                        iconSize: 21
                        description: "Next"
                        onClicked: Player.next()
                    }
                    IconButton {
                        text: Player.repeatMode === 1 ? "󰑘" : "󰑖"
                        active: Player.repeatMode > 0
                        buttonWidth: 42
                        buttonHeight: 46
                        iconSize: 19
                        description: Player.repeatMode === 0 ? "Repeat off"
                                   : Player.repeatMode === 1 ? "Repeat track" : "Repeat all"
                        onClicked: Player.repeatMode = (Player.repeatMode + 1) % 3
                    }

                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: 10

                    Text {
                        text: "VOL"
                        color: Theme.accent
                        font.pixelSize: 9
                        font.letterSpacing: 2
                        font.bold: true
                    }
                    Text {
                        text: Player.volume <= 0 ? "󰖁" : Player.volume < 0.5 ? "" : ""
                        color: Theme.accent
                        font.family: "MesloLGS Nerd Font Mono"
                        font.pixelSize: 14
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
                        Layout.preferredWidth: 32
                        text: Math.round(Player.volume * 100) + "%"
                        color: Theme.muted
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
