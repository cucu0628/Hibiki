import QtQuick
import QtQuick.Controls

// Text input matching the shell's search field: a flat well with an accent
// hairline while it holds focus and a glyph in the gutter.
TextField {
    id: field

    property string indicator: ""
    property color fieldColor: Theme.background

    implicitHeight: 38
    leftPadding: indicator.length > 0 ? 36 : 12
    rightPadding: 12
    color: Theme.foreground
    placeholderTextColor: Theme.muted
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    font.pixelSize: 12
    selectByMouse: true

    background: Rectangle {
        radius: 0
        color: field.fieldColor
        border.width: 1
        border.color: field.activeFocus ? Theme.accent : Theme.line
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: field.indicator.length > 0
            text: field.indicator
            color: Theme.accent
            font.family: "MesloLGS Nerd Font Mono"
            font.pixelSize: 13
        }
    }
}
