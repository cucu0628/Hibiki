import QtQuick
import QtQuick.Controls

// Chip button in the shell's tab style: filled with the accent when it is the
// primary action, otherwise a hairline outline that tints on hover.
Button {
    id: control

    property bool outlined: false
    property string iconText: ""

    implicitHeight: 30
    leftPadding: 14
    rightPadding: 14
    opacity: enabled ? 1 : 0.4
    hoverEnabled: true

    contentItem: Item {
        implicitWidth: chipRow.implicitWidth
        implicitHeight: chipRow.implicitHeight

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: control.iconText.length > 0 ? 8 : 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.iconText.length > 0
                text: control.iconText
                color: control.outlined ? Theme.accent : Theme.background
                font.family: "MesloLGS Nerd Font Mono"
                font.pixelSize: 13
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                color: control.outlined ? Theme.foreground : Theme.background
                font.pixelSize: 9
                font.letterSpacing: 2
                font.bold: true
            }
        }
    }

    background: Rectangle {
        radius: 0
        color: control.outlined ? (control.hovered ? Theme.hover : "transparent")
                                : (control.hovered ? Qt.lighter(Theme.accent, 1.18) : Theme.accent)
        border.width: 1
        border.color: control.outlined ? Theme.line : Theme.accent
        Behavior on color { ColorAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
