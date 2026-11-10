import QtQuick
import QtQuick.Controls

// Vellum text button. Filled for the main action of a panel, outlined (a thin
// line over the surface) for everything else.
Button {
    id: control

    property bool outlined: false
    property string iconText: ""

    implicitHeight: 32
    leftPadding: 12
    rightPadding: 12
    opacity: enabled ? 1 : 0.4
    hoverEnabled: true
    focusPolicy: Qt.TabFocus

    contentItem: Item {
        implicitWidth: chipRow.implicitWidth
        implicitHeight: chipRow.implicitHeight

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: control.iconText.length > 0 ? 6 : 0

            VellumIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.iconText.length > 0
                name: control.iconText
                color: control.outlined ? Theme.foreground : Theme.accentText
                iconSize: 14
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                color: control.outlined ? Theme.foreground : Theme.accentText
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }

    background: Rectangle {
        radius: 6
        color: control.outlined
            ? (control.hovered ? Theme.hover : "transparent")
            : (control.hovered ? Qt.lighter(Theme.accent, 1.12) : Theme.accent)
        border.width: control.outlined || control.visualFocus ? 1 : 0
        border.color: control.visualFocus ? Theme.accent : Theme.line
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
