import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: sections.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ScrollBar.vertical: ScrollBar {
            policy: scroller.contentHeight > scroller.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        }

        ColumnLayout {
            id: sections
            width: scroller.width
            spacing: 12

            VellumPanel {
                Layout.fillWidth: true
                implicitHeight: chromeHeight + discordColumn.implicitHeight
                title: "Discord Rich Presence"
                trailing: Discord.connected ? "Connected" : Discord.enabled ? "Waiting for Discord" : ""

                ColumnLayout {
                    id: discordColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 44
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Show what you're listening to"
                                color: Theme.foreground
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.fillWidth: true
                                text: "Track, artist and playback time on your Discord profile."
                                color: Theme.muted
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                        }

                        VellumSwitch {
                            checked: Discord.enabled
                            description: "Discord Rich Presence"
                            onToggled: Discord.enabled = checked
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.line
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        opacity: Discord.enabled ? 1 : 0.5

                        SectionLabel { text: "Application ID" }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            VellumField {
                                id: applicationIdInput
                                Layout.fillWidth: true
                                indicator: "key"
                                text: Discord.applicationId
                                placeholderText: "123456789012345678"
                                font.family: "monospace"
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: RegularExpressionValidator { regularExpression: /[0-9]{0,20}/ }
                                onEditingFinished: Discord.applicationId = text
                            }

                            AccentButton {
                                text: "Reconnect"
                                iconText: "sync"
                                outlined: true
                                enabled: Discord.enabled
                                onClicked: {
                                    Discord.applicationId = applicationIdInput.text
                                    Discord.reconnect()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 6
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Discord.connected ? Theme.accent : Theme.outline
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Discord.status
                                textFormat: Text.PlainText
                                color: Theme.muted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "The large image is your application's icon (Developer Portal → General Information). "
                                  + "<a href=\"https://discord.com/developers/applications\">Open the portal</a>"
                            textFormat: Text.StyledText
                            linkColor: Theme.accent
                            color: Theme.muted
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            onLinkActivated: link => Qt.openUrlExternally(link)

                            HoverHandler {
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                }
            }

            VellumPanel {
                Layout.fillWidth: true
                implicitHeight: chromeHeight + appearanceRow.implicitHeight
                title: "Appearance"

                RowLayout {
                    id: appearanceRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 12

                    // The palette at a glance, like Vellum's own theme cards.
                    Row {
                        spacing: 4
                        Repeater {
                            model: [Theme.background, Theme.surface, Theme.accent, Theme.foreground]
                            Rectangle {
                                required property color modelData
                                width: 16
                                height: 16
                                radius: 4
                                color: modelData
                                border.width: 1
                                border.color: Theme.line
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: Theme.themeName
                            textFormat: Text.PlainText
                            color: Theme.foreground
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Follows your Vellum Shell theme and updates when you switch it."
                            color: Theme.muted
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            VellumPanel {
                Layout.fillWidth: true
                implicitHeight: chromeHeight + shortcutGrid.implicitHeight
                title: "Shortcuts"

                ColumnLayout {
                    id: shortcutGrid
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 6

                    Repeater {
                        model: [
                            ["Space", "Play or pause"],
                            ["Ctrl+F", "Search the library"],
                            ["Ctrl+1 – 4", "Switch page"],
                            ["Enter", "Play the selected track"]
                        ]

                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                Layout.preferredWidth: 80
                                text: modelData[0]
                                color: Theme.foreground
                                font.family: "monospace"
                                font.pixelSize: 10
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData[1]
                                color: Theme.muted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
