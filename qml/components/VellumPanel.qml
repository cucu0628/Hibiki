import QtQuick

// DMS dashboard surface with a compact Material section header.
Rectangle {
    id: panel

    property string title: ""
    property string trailing: ""
    property real contentSpacing: 12
    property real bodyMargin: 18
    default property alias content: body.data

    readonly property alias bodyHeight: body.height

    radius: Theme.cornerRadius
    color: Theme.surface
    border.width: 0
    clip: true

    Item {
        id: head

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: panel.bodyMargin
        anchors.rightMargin: panel.bodyMargin
        anchors.topMargin: 16
        height: 20

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: panel.title
            color: Theme.foreground
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: panel.trailing
            color: Theme.muted
            font.pixelSize: 11
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
        anchors.topMargin: 8
        height: 0
        visible: false
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
        anchors.bottomMargin: 16
    }
}
