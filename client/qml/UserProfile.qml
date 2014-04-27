import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "profilePage"

    property string jid: ""
    onJidChanged: {
        phone = jid.split("@")[0]
        var model = ContactsBaseModel.getModel(jid)
        pushname = model.nickname || model.name
        presence = model.message
        picture = model.avatar
        blocked = model.blocked
    }
    property string pushname: ""
    property string presence: ""
    property string phone: ""
    property string picture: ""
    property bool blocked: false

    property variant conversationModel

    Connections {
        target: ContactsBaseModel
        onNicknameChanged: {
            if (pjid == page.jid) {
                pushname = nickname
            }
        }
    }

    Connections {
        target: Mitakuuluu
        onPictureUpdated: {
            if (pjid == page.jid) {
                picture = ""
                picture = path
            }
        }
    }

    Connections {
        target: conversationModel
        onMediaListReceived: {
            if (pjid === page.jid) {
                mediaListModel.clear()
                for (var i = 0; i < mediaList.length; i++) {
                    console.log(JSON.stringify(mediaList[i]))
                    mediaListModel.append(mediaList[i])
                }
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Inactive) {

        }
        else if (status == PageStatus.Active) {
            conversationModel.requestContactMedia()
        }
    }

    function timestampToFullDate(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd MMM yyyy")
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                text: blocked ? qsTr("Unblock contact", "User profile page menu item")
                              : qsTr("Block contact", "User profile page menu item")
                onClicked: {
                    page.blocked = !page.blocked
                    Mitakuuluu.blockOrUnblockContact(page.jid)
                }
            }

            MenuItem {
                text: qsTr("Save chat history", "User profile page menu item")
                onClicked: {
                    conversationModel.saveHistory(page.jid, page.pushname)
                    banner.notify(qsTr("History saved to Documents", "User profile page history saved banner"))
                }
            }

            MenuItem {
                text: qsTr("Save to phonebook", "User profile page menu item")
                onClicked: {
                    Mitakuuluu.openProfile(pushname, "+" + phone)
                }

            }

            MenuItem {
                text: qsTr("Call to contact", "User profile page menu item")
                onClicked: {
                    Qt.openUrlExternally("tel:+" + page.jid.split("@")[0])
                }
            }
        }

        Column {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingLarge
            }

            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: pushname
            }

            AvatarHolder {
                id: ava
                width: Theme.iconSizeLarge * 4
                height: Theme.iconSizeLarge * 4
                anchors.horizontalCenter: parent.horizontalCenter
                source: page.picture
                emptySource: "../images/avatar-empty.png"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        avatarView.show(page.picture)
                    }
                }
            }

            Label {
                id: pushnameLabel
                width: parent.width
                text: qsTr("Nickname: %1", "User profile page nickname label").arg(Utilities.emojify(pushname, emojiPath))
                textFormat: Text.RichText
            }

            Label {
                id: presenceLabel
                width: parent.width
                text: qsTr("Status: %1", "User profile page status label").arg(Utilities.emojify(presence, emojiPath))
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
            }

            Label {
                id: phoneLabel
                width: parent.width
                text: qsTr("Phone: +%1", "User profile page phone label").arg(phone)
                textFormat: Text.RichText
            }

            Label {
                id: ifBlocked
                width: parent.width
                text: qsTr("Contact blocked", "User profile page contact blocked label")
                visible: page.blocked
            }

            SectionHeader {
                text: qsTr("Media", "User profile page media section name")
                visible: mediaGrid.count > 0
            }

            SilicaGridView {
                id: mediaGrid
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: - Theme.paddingLarge
                }

                delegate: gridDelegate
                model: mediaListModel
                cellWidth: page.isPortrait ? width / 3 : width / 5
                cellHeight: cellWidth
                clip: true
                height: mediaGrid.contentHeight
                interactive: false
            }
        }

        VerticalScrollDecorator {}
    }

    AvatarView {
        id: avatarView
    }

    ListModel {
        id: mediaListModel
    }

    Component {
        id: gridDelegate
        MouseArea {
            id: item
            width: GridView.view.cellWidth - 1
            height: GridView.view.cellHeight - 1

            Thumbnail {
                id: image
                source: model.path
                height: parent.height
                width: parent.width
                sourceSize.height: parent.height
                sourceSize.width: parent.width
                anchors.centerIn: parent
                clip: true
                smooth: true
                mimeType: model.mime

                states: [
                    State {
                        name: 'loaded'; when: image.status == Thumbnail.Ready
                        PropertyChanges { target: image; opacity: 1; }
                    },
                    State {
                        name: 'loading'; when: image.status != Thumbnail.Ready
                        PropertyChanges { target: image; opacity: 0; }
                    }
                ]

                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                visible: pressed && containsMouse
            }
            Image {
                source: "image://theme/icon-m-play"
                visible: model.mime.indexOf("video") == 0
                anchors.centerIn: parent
                asynchronous: true
                cache: true
            }
            onClicked: {
                Qt.openUrlExternally(model.path)
            }
        }
    }
}
