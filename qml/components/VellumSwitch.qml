import QtQuick
import QtQuick.Controls

// Vellum Shell's settings toggle: a square track with a square knob, accent
// filled when on, outlined in the muted tone when off.
Switch {
    id: control

    property string description: ""

    implicitWidth: 46
    implicitHeight: 28
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    Accessible.name: description

    indicator: Rectangle {
        width: 46
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        radius: 0
        color: control.checked ? Theme.accent : Theme.surface
        border.width: 1
        border.color: control.checked || control.visualFocus ? Theme.accent : Theme.muted
        Behavior on color { ColorAnimation { duration: 140 } }

        Rectangle {
            width: 16
            height: 16
            radius: 0
            anchors.verticalCenter: parent.verticalCenter
            x: control.checked ? parent.width - width - 4 : 4
            color: control.checked ? Theme.surface : Theme.muted
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }

    contentItem: Item {}

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
