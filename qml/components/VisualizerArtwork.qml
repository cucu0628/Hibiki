import QtQuick
import QtQuick.Effects

Item {
    id: root

    property url source
    property int decodeSize: 512
    property bool playing: false
    property var levels: []
    property real phase: 0

    function levelAt(position) {
        if (!levels || levels.length === 0)
            return 0
        const scaled = position * (levels.length - 1)
        const low = Math.floor(scaled)
        const high = Math.min(low + 1, levels.length - 1)
        const mix = scaled - low
        return levels[low] * (1 - mix) + levels[high] * mix
    }

    Canvas {
        id: spectrum
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            const span = Math.min(width, height)
            const centerX = width / 2
            const centerY = height / 2
            const radius = span * 0.355
            const bars = 72
            const accent = Theme.accent

            // Quiet concentric guides keep the visualizer visible when paused.
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
            ctx.lineWidth = 1
            ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.22)
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(centerX, centerY, span * 0.465, 0, Math.PI * 2)
            ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.09)
            ctx.stroke()

            ctx.lineCap = "round"
            ctx.lineWidth = Math.max(2, span * 0.009)
            for (let i = 0; i < bars; ++i) {
                const position = i / bars
                const angle = position * Math.PI * 2 - Math.PI / 2
                const mirrored = position <= 0.5 ? position * 2 : (1 - position) * 2
                const level = root.playing ? root.levelAt(mirrored) : 0
                const movement = root.playing ? (Math.sin(root.phase + i * 0.54) + 1) * 0.5 : 0
                const length = 4 + level * span * (0.064 + movement * 0.013)
                const start = radius + 3
                const end = start + length

                ctx.beginPath()
                ctx.moveTo(centerX + Math.cos(angle) * start,
                           centerY + Math.sin(angle) * start)
                ctx.lineTo(centerX + Math.cos(angle) * end,
                           centerY + Math.sin(angle) * end)
                ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b,
                                          root.playing ? 0.46 + level * 0.52 : 0.3)
                ctx.stroke()
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    onLevelsChanged: spectrum.requestPaint()
    onPlayingChanged: spectrum.requestPaint()

    Connections {
        target: Theme
        function onThemeChanged() { spectrum.requestPaint() }
    }

    Timer {
        running: root.visible && root.playing
        interval: 50
        repeat: true
        onTriggered: {
            root.phase += 0.13
            spectrum.requestPaint()
        }
    }

    Item {
        id: artFrame
        width: Math.min(parent.width, parent.height) * 0.62
        height: width
        anchors.centerIn: parent

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.surfaceHighest
            border.width: 3
            border.color: Theme.primaryContainer
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
