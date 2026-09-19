import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        VellumPanel {
            Layout.fillWidth: true
            implicitHeight: 268
            title: "Discord Rich Presence"
            trailing: Discord.connected ? "Connected" : Discord.enabled ? "Waiting" : "Disabled"

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 21
                        color: Theme.surfaceHigh
                        border.width: 0

                        DmsIcon {
                            anchors.centerIn: parent
                            text: "forum"
                            color: Discord.connected ? Theme.accent : Theme.muted
                            iconSize: 22
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: "Rich Presence"
                            color: Theme.foreground
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Show the current track, artist and playback time on Discord"
                            color: Theme.muted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    AccentButton {
                        text: Discord.enabled ? "Enabled" : "Disabled"
                        iconText: Discord.enabled ? "check" : "close"
                        outlined: !Discord.enabled
                        onClicked: Discord.enabled = !Discord.enabled
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.line
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    SectionLabel { text: "Application ID" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        VellumField {
                            id: applicationIdInput
                            Layout.fillWidth: true
                            indicator: "key"
                            text: Discord.applicationId
                            placeholderText: "Example: 123456789012345678"
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: RegularExpressionValidator { regularExpression: /[0-9]{0,20}/ }
                            onEditingFinished: Discord.applicationId = text
                        }

                        AccentButton {
                            text: "Reconnect"
                            iconText: "sync"
                            outlined: true
                            implicitHeight: 38
                            enabled: Discord.enabled
                            onClicked: {
                                Discord.applicationId = applicationIdInput.text
                                Discord.reconnect()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    Rectangle {
                        Layout.preferredWidth: 7
                        Layout.preferredHeight: 7
                        color: Discord.connected ? Theme.accent : Theme.muted
                        opacity: Discord.enabled ? 1 : 0.45
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Discord.status
                        color: Discord.connected ? Theme.foreground : Theme.muted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "discord.com/developers/applications"
                        color: Theme.accent
                        font.pixelSize: 9
                        font.letterSpacing: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://discord.com/developers/applications")
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "The large Discord image is the application icon. Set it under Developer Portal > General Information."
                    color: Theme.muted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
