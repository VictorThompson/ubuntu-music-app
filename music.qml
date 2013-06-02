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

            Component {
                id: highlight
                Rectangle {
                    width: 5; height: 40
                    color: "#DD4814";
                    Behavior on y {
                        SpringAnimation {
                            spring: 3
                            damping: 0.2
                        }
                    }
                }
            }

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
                    do {
                        var num = (Math.floor((Jarray.size()) * Math.random(seed)));
                        console.log(num)
                        console.log(page.playing)
                    } while (num == page.playing && Jarray.size() > 0)
                    player.source = Qt.resolvedUrl(Jarray.getList()[num])
                    filelist.currentIndex = Jarray.at(num)
                    page.playing = num
                    console.log("MediaPlayer statusChanged, currentIndex: " + filelist.currentIndex)
                } else {
                    if ((page.playing < Jarray.size() - 1 && direction === 1 )
                            || (page.playing > 0 && direction === -1)) {
                        console.log("page.playing: " + page.playing)
                        console.log("filelist.count: " + filelist.count)
                        console.log("Jarray.size(): " + Jarray.size())
                        page.playing += direction
                        if (page.playing === 0) {
                            filelist.currentIndex = page.playing + (page.itemnum - Jarray.size())
                        } else {
                            filelist.currentIndex += direction
                        }
                        player.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                    } else if(direction === 1) {
                        page.playing = 0
                        filelist.currentIndex = page.playing + (filelist.count - Jarray.size())
                        player.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                    } else if(direction === -1) {
                        page.playing = Jarray.size() - 1
                        filelist.currentIndex = page.playing + (filelist.count - Jarray.size())
                        player.source = Qt.resolvedUrl(Jarray.getList()[page.playing])
                    }
                    console.log("MediaPlayer statusChanged, currentIndex: " + filelist.currentIndex)
                }
                console.log("Playing: "+player.source)
                player.play()
            }

            MediaPlayer {
                id: player
                muted: false
                onStatusChanged: {
                    if (status == MediaPlayer.EndOfMedia) {
                        page.nextSong()
                    }
                }

                onPositionChanged: {
                    fileDurationProgressBackground.visible = true
                    fileDurationProgress.width = units.gu(Math.round((player.position*100)/player.duration) * .2) // 20 max
                    fileDurationBottom.text = Math.round((player.position/1000) / 60).toString() + ":" + (
                                Math.round((player.position/1000) % 60)<10 ? "0"+Math.round((player.position/1000) % 60).toString() :
                                                                  Math.round((player.position/1000) % 60).toString())
                    fileDurationBottom.text += " / "
                    fileDurationBottom.text += Math.round((player.duration/1000) / 60).toString() + ":" + (
                                Math.round((player.duration/1000) % 60)<10 ? "0"+Math.round((player.duration/1000) % 60).toString() :
                                                                  Math.round((player.duration/1000) % 60).toString())
                }
            }

            ListView {
                id: filelist
                width: parent.width
                height: parent.height - units.gu(10)
                highlight: highlight
                highlightFollowsCurrentItem: true
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

                FolderListModel {
                    id: folderModel
                    showDirectories: true
                    filterDirectories: false
                    nameFilters: ["*.mp3", "*.ogg","*.flac"]
                    path: Storage.getSetting("initialized") === "true" ? Storage.getSetting("currentfolder") : homePath()
                }

                Component {
                    id: fileDelegate
                    ListItem.Standard {
                        id: file
                        progression: model.isDir
                        icon: !model.isDir ? (trackCover === "" ? (fileName.match("\\.mp3") ? Qt.resolvedUrl("audio-x-mpeg.png") : Qt.resolvedUrl("audio-x-vorbis+ogg.png")) : "image://cover-art/"+filePath) : Qt.resolvedUrl("folder.png")
                        iconFrame: false
                        Label {
                            id: fileTitle
                            width: 400
                            wrapMode: Text.Wrap
                            maximumLineCount: 1
                            font.pixelSize: 16
                            anchors.left: parent.left
                            anchors.leftMargin: 75
                            anchors.top: parent.top
                            anchors.topMargin: 5
                            text: trackTitle == "" ? fileName : trackTitle
                        }
                        Label {
                            id: fileArtistAlbum
                            width: 400
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            font.pixelSize: 12
                            anchors.left: parent.left
                            anchors.leftMargin: 75
                            anchors.top: fileTitle.bottom
                            text: trackArtist == "" ? "" : trackArtist + " - " + trackAlbum
                        }
                        Label {
                            id: fileDuration
                            width: 400
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            font.pixelSize: 12
                            anchors.left: parent.left
                            anchors.leftMargin: 75
                            anchors.top: fileArtistAlbum.bottom
                            visible: false
                            text: ""
                        }

                        onFocusChanged: {
                            if (focus == false) {
                                selected = false
                            } else if (file.progression == false){
                                selected = false
                                fileArtistAlbumBottom.text = fileArtistAlbum.text
                                fileTitleBottom.text = fileTitle.text
                                iconbottom.source = file.icon
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
                                filelist.currentIndex = -1
                                page.itemnum = 0
                                page.playing = filelist.currentIndex
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
                                    } else if (player.playbackState === MediaPlayer.PausedState) {
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
                                console.log("Length: " + trackLength.toString())
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
                height: units.gu(10)
                width: parent.width
                color: "#333333"
                UbuntuShape {
                    id: forwardshape
                    height: parent.height * .5
                    width: parent.height * .5
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    radius: "none"
                    image: Image {
                        id: forwardindicator
                        source: "forward.png"
                        anchors.right: parent.right
                        anchors.centerIn: parent
                        opacity: .7
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            page.nextSong()
                        }
                    }
                }
                UbuntuShape {
                    id: playshape
                    height: parent.height * .4
                    width: parent.height * .4
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: forwardshape.left
                    radius: "none"
                    image: Image {
                        id: playindicator
                        source: "play.png"
                        anchors.right: parent.right
                        anchors.centerIn: parent
                        opacity: .7
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (player.playbackState === MediaPlayer.PlayingState)  {
                                playindicator.source = "play.png"
                                player.pause()
                            } else {
                                playindicator.source = "pause.png"
                                player.play()
                            }
                        }
                    }
                }
                UbuntuShape {
                    id: upshape
                    height: parent.height * .4
                    width: parent.height * .4
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: playshape.left
                    radius: "none"
                    image: Image {
                        id: upindicator
                        source: "up.png"
                        anchors.right: parent.right
                        anchors.centerIn: parent
                        opacity: .7
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Jarray.clear()
                            folderModel.path = folderModel.parentPath
                            filelist.currentIndex = -1
                            page.itemnum = 0
                            page.playing = filelist.currentIndex
                            currentpath.text = folderModel.path
                            Storage.setSetting("currentfolder", currentpath.text)
                        }
                    }
                }

                Image {
                    id: iconbottom
                    source: ""
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    anchors.leftMargin: units.gu(1)
                }
                Label {
                    id: fileTitleBottom
                    width: units.gu(30)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 16
                    anchors.left: iconbottom.right
                    anchors.top: parent.top
                    anchors.topMargin: units.gu(1)
                    anchors.leftMargin: units.gu(1)
                    text: ""
                }
                Label {
                    id: fileArtistAlbumBottom
                    width: units.gu(30)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 12
                    anchors.left: iconbottom.right
                    anchors.top: fileTitleBottom.bottom
                    anchors.leftMargin: units.gu(1)
                    text: ""
                }
                Rectangle {
                    id: fileDurationProgressContainer
                    anchors.top: fileArtistAlbumBottom.bottom
                    anchors.left: iconbottom.right
                    anchors.topMargin: 2
                    anchors.leftMargin: units.gu(1)
                    width: units.gu(20)
                    color: "#333333"

                    Rectangle {
                        id: fileDurationProgressBackground
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        height: 1
                        width: units.gu(20)
                        color: "#FFFFFF"
                        visible: false
                    }
                    Rectangle {
                        id: fileDurationProgress
                        anchors.top: parent.top
                        height: 5
                        width: 0
                        color: "#DD4814"
                    }
                }
                Label {
                    id: fileDurationBottom
                    anchors.top: fileArtistAlbumBottom.bottom
                    anchors.left: fileDurationProgressContainer.right
                    anchors.leftMargin: units.gu(1)
                    width: units.gu(30)
                    wrapMode: Text.Wrap
                    color: "#FFFFFF"
                    maximumLineCount: 1
                    font.pixelSize: 12
                    text: ""
                }
                Label {
                    id: currentpath
                    text: folderModel.path
                    width: 3 * parent.width / 4
                    color: "#FFFFFF"
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    font.pixelSize: 14
                    opacity: .4
                }
            }
        }
    }
}
