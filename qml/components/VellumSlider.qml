import QtQuick

// Rounded Material seek bar used by DMS media controls.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property bool interactive: true
    property real wheelStep: (to - from) / 20
    signal moved(real value)

    implicitHeight: 20

    function positionFor(mouseX) {
        return Math.max(from, Math.min(to, from + (mouseX / width) * (to - from)))
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
        height: root.interactive && (area.containsMouse || area.pressed) ? 6 : 4
        radius: height / 2
        color: Theme.surfaceHighest
        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, (root.value - root.from) / Math.max(1, root.to - root.from)))
            height: parent.height
            radius: height / 2
            color: Theme.accent
            Behavior on width {
                enabled: !area.pressed
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        visible: root.interactive
        width: area.pressed ? 14 : 10
        height: width
        radius: width / 2
        color: Theme.accent
        x: Math.max(0, Math.min(root.width - width,
             root.width * (root.value - root.from) / Math.max(1, root.to - root.from) - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        Behavior on width { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
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
