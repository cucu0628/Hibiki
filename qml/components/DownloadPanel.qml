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
            implicitHeight: 124
            title: "Import from YouTube"
            trailing: Downloads.toolsAvailable ? "yt-dlp and FFmpeg ready" : "Tools missing"

            RowLayout {
                anchors.fill: parent
                spacing: 10

                VellumField {
                    id: urlInput
                    Layout.fillWidth: true
                    indicator: "video_library"
                    placeholderText: "YouTube video or playlist URL"
                    onAccepted: downloadButton.clicked()
                }

                AccentButton {
                    id: downloadButton
                    text: Downloads.busy ? "Add to queue" : "Download"
                    iconText: "download"
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
            title: "Download queue"
            trailing: jobsView.count + (jobsView.count === 1 ? " job" : " jobs")

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
                        text: "Clear finished"
                        iconText: "delete_sweep"
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
                        color: Theme.surfaceHigh

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
                                    text: modelData.status
                                    color: modelData.status === "failed" ? Theme.error : Theme.accent
                                    font.pixelSize: 11
                                    font.bold: true
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

                        DmsIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "download"
                            color: Theme.accent
                            opacity: 0.45
                            iconSize: 40
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
