import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import QtMultimedia 5.0
import Qt.labs.folderlistmodel 1.0
import "script.js" as Jarray

/*!
    \brief MainView with Tabs element.
           First Tab has a single Label and
           second Tab has a single ToolbarAction.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "music"
    
    width: units.gu(50)
    height: units.gu(75)
    
    Tabs {
        id: tabs
        anchors.fill: parent
        
        // First tab begins here
        Tab {
            id: tab
            objectName: "Tab1"
            
            title: i18n.tr("Music")
            
            // Tab content begins here

            page: Page {
                id: page
                property int playing: 0
                property variant arr: []
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

                    MediaPlayer {
                        id: playMusic
                        onStatusChanged: {
                            if (status == MediaPlayer.EndOfMedia) {
                                if (randomswitch.checked) {
                                    var now = new Date();
                                    var seed = now.getSeconds();
                                    var num = (Math.floor(playlist.count * Math.random(seed)));
                                    playMusic.source = Qt.resolvedUrl(Jarray.getList()[num])
                                    page.playing = num
                                    playlist.currentIndex = num
                                } else {
                                    if (page.playing < playlist.count - 1) {
                                        playMusic.source = Qt.resolvedUrl(Jarray.getList()[page.playing + 1])
                                        page.playing++
                                        playlist.currentIndex = page.playing
                                    } else {
                                        playMusic.source = Qt.resolvedUrl(Jarray.getList()[0])
                                        page.playing = 0
                                        playlist.currentIndex = 0
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
                        // TODO: both of these cause the "isFolder()" check to detect music files as folders. Find a fix.
                        //showDotAndDotDot: true
                        //showDirsFirst: true
                        nameFilters: ["*.mp3"]
                        folder: Qt.resolvedUrl("/")
                    }

                    Component {
                        id: fileDelegate
                        ListItem.Standard {
                            id: file
                            text: fileName
                            progression: folderModel.isFolder(filePath)
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (folderModel.isFolder(filePath)) {
                                        Jarray.clear()
                                        playMusic.stop()
                                        folderModel.folder = Qt.resolvedUrl(filePath)
                                        if (fileName == "..") {
                                            tab.title = folderModel.folder.toString().replace("file://", "")
                                        } else {
                                            tab.title = filePath
                                        }
                                    } else {
                                        playMusic.stop()
                                        playMusic.source = Qt.resolvedUrl(filePath)
                                        playlist.currentIndex = index
                                        page.playing = playlist.currentIndex
                                        console.log("Playing click: "+playMusic.source)
                                        console.log("Index: " + playlist.currentIndex)
                                        playMusic.play()
                                    }
                                }
                                Component.onCompleted: {
                                    if (!Jarray.contains(filePath) && !folderModel.isFolder(filePath)) {
                                        console.log("Adding file:" + filePath)
                                        Jarray.addItem(filePath)
                                    }
                                }
                            }

                        }
                    }
                    model: folderModel
                    delegate: fileDelegate
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    height: units.gu(4)
                    width: parent.width
                    ListItem.Standard {
                        text: "Shuffle?"
                        height: units.gu(4)
                        width: parent.width / 2
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        control: Switch {
                            anchors.centerIn: parent
                            id: randomswitch
                        }
                    }
                    Button {
                        id: up
                        text: "Return"
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        height: units.gu(4)
                        width: parent.width / 4
                        color: "#DD4814";

                        onClicked: {
                            Jarray.clear()
                            playMusic.stop()
                            tab.title = folderModel.parentFolder.toString().replace("file://", "")
                            folderModel.folder = Qt.resolvedUrl(folderModel.parentFolder)
                        }
                    }
                    Button {
                        id: stop
                        text: "Stop"
                        anchors.bottom: parent.bottom
                        anchors.right: up.left
                        height: units.gu(4)
                        width: parent.width / 4
                        color: "#DD4814";

                        onClicked: {
                            playMusic.stop()
                        }
                    }
                }
            }
        }
    }
}
