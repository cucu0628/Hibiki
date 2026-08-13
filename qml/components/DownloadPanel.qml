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
            implicitHeight: 108
            title: "YOUTUBE IMPORT"
            trailing: Downloads.toolsAvailable ? "YT-DLP / FFMPEG READY" : "TOOLS MISSING"

            RowLayout {
                anchors.fill: parent
                spacing: 10

                VellumField {
                    id: urlInput
                    Layout.fillWidth: true
                    indicator: ""
                    placeholderText: "YouTube video or playlist URL"
                    onAccepted: downloadButton.clicked()
                }

                AccentButton {
                    id: downloadButton
                    text: Downloads.busy ? "ADD TO QUEUE" : "DOWNLOAD"
                    iconText: ""
                    implicitHeight: 38
                    enabled: urlInput.text.trim().length > 0 && Downloads.toolsAvailable
                    onClicked: {
                        if (Downloads.enqueue(urlInput.text))
                            urlInput.clear()
                    }
                }
            }
        }

        VellumPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "DOWNLOAD QUEUE"
            trailing: jobsView.count + (jobsView.count === 1 ? " JOB" : " JOBS")

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: Downloads.busy ? "Download running" : "Queue idle"
                        color: Theme.muted
                        font.pixelSize: 10
                    }

                    AccentButton {
                        text: "CLEAR FINISHED"
                        iconText: "󰆴"
                        outlined: true
                        onClicked: Downloads.clearFinished()
                    }
                }

                ListView {
                    id: jobsView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    clip: true
                    model: Downloads.jobs
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: VellumCard {
                        required property var modelData
                        width: ListView.view.width
                        height: 70
                        accentLine: modelData.status === "downloading"
                                 || modelData.status === "processing"
                        color: Theme.background

                        Column {
                            anchors.fill: parent
                            anchors.margins: 11
                            anchors.leftMargin: 15
                            spacing: 6

                            Item {
                                width: parent.width
                                height: 15

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: statusText.left
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.title
                                    color: Theme.foreground
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: statusText
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.status.toUpperCase()
                                    color: modelData.status === "failed" ? "#eb6f92" : Theme.accent
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1
                                }
                            }

                            VellumSlider {
                                width: parent.width
                                implicitHeight: 6
                                value: modelData.progress
                                interactive: false
                            }

                            Text {
                                width: parent.width
                                text: modelData.detail || modelData.url
                                color: Theme.muted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: jobsView.count === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: ""
                            color: Theme.accent
                            opacity: 0.45
                            font.family: "MesloLGS Nerd Font Mono"
                            font.pixelSize: 40
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Downloads.toolsAvailable ? "No downloads in the queue"
                                                           : "yt-dlp or FFmpeg is missing"
                            color: Theme.muted
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
