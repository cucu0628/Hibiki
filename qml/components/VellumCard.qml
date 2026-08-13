import QtQuick

// Plain surface tile, used where a panel header would be noise.
Rectangle {
    id: card

    property bool accentLine: false
    property bool highlighted: false

    color: Theme.surface
    border.width: 1
    border.color: highlighted ? Theme.accent : Theme.outline
    radius: 0

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: Theme.accent
        opacity: 0.5
        visible: card.accentLine
    }
}
