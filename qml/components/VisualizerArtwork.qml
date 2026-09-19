import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source
    property int decodeSize: 512
    property bool playing: false
    property var levels: []
    property real phase: 0
    clip: true

    function levelAt(position) {
        if (!levels || levels.length === 0)
            return 0
        const scaled = position * levels.length
        const low = Math.floor(scaled) % levels.length
        const high = (low + 1) % levels.length
        const mix = scaled - Math.floor(scaled)
        return levels[low] * (1 - mix) + levels[high] * mix
    }

    Canvas {
        id: halo
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const cx = width / 2
            const cy = height / 2
            const span = Math.min(width, height)
            // Keep even the loudest peak inside the canvas. Without this
            // safety margin the outline is clipped into a flat edge and looks
            // as if it slipped below the surrounding panel.
            const baseRadius = span * 0.41
            const points = 72

            ctx.beginPath()
            for (let i = 0; i <= points; ++i) {
                const ratio = i / points
                const angle = ratio * Math.PI * 2 - Math.PI / 2
                const band = root.levelAt((ratio + root.phase * 0.025) % 1)
                const idleWave = root.playing
                    ? Math.sin(angle * 5 + root.phase) * 1.2
                    : 0
                const radius = baseRadius + 2 + band * span * 0.055 + idleWave
                const x = cx + Math.cos(angle) * radius
                const y = cy + Math.sin(angle) * radius
                if (i === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(Theme.accent.r, Theme.accent.g,
                                    Theme.accent.b, root.playing ? 0.25 : 0.12)
            ctx.fill()
            ctx.lineWidth = 2
            ctx.strokeStyle = Theme.accent
            ctx.stroke()
        }

        Connections {
            target: Player
            function onVisualizerLevelsChanged() { halo.requestPaint() }
        }
    }

    Timer {
        running: root.visible && root.playing
        interval: 33
        repeat: true
        onTriggered: {
            root.phase += 0.09
            halo.requestPaint()
        }
    }

    Item {
        id: artFrame
        width: Math.min(parent.width, parent.height) * 0.84
        height: width
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.surfaceHighest
            border.width: 2
            border.color: Theme.accent
        }

        Image {
            id: cover
            anchors.fill: parent
            source: root.source
            sourceSize.width: root.decodeSize
            sourceSize.height: root.decodeSize
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
        }

        Rectangle {
            id: circleMask
            anchors.fill: parent
            radius: width / 2
            color: "white"
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: parent
            source: cover
            maskEnabled: true
            maskSource: circleMask
            visible: cover.status === Image.Ready
        }

        DmsIcon {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: "album"
            color: Theme.accent
            opacity: 0.72
            iconSize: Math.max(32, parent.width * 0.3)
        }
    }
}
