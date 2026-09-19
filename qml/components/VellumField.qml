import QtQuick
import QtQuick.Controls

// DMS-style filled Material search field.
TextField {
    id: field

    property string indicator: ""
    property color fieldColor: Theme.background

    implicitHeight: 44
    leftPadding: indicator.length > 0 ? 36 : 12
    rightPadding: 12
    color: Theme.foreground
    placeholderTextColor: Theme.muted
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    font.pixelSize: 12
    selectByMouse: true

    background: Rectangle {
        radius: height / 2
        color: field.activeFocus ? Theme.surfaceHighest : Theme.surfaceHigh
        border.width: 1
        border.color: field.activeFocus ? Theme.accent : "transparent"
        Behavior on border.color { ColorAnimation { duration: 155 } }

        DmsIcon {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: field.indicator.length > 0
            text: field.indicator
            color: Theme.accent
            iconSize: 17
        }
    }
}
