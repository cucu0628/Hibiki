import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Mini player, modelled on Vellum's dashboard player band: a blurred wash of
// the cover behind the surface, title and transport on top, the timeline below.
Item {
    id: root

    property bool compact: false
    signal openRequested()

    property real lastVolume: 0.6

    implicitHeight: 72

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    function toggleMute() {
        if (Player.volume > 0) {
            lastVolume = Player.volume
            Player.volume = 0
        } else {
            Player.volume = lastVolume > 0 ? lastVolume : 0.6
        }
    }

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: 10
        color: Theme.surface
    }

    // Plain clipping is rectangular, so the cover wash is masked to the
    // plate's rounded shape instead.
    Rectangle {
        id: washMask
        anchors.fill: parent
        radius: plate.radius
        visible: false
        layer.enabled: true
    }

    Item {
        anchors.fill: parent
        visible: backdropSource.status === Image.Ready
        layer.enabled: visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: washMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Image {
            id: backdropSource
            anchors.fill: parent
            source: Player.coverUrl
            sourceSize: Qt.size(96, 96)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: backdropSource
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 64
            blur: 1
            saturation: 0.15
            opacity: 0.4
        }

        // Theme-colored veil, stronger to the right where the controls sit.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.2) }
                GradientStop { position: 0.6; color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.6) }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85) }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Artwork {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            radius: 6
            path: Player.coverPath

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openRequested()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: Player.title || "Nothing playing"
                        textFormat: Text.PlainText
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openRequested()
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Player.artist || "Pick a track from the library"
                        textFormat: Text.PlainText
                        color: Theme.muted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                Row {
                    spacing: 2

                    IconButton {
                        glyph: "skip_previous"
                        description: "Previous"
                        onClicked: Player.previous()
                    }
                    IconButton {
                        glyph: Player.playing ? "pause" : "play_arrow"
                        primary: true
                        description: Player.playing ? "Pause" : "Play"
                        onClicked: Player.toggle()
                    }
                    IconButton {
                        glyph: "skip_next"
                        description: "Next"
                        onClicked: Player.next()
                    }
                }

                IconButton {
                    id: volumeButton
                    glyph: Player.volume <= 0 ? "volume_off" : Player.volume < 0.35 ? "volume_down"
                         : Player.volume < 0.7 ? "volume_mid" : "volume_up"
                    description: root.compact ? "Volume " + Math.round(Player.volume * 100) + "% — scroll to change"
                                              : Player.volume > 0 ? "Mute" : "Unmute"
                    iconSize: 15
                    onClicked: root.toggleMute()

                    WheelHandler {
                        onWheel: event => {
                            let delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y
                            Player.volume = Math.max(0, Math.min(1, Player.volume + (delta > 0 ? 0.05 : -0.05)))
                        }
                    }
                }

                VellumSlider {
                    Layout.preferredWidth: 80
                    visible: !root.compact
                    from: 0
                    to: 1
                    value: Player.volume
                    wheelStep: 0.05
                    fillColor: Theme.foreground
                    description: "Volume"
                    onMoved: value => Player.volume = value
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.formatDuration(Player.position)
                    color: Theme.muted
                    font.family: "monospace"
                    font.pixelSize: 9
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
                    font.pixelSize: 9
                }
            }
        }
    }
}
