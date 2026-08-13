import QtQuick

// Panel frame in the shell's dashboard style: an accent section title, a
// muted trailing note and a thin accent rule above the content.
Rectangle {
    id: panel

    property string title: ""
    property string trailing: ""
    property real contentSpacing: 10
    property real bodyMargin: 14
    default property alias content: body.data

    readonly property alias bodyHeight: body.height

    radius: 0
    color: Theme.surface
    border.color: Theme.outline
    border.width: 1
    clip: true

    Item {
        id: head

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: panel.bodyMargin
        anchors.rightMargin: panel.bodyMargin
        anchors.topMargin: 12
        height: 16

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: panel.title
            color: Theme.accent
            font.pixelSize: 9
            font.letterSpacing: 3
            font.bold: true
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: panel.trailing
            color: Theme.muted
            font.pixelSize: 9
            font.letterSpacing: 1
            visible: panel.trailing !== ""
        }
    }

    Rectangle {
        id: rule

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.leftMargin: panel.bodyMargin
        anchors.rightMargin: panel.bodyMargin
        anchors.topMargin: 9
        height: 1
        color: Theme.accent
        opacity: 0.26
    }

    Item {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: rule.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: panel.bodyMargin
        anchors.rightMargin: panel.bodyMargin
        anchors.topMargin: panel.contentSpacing
        anchors.bottomMargin: 12
    }
}
