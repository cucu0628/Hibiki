import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property bool compact: false
    property int targetTrackId: -1

    signal downloadRequested()
    signal createPlaylistRequested()
    signal renameRequested()
    signal deleteRequested()

    readonly property bool inPlaylist: Tracks.selectedPlaylistId >= 0
    // "All tracks" first, then the user's playlists, as one chip strip.
    readonly property var sources: {
        let list = [{ id: -1, name: "All tracks", count: Tracks.libraryCount }]
        let playlists = Tracks.playlists
        for (let i = 0; i < playlists.length; ++i)
            list.push(playlists[i])
        return list
    }

    function focusSearch() {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    function formatDuration(milliseconds) {
        if (!milliseconds || milliseconds < 0)
            return "0:00"
        let seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0")
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            anchors.bottomMargin: 8
            spacing: 8

            // Title, one line of metadata, and the actions for this source.
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                spacing: 4

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.inPlaylist ? Tracks.selectedPlaylistName
                             : Tracks.libraryCount === 0 ? "Welcome to Hibiki" : "Library"
                        textFormat: Text.PlainText
                        color: Theme.foreground
                        font.family: "serif"
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Tracks.scanning ? "Scanning your music folder…"
                             : Tracks.searchText ? Tracks.count + (Tracks.count === 1 ? " match" : " matches")
                             : Tracks.count + (Tracks.count === 1 ? " track" : " tracks")
                        color: Tracks.scanning ? Theme.accent : Theme.muted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        visible: Tracks.libraryCount > 0 || Tracks.scanning
                    }
                }

                IconButton {
                    visible: root.inPlaylist
                    glyph: "edit"
                    description: "Rename playlist"
                    onClicked: root.renameRequested()
                }
                IconButton {
                    visible: root.inPlaylist
                    glyph: "delete"
                    description: "Delete playlist"
                    onClicked: root.deleteRequested()
                }
                IconButton {
                    id: rescanButton
                    glyph: "refresh"
                    description: Tracks.scanning ? "Scanning…" : "Rescan library"
                    enabled: !Tracks.scanning
                    onClicked: Tracks.rescan()

                    NumberAnimation {
                        target: rescanButton.contentItem
                        property: "rotation"
                        running: Tracks.scanning
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) rescanButton.contentItem.rotation = 0
                    }
                }
            }

            VellumField {
                id: searchInput
                Layout.fillWidth: true
                visible: Tracks.libraryCount > 0
                indicator: "search"
                placeholderText: "Search title, artist, album"
                onTextChanged: Tracks.searchText = text
                Keys.onEscapePressed: {
                    clear()
                    focus = false
                }
                Keys.onDownPressed: {
                    trackList.forceActiveFocus()
                    if (trackList.currentIndex < 0)
                        trackList.currentIndex = 0
                }
            }

            // Source strip: All tracks + playlists, scrolls sideways when the
            // window is narrow.
            ListView {
                id: sourceStrip
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                visible: Tracks.libraryCount > 0
                orientation: ListView.Horizontal
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.sources

                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool selected: Tracks.selectedPlaylistId === modelData.id

                    width: chipRow.implicitWidth + 20
                    height: 28
                    radius: 6
                    color: selected ? Theme.selection
                         : chipArea.containsMouse ? Theme.hover : "transparent"
                    border.width: selected ? 0 : 1
                    border.color: Theme.line
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.name
                            textFormat: Text.PlainText
                            color: chip.selected ? Theme.foreground : Theme.muted
                            font.pixelSize: 11
                            font.weight: chip.selected ? Font.DemiBold : Font.Normal
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: chip.modelData.id >= 0
                            text: chip.modelData.count
                            color: chip.selected ? Theme.accent : Theme.outline
                            font.family: "monospace"
                            font.pixelSize: 9
                        }
                    }

                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Tracks.selectedPlaylistId = chip.modelData.id
                    }
                }

                footer: Item {
                    width: 32
                    height: 28

                    IconButton {
                        anchors.right: parent.right
                        buttonWidth: 28
                        buttonHeight: 28
                        iconSize: 14
                        glyph: "add"
                        description: "New playlist"
                        onClicked: root.createPlaylistRequested()
                    }
                }
            }

            ListView {
                id: trackList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                spacing: 2
                clip: true
                model: Tracks
                reuseItems: true
                cacheBuffer: 400
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: false
                currentIndex: -1

                Keys.onReturnPressed: if (currentIndex >= 0) Player.playTrack(currentIndex)
                Keys.onEnterPressed: if (currentIndex >= 0) Player.playTrack(currentIndex)

                ScrollBar.vertical: ScrollBar {
                    id: libraryScroll
                    width: 10
                    policy: trackList.contentHeight > trackList.height
                        ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    interactive: true
                    minimumSize: 0.08

                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: width / 2
                        color: libraryScroll.pressed ? Theme.accent : Theme.outline
                        opacity: libraryScroll.pressed || libraryScroll.hovered ? 0.9 : 0.45
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    background: Item { implicitWidth: 10 }
                }

                Connections {
                    target: Player
                    function onTrackChanged() {
                        let index = Tracks.indexOfFilePath(Player.currentFilePath)
                        if (index < 0)
                            return
                        Qt.callLater(function() {
                            trackList.positionViewAtIndex(index, ListView.Contain)
                        })
                    }
                }

                delegate: Rectangle {
                    id: row
                    required property int index
                    required property int trackId
                    required property string filePath
                    required property string title
                    required property string artist
                    required property string album
                    required property string coverPath
                    required property int duration
                    readonly property bool current: filePath === Player.currentFilePath
                    readonly property bool hovered: rowHover.hovered
                    readonly property bool focused: trackList.activeFocus && ListView.isCurrentItem

                    width: ListView.view.width - (libraryScroll.visible ? 12 : 0)
                    height: 48
                    radius: 6
                    color: row.current ? Theme.selection
                         : row.hovered || row.focused ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 110 } }

                    HoverHandler { id: rowHover }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: trackList.currentIndex = row.index
                        onDoubleClicked: Player.playTrack(row.index)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 8
                        spacing: 8

                        // Index, a live "playing" meter, or a play button on hover.
                        Item {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28

                            Text {
                                anchors.centerIn: parent
                                visible: !row.hovered && !row.current
                                text: row.index + 1
                                color: Theme.outline
                                font.family: "monospace"
                                font.pixelSize: 10
                            }

                            // Loaded only where shown, so idle rows neither hold the
                            // controls nor follow the visualizer levels.
                            Loader {
                                anchors.centerIn: parent
                                active: !row.hovered && row.current
                                sourceComponent: Row {
                                    spacing: 2

                                    Repeater {
                                        model: 3
                                        Rectangle {
                                            required property int index
                                            readonly property real level: {
                                                let levels = Player.visualizerLevels
                                                if (!Player.playing || !levels || levels.length === 0)
                                                    return 0.25
                                                let at = Math.min(levels.length - 1,
                                                                  Math.floor((index + 0.5) * levels.length / 3))
                                                return Math.max(0.2, Math.min(1, levels[at]))
                                            }
                                            anchors.bottom: parent.bottom
                                            width: 3
                                            height: 3 + 9 * level
                                            radius: 1.5
                                            color: Theme.accent
                                            Behavior on height { NumberAnimation { duration: 90 } }
                                        }
                                    }
                                }
                            }

                            Loader {
                                anchors.fill: parent
                                active: row.hovered
                                sourceComponent: IconButton {
                                    glyph: row.current && Player.playing ? "pause" : "play_arrow"
                                    iconSize: 15
                                    description: row.current && Player.playing ? "Pause" : "Play"
                                    onClicked: row.current ? Player.toggle() : Player.playTrack(row.index)
                                }
                            }
                        }

                        Artwork {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 6
                            path: row.coverPath
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: row.title
                                textFormat: Text.PlainText
                                color: row.current ? Theme.accent : Theme.foreground
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: row.artist || row.album || "Unknown artist"
                                textFormat: Text.PlainText
                                color: Theme.muted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        // Duration, swapped for the row actions under the pointer.
                        Item {
                            Layout.preferredWidth: root.inPlaylist ? 60 : 32
                            Layout.preferredHeight: 28

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !row.hovered
                                text: root.formatDuration(row.duration)
                                color: Theme.muted
                                font.family: "monospace"
                                font.pixelSize: 10
                            }

                            Loader {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                active: row.hovered
                                sourceComponent: Row {
                                    spacing: 0

                                    IconButton {
                                        buttonWidth: 28
                                        buttonHeight: 28
                                        iconSize: 15
                                        glyph: "playlist_add"
                                        description: "Add to playlist"
                                        onClicked: {
                                            root.targetTrackId = row.trackId
                                            addToPlaylistDialog.open()
                                        }
                                    }
                                    IconButton {
                                        visible: root.inPlaylist
                                        buttonWidth: 28
                                        buttonHeight: 28
                                        iconSize: 15
                                        glyph: "playlist_remove"
                                        description: "Remove from this playlist"
                                        onClicked: Tracks.removeFromPlaylist(Tracks.selectedPlaylistId, row.trackId)
                                    }
                                }
                            }
                        }
                    }
                }

                // One sentence and, when there is one, the action that fixes it.
                Column {
                    anchors.centerIn: parent
                    width: Math.min(trackList.width - 32, 280)
                    spacing: 12
                    visible: trackList.count === 0 && !Tracks.scanning

                    VellumIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: Tracks.searchText ? "search_off"
                            : root.inPlaylist ? "queue_music" : "library_music"
                        color: Theme.outline
                        iconSize: 32
                    }
                    Text {
                        width: parent.width
                        text: Tracks.searchText ? "Nothing matches “" + Tracks.searchText + "”."
                            : root.inPlaylist ? "This playlist is empty. Add tracks from All tracks with the playlist button."
                            : "Your library is empty. Download a track or playlist to start listening."
                        textFormat: Text.PlainText
                        color: Theme.muted
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                    AccentButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !Tracks.searchText
                        text: root.inPlaylist ? "Show all tracks" : "Open downloads"
                        iconText: root.inPlaylist ? "library_music" : "download"
                        onClicked: {
                            if (root.inPlaylist)
                                Tracks.selectedPlaylistId = -1
                            else
                                root.downloadRequested()
                        }
                    }
                }
            }
        }
    }

    VellumDialog {
        id: addToPlaylistDialog
        title: "Add to playlist"

        contentItem: ColumnLayout {
            spacing: 8
            Text {
                visible: Tracks.playlists.length === 0
                text: "You have no playlists yet."
                color: Theme.muted
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 12
            }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Tracks.playlists.length * 38, 266)
                visible: Tracks.playlists.length > 0
                clip: true
                spacing: 2
                model: Tracks.playlists
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 36
                    radius: 6
                    color: addMouse.containsMouse ? Theme.hover : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8
                        VellumIcon { name: "queue_music"; color: Theme.muted; iconSize: 15 }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            textFormat: Text.PlainText
                            color: Theme.foreground
                            elide: Text.ElideRight
                            font.pixelSize: 12
                        }
                        Text {
                            text: modelData.count
                            color: Theme.outline
                            font.family: "monospace"
                            font.pixelSize: 9
                        }
                    }
                    MouseArea {
                        id: addMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Tracks.addToPlaylist(modelData.id, root.targetTrackId)
                            addToPlaylistDialog.close()
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8
                AccentButton {
                    text: "New playlist"
                    iconText: "add"
                    outlined: true
                    onClicked: {
                        addToPlaylistDialog.close()
                        root.createPlaylistRequested()
                    }
                }
                Item { Layout.fillWidth: true }
                AccentButton {
                    text: "Close"
                    outlined: true
                    onClicked: addToPlaylistDialog.close()
                }
            }
        }
    }
}
