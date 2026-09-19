import QtQuick
import QtQuick.Controls

// Material 3 pill button matching DMS controls.
Button {
    id: control

    property bool outlined: false
    property string iconText: ""

    implicitHeight: 40
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

            DmsIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.iconText.length > 0
                text: control.iconText
                color: control.outlined ? Theme.accent : Theme.accentText
                iconSize: 17
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                color: control.outlined ? Theme.accent : Theme.accentText
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: control.outlined ? (control.hovered ? Theme.hover : "transparent")
                                : (control.hovered ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
        border.width: 1
        border.color: control.outlined ? Theme.outline : Theme.accent
        Behavior on color { ColorAnimation { duration: 155; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
