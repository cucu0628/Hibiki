import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    implicitHeight: 104
    color: Theme.surface
    radius: Theme.cornerRadius
    readonly property bool compact: width < 780

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    RowLayout {
        width: Math.min(parent.width - 24, 1200)
        height: parent.height - 24
        anchors.centerIn: parent
        spacing: root.compact ? 10 : 14

        Artwork {
            Layout.preferredWidth: root.compact ? 72 : 80
            Layout.preferredHeight: root.compact ? 72 : 80
            decodeSize: 256
            source: Player.coverUrl
        }

        ColumnLayout {
            Layout.preferredWidth: root.compact ? 150 : 210
            Layout.maximumWidth: root.compact ? 170 : 260
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: Player.title || "No track selected"
                color: Theme.foreground
                font.pixelSize: 15
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Player.artist || "Select from your library"
                color: Theme.muted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: root.compact ? 220 : 300
            spacing: 4

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                IconButton {
                    text: "skip_previous"
                    buttonWidth: 40
                    buttonHeight: 40
                    iconSize: 19
                    description: "Previous"
                    onClicked: Player.previous()
                }
                IconButton {
                    text: Player.playing ? "pause" : "play_arrow"
                    primary: true
                    buttonWidth: 48
                    buttonHeight: 48
                    iconSize: 22
                    description: Player.playing ? "Pause" : "Play"
                    onClicked: Player.toggle()
                }
                IconButton {
                    text: "skip_next"
                    buttonWidth: 40
                    buttonHeight: 40
                    iconSize: 19
                    description: "Next"
                    onClicked: Player.next()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.formatDuration(Player.position)
                    color: Theme.muted
                    font.pixelSize: 10
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
                    font.pixelSize: 10
                }
            }
        }

        RowLayout {
            Layout.preferredWidth: root.compact ? 110 : 150
            spacing: root.compact ? 6 : 8

            DmsIcon {
                text: Player.volume <= 0 ? "volume_off" : Player.volume < 0.5 ? "volume_down" : "volume_up"
                color: Theme.foreground
                iconSize: 18
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
