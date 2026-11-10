import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    function isActive(status) {
        return status === "downloading" || status === "processing" || status === "retrying"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        VellumPanel {
            Layout.fillWidth: true
            implicitHeight: chromeHeight + importColumn.implicitHeight
            title: "Import from YouTube"
            trailing: Downloads.toolsAvailable ? "" : "yt-dlp or FFmpeg missing"

            ColumnLayout {
                id: importColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    VellumField {
                        id: urlInput
                        Layout.fillWidth: true
                        indicator: "youtube"
                        placeholderText: "Video or playlist URL"
                        enabled: Downloads.toolsAvailable
                        onAccepted: if (downloadButton.enabled) downloadButton.clicked()
                    }

                    AccentButton {
                        id: downloadButton
                        text: Downloads.busy ? "Queue" : "Download"
                        iconText: "download"
                        enabled: urlInput.text.trim().length > 0 && Downloads.toolsAvailable
                        onClicked: {
                            if (Downloads.enqueue(urlInput.text))
                                urlInput.clear()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: !Downloads.toolsAvailable
                    text: "Install yt-dlp and FFmpeg, then restart Hibiki."
                    color: Theme.muted
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }

        VellumPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Queue"
            trailing: jobsView.count === 0 ? ""
                    : Downloads.busy ? "Downloading" : jobsView.count + (jobsView.count === 1 ? " job" : " jobs")

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                ListView {
                    id: jobsView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4
                    clip: true
                    model: Downloads.jobs
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: VellumCard {
                        id: job
                        required property var modelData
                        readonly property bool running: root.isActive(modelData.status)

                        width: ListView.view.width
                        height: 60
                        highlighted: running

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: job.modelData.title
                                        textFormat: Text.PlainText
                                        color: Theme.foreground
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: job.modelData.status
                                        color: job.modelData.status === "failed" ? Theme.error
                                             : job.running ? Theme.accent : Theme.muted
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }

                                VellumSlider {
                                    Layout.fillWidth: true
                                    implicitHeight: 6
                                    value: Math.max(0, job.modelData.progress)
                                    interactive: false
                                    fillColor: job.modelData.status === "failed" ? Theme.error : Theme.accent
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: job.modelData.detail || job.modelData.url
                                    textFormat: Text.PlainText
                                    color: Theme.muted
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }

                            IconButton {
                                visible: job.running
                                glyph: "close"
                                iconSize: 14
                                description: "Cancel download"
                                onClicked: Downloads.cancelCurrent()
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        width: Math.min(jobsView.width - 32, 260)
                        spacing: 12
                        visible: jobsView.count === 0

                        VellumIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: "download"
                            color: Theme.outline
                            iconSize: 32
                        }
                        Text {
                            width: parent.width
                            text: "Paste a link above; finished tracks land in your library."
                            color: Theme.muted
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                AccentButton {
                    Layout.alignment: Qt.AlignRight
                    visible: jobsView.count > 0
                    text: "Clear finished"
                    iconText: "delete_sweep"
                    outlined: true
                    onClicked: Downloads.clearFinished()
                }
            }
        }
    }
}
