import QtQuick

// Album artwork on a rounded Vellum tile. The corners are baked into the
// decoded image by the cover provider, so a tile costs one texture and no
// effect layer.
Rectangle {
    id: root

    // Local file path of the cover; empty shows the placeholder note.
    property string path
    // Decoded pixel size; defaults to the tile's on-screen size.
    property int decodeSize: Math.ceil(Math.max(width, height) * Screen.devicePixelRatio)

    color: Theme.raised
    radius: 6

    Image {
        id: cover
        anchors.fill: parent
        source: root.path && root.decodeSize > 0 && root.width > 0
                ? "image://cover/" + (root.radius / root.width).toFixed(3) + "/"
                  + encodeURIComponent(root.path)
                : ""
        sourceSize.width: root.decodeSize
        sourceSize.height: root.decodeSize
        asynchronous: true
        cache: true
    }

    VellumIcon {
        anchors.centerIn: parent
        visible: cover.status !== Image.Ready
        name: "music_note"
        color: Theme.muted
        iconSize: Math.max(16, parent.width * 0.42)
    }
}
