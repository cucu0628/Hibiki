import QtQuick
import QtQuick.Controls

// Square Vellum control: a quiet hover wash for secondary actions, a solid
// accent tile for the primary one (play/pause).
Button {
    id: control

    property string glyph: ""
    property bool primary: false
    property bool active: false
    property int buttonWidth: primary ? 44 : 32
    property int buttonHeight: 32
    property int iconSize: primary ? 18 : 16
    property string description: ""

    implicitWidth: buttonWidth
    implicitHeight: buttonHeight
    padding: 0
    hoverEnabled: true
    focusPolicy: Qt.TabFocus

    Accessible.name: description

    ToolTip.visible: hovered && description.length > 0
    ToolTip.text: description
    ToolTip.delay: 600

    contentItem: VellumIcon {
        name: control.glyph
        iconSize: control.iconSize
        color: control.primary ? Theme.accentText
             : control.active ? Theme.accent : Theme.foreground
        opacity: control.enabled ? 1 : 0.35
    }

    background: Rectangle {
        radius: 6
        color: control.primary
            ? (control.down ? Qt.darker(Theme.accent, 1.08)
               : control.hovered ? Qt.lighter(Theme.accent, 1.12) : Theme.accent)
            : (control.down ? Theme.line : control.hovered && control.enabled ? Theme.hover : "transparent")
        border.width: control.visualFocus ? 1 : 0
        border.color: Theme.accent
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    HoverHandler {
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
