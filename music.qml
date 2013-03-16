import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import QtMultimedia 5.0
import Qt.labs.folderlistmodel 1.0
import "script.js" as Jarray
import "storage.js" as Storage

/*!
    \brief MainView with Tabs element.
           First Tab has a single Label and
           second Tab has a single ToolbarAction.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "music"
    applicationName: "Music"

    width: units.gu(50)
    height: units.gu(75)

    PageStack {
        id: pageStack
        anchors.fill: parent

        Component.onCompleted: {
            pageStack.push(page)
            Storage.initialize()
            console.debug("INITIALIZED")
            if (Storage.getSetting("initialized") !== "true") {
                // initialize settings
                console.debug("reset settings")
                Storage.setSetting("initialized", "true")
                Storage.setSetting("currentfolder", "/")
            }
        }
        Page {
            id: page
            property int playing: 0
            property int loaded: 0
            property variant arr: []
            title: i18n.tr("Music")
            Component {
                id: highlight
                Rectangle {
                    width: parent.width; height: 40
                    border.color: "#DD4814";
                    border.width: 3
                    Behavior on y {
                        SpringAnimation {
                            spring: 3
                            damping: 0.2
                        }
                    }
                }
            }
            ListView {
                id: playlist
                height: parent.height - units.gu(8)
                width: parent.width
                highlight: highlight
                highlightFollowsCurrentItem: true

                Popover {
                    id: popover
                    property string artist
                    property string album
                    property string song

                    ListItem.Standard {
                        text: "Artist: " + popover.artist + "\nAlbum: " + popover.album + "\nSong: " + popover.song
                    }
                    visible: false
                }

                MediaPlayer {
                    id: playMusic
                    onStatusChanged: {
                        if (status == MediaPlayer.EndOfMedia) {
                            if (randomswitch.checked) {
                                var now = new Date();
                                var seed = now.getSeconds();
                                var num = (Math.floor((Jarray.size() - 1) * Math.random(seed)));
                                playMusic.source = Qt.resolvedUrl(Jarray.getList()[num])
                                page.playing = num
                                playlist.currentIndex = Jarray.at(num)
                            } else {
                                if (page.playing < Jarray.size() - 1) {
                                    console.log("page.playing: " + page.playing)
                                    console.log("playlist.count: " + playlist.count)
                                    console.log("Jarray.size(): " + Jarray.size())
                                    page.playing++
                                    playMusic.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                                    playlist.currentIndex++
                                } else {
                                    page.playing = 0
                                    playMusic.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                                    playlist.currentIndex = page.playing + (playlist.count - Jarray.size())
                                }
                            }
                            console.log("Playing: "+playMusic.source)
                            playMusic.play()
                        }
                    }
                }
                FolderListModel {
                    id: folderModel
                    showDirs: true
                    showDotAndDotDot: true
                    showDirsFirst: true
                    nameFilters: ["*.mp3", "*.ogg"]
                    folder: Storage.getSetting("initialized") === "true" ? Qt.resolvedUrl(Storage.getSetting("currentfolder")) : Qt.resolvedUrl("/")
                    showOnlyReadable: true
                }

                Component {
                    id: fileDelegate
                    ListItem.Standard {
                        id: file
                        text: fileName
                        progression: folderModel.isFolder(index)
                        icon: !folderModel.isFolder(index) ? (fileName.match("\\.mp3") ? Qt.resolvedUrl("audio-x-mpeg.png") : Qt.resolvedUrl("audio-x-vorbis+ogg.png")) : Qt.resolvedUrl("folder.png")
                        iconFrame: false
                        height: 60
                        Image {
                            id: playindicator
                            source: ""
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: .5
                        }
                        onFocusChanged: {
                            if (focus == false) {
                                playindicator.source = ""
                            } else if (file.progression == false){
                                playindicator.source = "pause.png"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressAndHold: {
                                if (playlist.currentIndex == index && !folderModel.isFolder(index)) {
                                    popover.caller = file
                                    popover.artist = playMusic.metaData.albumArtist
                                    popover.album = playMusic.metaData.albumTitle
                                    popover.song = playMusic.metaData.title
                                    popover.show();
                                }
                            }
                            onClicked: {
                                if (folderModel.isFolder(index)) {
                                    Jarray.clear()
                                    playMusic.stop()
                                    folderModel.folder = Qt.resolvedUrl(filePath)
                                    playlist.currentIndex = 0
                                    page.loaded = 0
                                    if (fileName == "..") {
                                        currentpath.text = folderModel.folder.toString().replace("file://", "")
                                    } else {
                                        currentpath.text = filePath
                                    }
                                    Storage.setSetting("currentfolder", currentpath.text)
                                } else {
                                    console.log("Source: " + playMusic.source.toString())
                                    console.log("fileName: " + fileName)
                                    if (playlist.currentIndex == index) {
                                        if (playMusic.playbackState === MediaPlayer.PlayingState)  {
                                            playindicator.source = "play.png"
                                            playMusic.pause()
                                        } else {
                                            playindicator.source = "pause.png"
                                            playMusic.play()
                                        }
                                    } else {
                                        playMusic.stop()
                                        playMusic.source = Qt.resolvedUrl(filePath)
                                        playlist.currentIndex = index
                                        page.playing = Jarray.indexOf(filePath)
                                        console.log("Playing click: "+playMusic.source)
                                        console.log("Index: " + playlist.currentIndex)
                                        playMusic.play()
                                        playindicator.source = "pause.png"
                                    }
                                }
                            }
                        }
                        Component.onCompleted: {
                            if (!Jarray.contains(filePath) && !folderModel.isFolder(index)) {
                                console.log("Adding file:" + filePath)
                                Jarray.addItem(filePath, page.loaded)
                                console.log(page.loaded)
                            }
                            page.loaded++
                        }
                    }
                }
                model: folderModel
                delegate: fileDelegate
            }
            Rectangle {
                anchors.bottom: parent.bottom
                height: units.gu(8)
                width: parent.width
                ListItem.Standard {
                    text: "Shuffle?"
                    height: units.gu(4)
                    width: 3 * parent.width / 4
                    anchors.top: parent.top
                    anchors.left: parent.left
                    control: Switch {
                        anchors.centerIn: parent
                        id: randomswitch
                    }
                }
                Button {
                    id: stop
                    text: "Stop"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    height: units.gu(4)
                    width: parent.width / 4
                    color: "#DD4814";

                    onClicked: {
                        playMusic.stop()
                    }
                }
                ListItem.Standard {
                    id: currentpath
                    text: Storage.getSetting("initialized") === "true" ? Storage.getSetting("currentfolder") : "/"
                    height: units.gu(4)
                    width: 3 * parent.width / 4
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    opacity: .5
                }
                Button {
                    id: up
                    text: "Up"
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    height: units.gu(4)
                    width: parent.width / 4
                    color: "#DD4814";

                    onClicked: {
                        Jarray.clear()
                        playMusic.stop()
                        folderModel.folder = Qt.resolvedUrl(folderModel.parentFolder)
                        playlist.currentIndex = 0
                        page.loaded = 0
                        currentpath.text = folderModel.folder.toString().replace("file://", "")
                        Storage.setSetting("currentfolder", currentpath.text)
                    }
                }
            }
        }
    }
}
