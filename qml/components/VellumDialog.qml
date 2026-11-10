import QtQuick
import QtQuick.Controls

// Centered Vellum sheet: background-colored with a hairline edge and a serif
// title, over a soft dim of the window.
Dialog {
    id: dialog

    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(320, (Overlay.overlay ? Overlay.overlay.width : 320) - 32)
    padding: 16
    topPadding: 12

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: 220; easing.type: Easing.OutQuint }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 }
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    background: Rectangle {
        color: Theme.background
        radius: 10
        border.width: 1
        border.color: Theme.line
    }

    header: Text {
        text: dialog.title
        color: Theme.foreground
        font.family: "serif"
        font.pixelSize: 18
        font.weight: Font.Medium
        leftPadding: 16
        rightPadding: 16
        topPadding: 16
        elide: Text.ElideRight
    }
}
