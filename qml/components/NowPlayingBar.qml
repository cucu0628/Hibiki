import QtQuick
import QtQuick.Layouts

VellumPanel {
    id: root

    implicitHeight: 128
    title: Player.currentIndex >= 0 ? (Player.playing ? "NOW PLAYING" : "PAUSED") : "PLAYER IDLE"
    trailing: Player.album ? Player.album.toUpperCase() : "HIBIKI"

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        Artwork {
            Layout.preferredWidth: 68
            Layout.preferredHeight: 68
            Layout.alignment: Qt.AlignVCenter
            decodeSize: 256
            source: Player.coverUrl
        }

        ColumnLayout {
            Layout.preferredWidth: 210
            Layout.maximumWidth: 280
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: Player.title || "No track selected"
                color: Theme.foreground
                font.pixelSize: 17
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Player.artist || "Select a track from your library"
                color: Theme.muted
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 9

                IconButton {
                    text: "󰒟"
                    active: Player.shuffle
                    buttonWidth: 40
                    buttonHeight: 34
                    iconSize: 17
                    description: "Shuffle"
                    onClicked: Player.shuffle = !Player.shuffle
                }
                IconButton {
                    text: "󰒮"
                    buttonWidth: 46
                    buttonHeight: 40
                    iconSize: 19
                    description: "Previous"
                    onClicked: Player.previous()
                }
                IconButton {
                    text: Player.playing ? "󰏤" : "󰐊"
                    primary: true
                    buttonWidth: 58
                    buttonHeight: 40
                    iconSize: 22
                    description: Player.playing ? "Pause" : "Play"
                    onClicked: Player.toggle()
                }
                IconButton {
                    text: "󰒭"
                    buttonWidth: 46
                    buttonHeight: 40
                    iconSize: 19
                    description: "Next"
                    onClicked: Player.next()
                }
                IconButton {
                    text: Player.repeatMode === 1 ? "󰑘" : "󰑖"
                    active: Player.repeatMode > 0
                    buttonWidth: 40
                    buttonHeight: 34
                    iconSize: 17
                    description: Player.repeatMode === 0 ? "Repeat off"
                               : Player.repeatMode === 1 ? "Repeat track" : "Repeat all"
                    onClicked: Player.repeatMode = (Player.repeatMode + 1) % 3
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: root.formatDuration(Player.position)
                    color: Theme.muted
                    font.pixelSize: 9
                }
                VellumSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, Player.duration)
                    value: Player.position
                    wheelStep: 5000
                    onMoved: value => Player.seek(value)
                }
                Text {
                    text: root.formatDuration(Player.duration)
                    color: Theme.muted
                    font.pixelSize: 9
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 132
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "VOL"
                    color: Theme.accent
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(Player.volume * 100) + "%"
                    color: Theme.muted
                    font.pixelSize: 9
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: Player.volume <= 0 ? "󰖁" : Player.volume < 0.5 ? "" : ""
                    color: Theme.accent
                    font.family: "MesloLGS Nerd Font Mono"
                    font.pixelSize: 13
                }
                VellumSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: Player.volume
                    wheelStep: 0.05
                    onMoved: value => Player.volume = value
                }
            }
        }
    }
}
