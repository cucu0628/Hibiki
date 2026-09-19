import QtQuick

// Nested surface card using DMS' Material container hierarchy.
Rectangle {
    id: card

    property bool accentLine: false
    property bool highlighted: false

    color: highlighted ? Theme.primaryContainer : Theme.surfaceHigh
    border.width: 0
    radius: Theme.cornerRadius

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: Theme.accent
        opacity: 0.8
        visible: card.accentLine
    }
}
