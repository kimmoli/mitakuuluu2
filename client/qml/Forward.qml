import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    objectName: "forwardMessage"

    property variant jids: []

    property string jid: ""
    property string msgid: ""
    property string preview: ""
    property string msgtext: ""

    canAccept: listView.count > 0

    property variant conversationModel

    onAccepted: {
        conversationModel.forwardMessage(page.jids, page.msgid)
        page.clear()
    }

    function clear() {
        page.jid = ""
        page.msgid = ""
        page.jids = []
        page.msgtext = ""
        page.preview = ""
    }

    property variant messageModel
    onMessageModelChanged: {
        page.msgid = messageModel.msgid
        if (messageModel.watype == 0) {
            msgtext = messageModel.data
        }
        else if (messageModel.url.length > 0) {
            msgtext = ""//messageModel.mediaurl
            if (messageModel.watype == 1) {
                if (messageModel.local.length > 0)
                    preview = messageModel.local
                else if (messageModel.data.length > 0)
                    preview = "data:image/jpeg;base64," + messageModel.data
            }
        }
        else if (messageModel.watype == 4) {
            msgtext = "Contact: " + messageModel.name
        }
        else if (messageModel.latitude.length > 0 && messageModel.longitude.length > 0) {
            msgtext = messageModel.latitude + "," + messageModel.longitude
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: page
        pressDelay: 0

        DialogHeader {
            id: header
            title: jids.length == 0 ? qsTr("Select contacts", "Forward message page title")
                                    : qsTr("Forward", "Forward message page title")
        }

        Label {
            id: msgArea
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            width: (page.isPortrait ? page.width : (page.width / 2)) - Theme.paddingMedium
            text: msgtext
            wrapMode: Text.WordWrap
        }

        Image {
            id: prev
            sourceSize.width: page.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: msgArea.horizontalCenter
            fillMode: Image.PreserveAspectFit
            source: preview
            opacity: page.isPortrait ? 0.2 : 1.0
        }

        SilicaListView {
            id: listView
            anchors.top: page.isPortrait ? msgArea.bottom : header.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: page.isPortrait ? page.width : (page.width / 2)
            clip: true
            model: contactsModel
            delegate: listDelegate
            pressDelay: 0
        }

        VerticalScrollDecorator {}
    }

    ContactsFilterModel {
        id: contactsModel
        contactsModel: ContactsBaseModel
        showActive: false
        showUnknown: acceptUnknown
        filterContacts: showMyJid ? [] : [Mitakuuluu.myJid]
        Component.onCompleted: {
            init()
        }
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium
            highlighted: down || checked
            property bool checked: page.jids.indexOf(model.jid) != -1

            AvatarHolder {
                id: contactava
                height: Theme.iconSizeLarge
                width: Theme.iconSizeLarge
                source: model.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: contact
                anchors.left: contactava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeMedium
                text: Utilities.emojify(model.nickname, emojiPath)
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            onClicked: {
                if (page.jids.length > 1 && model.jid.indexOf("-") == -1 && page.jids[0].indexOf("-") == -1) {
                    selectMany(model.jid)
                }
                else {
                    selectOne(model.jid)
                }
            }

            onPressAndHold: {
                if (model.jid.indexOf("-") == -1 && page.jids[0].indexOf("-") == -1) {
                    selectMany(model.jid)
                }
                else {
                    selectOne(model.jid)
                }
            }

            function selectMany(jid) {
                var value = page.jids
                var exists = value.indexOf(jid)
                if (exists != -1) {
                    value.splice(exists, 1)
                }
                else {
                    value.splice(0, 0, jid)
                }
                page.jids = value
                page.canAccept = page.jids.length > 0
            }

            function selectOne(jid) {
                page.jids = [model.jid]
                page.canAccept = page.jids.length > 0
            }
        }
    }
}
