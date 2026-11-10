import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Hibiki

ApplicationWindow {
    id: window
    width: 760
    height: 600
    minimumWidth: 400
    minimumHeight: 460
    visible: true
    title: "Hibiki"
    color: Theme.background

    property int page: 0
    // Icon-only tabs below this width; the library drops secondary columns.
    readonly property bool compact: width < 620
    readonly property bool wideMode: width >= 1180
    readonly property bool libraryEmpty: Tracks.libraryCount === 0
    readonly property bool showWidePlayer: wideMode && !libraryEmpty

    readonly property var pages: [
        { label: "Library", icon: "library_music" },
        { label: "Playing", icon: "play_circle" },
        { label: "Downloads", icon: "download" },
        { label: "Settings", icon: "settings" }
    ]

    onPageChanged: {
        if (page === 2)
            downloadsLoader.visited = true
        else if (page === 3)
            settingsLoader.visited = true
    }

    Component.onCompleted: App.windowReady(window)
    onClosing: close => {
        close.accepted = false
        App.hideToTray()
    }

    function openPlaylistEditor(id, name) {
        playlistEditor.playlistId = id
        playlistName.text = name || ""
        playlistEditor.open()
        playlistName.forceActiveFocus()
    }

    Shortcut {
        sequence: "Space"
        onActivated: Player.toggle()
    }
    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: {
            window.page = 0
            library.focusSearch()
        }
    }
    Shortcut { sequence: "Ctrl+1"; onActivated: window.page = 0 }
    Shortcut { sequence: "Ctrl+2"; onActivated: window.page = 1 }
    Shortcut { sequence: "Ctrl+3"; onActivated: window.page = 2 }
    Shortcut { sequence: "Ctrl+4"; onActivated: window.page = 3 }

    VellumDialog {
        id: playlistEditor
        property int playlistId: -1
        title: playlistId < 0 ? "New playlist" : "Rename playlist"

        contentItem: ColumnLayout {
            spacing: 16
            VellumField {
                id: playlistName
                Layout.fillWidth: true
                placeholderText: "Playlist name"
                onAccepted: playlistEditor.save()
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8
                AccentButton { text: "Cancel"; outlined: true; onClicked: playlistEditor.close() }
                AccentButton {
                    text: playlistEditor.playlistId < 0 ? "Create" : "Save"
                    enabled: playlistName.text.trim().length > 0
                    onClicked: playlistEditor.save()
                }
            }
        }
        function save() {
            if (!playlistName.text.trim())
                return
            if (playlistId < 0) {
                let id = Tracks.createPlaylist(playlistName.text)
                if (id >= 0) {
                    Tracks.selectedPlaylistId = id
                    window.page = 0
                    close()
                }
            } else if (Tracks.renamePlaylist(playlistId, playlistName.text)) {
                close()
            }
        }
    }

    VellumDialog {
        id: deletePlaylistDialog
        title: "Delete playlist?"

        contentItem: ColumnLayout {
            spacing: 16
            Text {
                Layout.fillWidth: true
                text: "“" + Tracks.selectedPlaylistName + "” will be removed. Its tracks stay in your library."
                textFormat: Text.PlainText
                color: Theme.muted
                wrapMode: Text.WordWrap
                font.pixelSize: 12
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8
                AccentButton { text: "Cancel"; outlined: true; onClicked: deletePlaylistDialog.close() }
                AccentButton {
                    text: "Delete"
                    onClicked: {
                        Tracks.deletePlaylist(Tracks.selectedPlaylistId)
                        deletePlaylistDialog.close()
                    }
                }
            }
        }
    }

    background: Rectangle {
        color: Theme.background
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Header: wordmark on the left, page tabs on the right.
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.leftMargin: 4
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Hibiki"
                color: Theme.foreground
                font.family: "serif"
                font.pixelSize: 20
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Row {
                id: tabs
                spacing: 2

                Repeater {
                    model: window.pages

                    delegate: Rectangle {
                        id: tab
                        required property var modelData
                        required property int index
                        readonly property bool selected: window.page === index

                        width: tabRow.implicitWidth + (window.compact ? 16 : 20)
                        height: 32
                        radius: 6
                        color: selected ? Theme.surface
                             : tabArea.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 110 } }

                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData.label

                        Row {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 6

                            VellumIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: tab.modelData.icon
                                iconSize: 15
                                color: tab.selected ? Theme.accent : Theme.muted
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !window.compact
                                text: tab.modelData.label
                                color: tab.selected ? Theme.foreground : Theme.muted
                                font.pixelSize: 12
                                font.weight: tab.selected ? Font.DemiBold : Font.Normal
                            }
                        }

                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.page = tab.index
                        }

                        ToolTip.visible: window.compact && tabArea.containsMouse
                        ToolTip.text: modelData.label
                        ToolTip.delay: 600
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.page

            RowLayout {
                spacing: 12

                LibraryView {
                    id: library
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    compact: window.compact
                    onDownloadRequested: window.page = 2
                    onCreatePlaylistRequested: window.openPlaylistEditor(-1, "")
                    onRenameRequested: window.openPlaylistEditor(Tracks.selectedPlaylistId,
                                                                 Tracks.selectedPlaylistName)
                    onDeleteRequested: deletePlaylistDialog.open()
                }

                Loader {
                    Layout.preferredWidth: 380
                    Layout.fillHeight: true
                    visible: active
                    active: window.showWidePlayer
                    sourceComponent: NowPlayingView { }
                }
            }

            // Everything the player shows lives in Player, so the page (and
            // its visualizer canvas) is only kept while it is on screen.
            Loader {
                active: window.page === 1
                sourceComponent: NowPlayingView { }
            }

            Loader {
                id: downloadsLoader
                property bool visited: false
                active: visited
                sourceComponent: DownloadPanel { }
            }

            Loader {
                id: settingsLoader
                property bool visited: false
                active: visited
                sourceComponent: SettingsView { }
            }
        }

        NowPlayingBar {
            Layout.fillWidth: true
            compact: window.compact
            visible: !window.libraryEmpty && window.page !== 1
                     && !(window.page === 0 && window.showWidePlayer)
            onOpenRequested: window.page = 1
        }
    }
}
