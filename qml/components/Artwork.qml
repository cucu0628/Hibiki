import QtQuick

// Album artwork shaped like DMS' media card artwork.
Rectangle {
    id: root

    property url source
    property int decodeSize: 256

    color: Theme.surfaceHighest
    radius: Theme.cornerRadius
    clip: true

    Image {
        id: cover
        anchors.fill: parent
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

    DmsIcon {
        anchors.centerIn: parent
        visible: !cover.visible
        text: "album"
        color: Theme.accent
        opacity: 0.72
        iconSize: Math.max(16, parent.width * 0.42)
    }

}
