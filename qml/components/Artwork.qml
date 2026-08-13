import QtQuick

// Cover frame in the shell's media style: accent hairline, a dimmed image and
// an icon placeholder while nothing is loaded.
Rectangle {
    id: root

    property url source
    property int decodeSize: 256

    color: Theme.background
    border.width: 1
    border.color: Theme.accent
    clip: true

    Image {
        id: cover
        anchors.fill: parent
        anchors.margins: 1
        source: root.source
        // Thumbnails come from yt-dlp at video resolution; decoding them at
        // display size keeps list scrolling cheap.
        sourceSize.width: root.decodeSize
        sourceSize.height: root.decodeSize
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: cover
        color: Theme.background
        opacity: 0.16
        visible: cover.visible
    }

    Text {
        anchors.centerIn: parent
        visible: !cover.visible
        text: ""
        color: Theme.accent
        opacity: 0.6
        font.family: "MesloLGS Nerd Font Mono"
        font.pixelSize: Math.max(16, parent.width * 0.42)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        color: Theme.accent
        opacity: 0.9
    }
}
