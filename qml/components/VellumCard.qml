import QtQuick

// Inner tile on a panel: a slightly lifted surface, accent-tinted while busy.
Rectangle {
    id: card

    property bool highlighted: false

    color: highlighted ? Theme.selection : Theme.raised
    border.width: 0
    radius: 8
}
