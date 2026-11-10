import QtQuick

// Thin Vellum timeline: a hairline track that thickens under the pointer.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property bool interactive: true
    property real wheelStep: (to - from) / 20
    property color fillColor: Theme.accent
    property string description: ""
    signal moved(real value)

    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / Math.max(0.0001, to - from)))
    readonly property bool engaged: interactive && (area.containsMouse || area.pressed || activeFocus)

    implicitHeight: 16
    activeFocusOnTab: interactive

    Accessible.role: Accessible.Slider
    Accessible.name: description

    Keys.onLeftPressed: moved(steppedValue(-1))
    Keys.onRightPressed: moved(steppedValue(1))

    function positionFor(mouseX) {
        return Math.max(from, Math.min(to, from + (mouseX / Math.max(1, width)) * (to - from)))
    }

    function steppedValue(direction) {
        if (wheelStep <= 0)
            return value
        let normalized = (value - from) / wheelStep
        let nearest = Math.round(normalized)
        if (Math.abs(normalized - nearest) < 0.0001)
            normalized = nearest
        let steps = direction > 0 ? Math.floor(normalized) + 1
                                  : Math.ceil(normalized) - 1
        return Math.max(from, Math.min(to, from + steps * wheelStep))
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.engaged ? 5 : 3
        radius: height / 2
        color: Theme.line
        Behavior on height { NumberAnimation { duration: 90 } }

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: height / 2
            color: root.fillColor
            Behavior on width {
                enabled: !area.pressed
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        visible: root.interactive
        width: 10
        height: 10
        radius: 5
        color: root.fillColor
        opacity: root.engaged ? 1 : 0
        scale: area.pressed ? 1.2 : 1
        x: Math.max(0, Math.min(root.width - width, root.width * root.ratio - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        Behavior on opacity { NumberAnimation { duration: 110 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: mouse => root.moved(root.positionFor(mouse.x))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(root.positionFor(mouse.x))
        }
        onWheel: wheel => {
            let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y
            if (delta !== 0)
                root.moved(root.steppedValue(delta))
            wheel.accepted = true
        }
    }
}
