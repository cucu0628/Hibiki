import QtQuick
import QtQuick.Controls

// Vellum search/input field: a flat well on the surface, accent outline while
// focused.
TextField {
    id: field

    property string indicator: ""
    property color fieldColor: Theme.background

    implicitHeight: 32
    leftPadding: indicator.length > 0 ? 32 : 10
    rightPadding: 10
    color: Theme.foreground
    placeholderTextColor: Theme.outline
    selectionColor: Theme.selection
    selectedTextColor: Theme.foreground
    font.pixelSize: 12
    selectByMouse: true

    background: Rectangle {
        radius: 6
        color: field.fieldColor
        border.width: 1
        border.color: field.activeFocus ? Theme.accent : Theme.line
        Behavior on border.color { ColorAnimation { duration: 110 } }

        VellumIcon {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: field.indicator.length > 0
            name: field.indicator
            color: field.activeFocus ? Theme.accent : Theme.muted
            iconSize: 14
        }
    }
}
