import QtQuick
import QtQuick.Controls

// Transport control drawn like the shell's media buttons: a flat rectangle
// with a hairline border, or an accent block for the primary action.
Button {
    id: control

    property bool primary: false
    property bool active: true
    property int buttonWidth: primary ? 64 : 50
    property int buttonHeight: 46
    property int iconSize: primary ? 24 : 20
    property string description: ""

    implicitWidth: buttonWidth
    implicitHeight: buttonHeight
    padding: 0
    hoverEnabled: true
    font.family: "MesloLGS Nerd Font Mono"
    font.pixelSize: iconSize

    ToolTip.visible: hovered && description.length > 0
    ToolTip.text: description
    ToolTip.delay: 450

    contentItem: Text {
        text: control.text
        color: control.primary ? Theme.background : Theme.foreground
        opacity: control.active ? 1 : 0.35
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 0
        color: control.primary ? (control.hovered ? Qt.lighter(Theme.accent, 1.18) : Theme.accent)
                               : (control.hovered ? Theme.hover : "transparent")
        border.width: control.primary ? 0 : 1
        border.color: Theme.line
        Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
