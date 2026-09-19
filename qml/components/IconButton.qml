import QtQuick
import QtQuick.Controls

// Rounded DMS media action. The primary play button uses the active theme's
// primary color; secondary actions get the Material state layer on hover.
Button {
    id: control

    property bool primary: false
    property bool active: false
    property int buttonWidth: primary ? 56 : 44
    property int buttonHeight: primary ? 56 : 44
    property int iconSize: primary ? 24 : 20
    property string description: ""

    implicitWidth: buttonWidth
    implicitHeight: buttonHeight
    padding: 0
    hoverEnabled: true
    font.family: DmsFonts.icons
    font.pixelSize: iconSize
    font.variableAxes: {
        "FILL": control.primary || control.active ? 1 : 0,
        "GRAD": -25,
        "opsz": 24,
        "wght": control.primary || control.active ? 500 : 400
    }

    ToolTip.visible: hovered && description.length > 0
    ToolTip.text: description
    ToolTip.delay: 450

    contentItem: Text {
        text: control.text
        color: control.primary ? Theme.accentText
                               : control.active ? Theme.accent : Theme.foreground
        opacity: control.enabled ? 1 : 0.35
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: height / 2
        color: control.primary ? (control.hovered ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
                               : (control.hovered ? Theme.hover : "transparent")
        border.width: 0
        Behavior on color { ColorAnimation { duration: 155; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
