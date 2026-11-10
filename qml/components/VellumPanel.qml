import QtQuick

// A quiet Vellum section: flat surface, one heading and an optional muted
// metadata line on the right.
Rectangle {
    id: panel

    property string title: ""
    property string trailing: ""
    property real contentSpacing: 12
    property real bodyMargin: 16
    default property alias content: body.data

    readonly property alias bodyHeight: body.height
    // Heading row plus the gaps around it; callers add their content height.
    readonly property real chromeHeight: head.anchors.topMargin + head.height
                                         + contentSpacing + bodyMargin

    radius: 10
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
        anchors.topMargin: 14
        height: 18

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: head.width - (panel.trailing !== "" ? trailingText.width + 12 : 0)
            text: panel.title
            color: Theme.foreground
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            id: trailingText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: panel.trailing
            color: Theme.muted
            font.pixelSize: 10
            visible: panel.trailing !== ""
        }
    }

    Item {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: panel.bodyMargin
        anchors.rightMargin: panel.bodyMargin
        anchors.topMargin: panel.contentSpacing
        anchors.bottomMargin: panel.bodyMargin
    }
}
