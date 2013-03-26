import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import QtMultimedia 5.0
import org.nemomobile.folderlistmodel 1.0
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
            filelist.currentIndex = -1
        }
        Page {
            id: page
            property int playing: 0
            property int itemnum: 0
            property bool random: false
            title: i18n.tr("Music")

            function previousSong() {
                getSong(-1)
            }
            function nextSong() {
                getSong(1)
            }

            function getSong(direction) {
                if (page.random) {
                    var now = new Date();
                    var seed = now.getSeconds();
                    var num = (Math.floor((Jarray.size()) * Math.random(seed)));
                    player.source = Qt.resolvedUrl(Jarray.getList()[num])
                    page.playing = num
                    filelist.currentIndex = Jarray.at(num)
                    console.log("MediaPlayer statusChanged, currentIndex: " + filelist.currentIndex)
                } else {
                    if ((page.playing < Jarray.size() - 1 && direction === 1 )
                            || (page.playing > 0 && direction === -1)) {
                        console.log("page.playing: " + page.playing)
                        console.log("filelist.count: " + filelist.count)
                        console.log("Jarray.size(): " + Jarray.size())
                        page.playing += direction
                        player.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                        filelist.currentIndex += direction
                    } else if(direction === 1) {
                        page.playing = 0
                        player.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                        filelist.currentIndex = page.playing + (filelist.count - Jarray.size())
                    } else if(direction === -1) {
                        page.playing = Jarray.size() - 1
                        player.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                        filelist.currentIndex = page.playing + (filelist.count - Jarray.size())
                    }
                    console.log("MediaPlayer statusChanged, currentIndex: " + filelist.currentIndex)
                }
                console.log("Playing: "+player.source)
                player.play()
            }

            tools: ToolbarActions {
                active: true
                Action {
                    text: "Mute"
                    iconSource: "image://gicon/audio-volume-muted-symbolic"
                    onTriggered: {
                        player.volume = 0
                    }
                }
                Action {
                    text: "Down"
                    iconSource: "image://gicon/audio-volume-low-symbolic"
                    onTriggered: {
                        if (player.volume >= .1) player.volume -= .1
                    }
                }
                Action {
                    text: "Up"
                    iconSource: "image://gicon/audio-volume-high-symbolic"
                    onTriggered: {
                        if (player.volume <= .9) player.volume += .1
                    }
                }
                Action {
                    text: "Shuffle?"
                    iconSource: page.random ? "image://gicon/edit-delete-symbolic" : "image://gicon/media-playlist-shuffle-symbolic"
                    onTriggered: {
                        page.random = !page.random
                    }
                }
                Action {
                    text: "Previous"
                    iconSource: "image://gicon/media-skip-backward-symbolic"
                    onTriggered: page.previousSong()
                }
                Action {
                    text: "Stop"
                    iconSource: "image://gicon/media-playback-stop-symbolic"
                    onTriggered: {
                        filelist.currentItem.focus = false
                        player.stop()
                    }
                }
                Action {
                    text: "Next"
                    iconSource: "image://gicon/media-skip-forward-symbolic"
                    onTriggered: page.nextSong()
                }
                Action {
                    text: "Info"
                    iconSource: "image://gicon/audio-x-generic-symbolic"
                    onTriggered: {
                        if (player.playbackState === MediaPlayer.PlayingState || player.playbackState === MediaPlayer.PausedState) {
                            PopupUtils.open(dialogcomponent, filelist.currentItem)
                        }
                    }
                }
                Action {
                    text: "Up"
                    iconSource: "image://gicon/go-up-symbolic"
                    onTriggered: {
                        Jarray.clear()
                        player.stop()
                        folderModel.path = folderModel.parentPath
                        filelist.currentIndex = -1
                        page.itemnum = 0
                        currentpath.text = folderModel.path
                        Storage.setSetting("currentfolder", currentpath.text)
                    }
                }
            }

            ListView {
                id: filelist
                width: parent.width
                height: parent.height - units.gu(4)
                model: folderModel
                delegate: fileDelegate
                Component {
                    id: dialogcomponent
                    Dialog {
                        id: dialog
                        property string artist
                        property string album
                        property string song
                        title: "Song Information"
                        text: "Artist: " + player.metaData.albumArtist + "\nAlbum: " + player.metaData.albumTitle + "\nSong: " + player.metaData.title

                        Button {
                            text: "OK"
                            color: "#DD4814"
                            onClicked: PopupUtils.close(dialog)
                        }
                    }
                }

                MediaPlayer {
                    id: player
                    muted: false
                    onStatusChanged: {
                        if (status == MediaPlayer.EndOfMedia) {
                            page.nextSong()
                        }
                    }
                }
                FolderListModel {
                    id: folderModel
                    showDirectories: true
                    filterDirectories: false
                    nameFilters: ["*.mp3", "*.ogg"]
                    path: Storage.getSetting("initialized") === "true" ? Storage.getSetting("currentfolder") : homePath()
                }

                Component {
                    id: fileDelegate
                    ListItem.Standard {
                        id: file
                        text: fileName
                        progression: model.isDir
                        icon: !model.isDir ? (fileName.match("\\.mp3") ? Qt.resolvedUrl("audio-x-mpeg.png") : Qt.resolvedUrl("audio-x-vorbis+ogg.png")) : Qt.resolvedUrl("folder.png")
                        iconFrame: false
                        Image {
                            id: playindicator
                            source: ""
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: .7
                        }
                        onFocusChanged: {
                            if (focus == false) {
                                playindicator.source = ""
                                selected = false
                            } else if (file.progression == false){
                                playindicator.source = "pause.png"
                                selected = true
                            }
                        }
                        onPressAndHold: {
                            if (filelist.currentIndex == index && !model.isDir) {
                                PopupUtils.open(dialogcomponent, file)
                            }
                        }
                        onClicked: {
                            if (focus == false) {
                                focus = true
                            }
                            if (model.isDir) {
                                Jarray.clear()
                                player.stop()
                                filelist.currentIndex = -1
                                page.itemnum = 0
                                currentpath.text = filePath.toString()
                                Storage.setSetting("currentfolder", currentpath.text.toString())
                                console.log("Stored:" + Storage.getSetting("currentfolder"))
                                folderModel.path = filePath
                            } else {
                                console.log("fileName: " + fileName)
                                if (filelist.currentIndex == index) {
                                    if (player.playbackState === MediaPlayer.PlayingState)  {
                                        playindicator.source = "play.png"
                                        player.pause()
                                    } else {
                                        playindicator.source = "pause.png"
                                        player.play()
                                    }
                                } else {
                                    player.stop()
                                    player.source = Qt.resolvedUrl(filePath)
                                    filelist.currentIndex = index
                                    page.playing = Jarray.indexOf(filePath)
                                    console.log("Playing click: "+player.source)
                                    console.log("Index: " + filelist.currentIndex)
                                    player.play()
                                    playindicator.source = "pause.png"
                                }
                                console.log("Source: " + player.source.toString())
                            }
                        }
                        Component.onCompleted: {
                            if (!Jarray.contains(filePath) && !model.isDir) {
                                console.log("Adding file:" + filePath)
                                Jarray.addItem(filePath, page.itemnum)
                                console.log(page.itemnum)
                            }
                            page.itemnum++
                        }
                    }
                }
            }
            Rectangle {
                anchors.top: filelist.bottom
                height: units.gu(4)
                width: parent.width
                ListItem.Standard {
                    id: currentpath
                    text: folderModel.path
                    height: units.gu(4)
                    width: 3 * parent.width / 4
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    opacity: .5
                }
            }
        }
    }
}
