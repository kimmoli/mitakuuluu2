import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TransferEngine 1.0
import "harbour/mitakuuluu2/sharecontacts" 1.0
import "harbour/mitakuuluu2/translator" 1.0
import "Utilities.js" as Utilities

ShareDialog {
    id: root
    allowedOrientations: Orientation.Portrait

    property string emojiPath: "/usr/share/harbour-mitakuuluu2/emoji/"

    property int viewWidth: root.isPortrait ? Screen.width : Screen.width / 2
    property variant jids: []

    property string path: source

    canAccept: false

    Component.onCompleted: {
        fastScroll.init()
    }

    onAccepted: {
        if (content && 'data' in content) {
            contactsModel.startSharing(jids, content.name, content.data)
        }
        else {
            shareItem.userData = {"description": jids.join(",")}
            shareItem.start()
        }
    }

    Translator {
        id: translator
    }

    SailfishShare {
        id: shareItem
        source: root.path
        metadataStripped: true
        serviceId: root.methodId
        userData: {"description": "Mitakuuluu"}
    }

    SilicaListView {
        anchors.fill: parent
        model: contactsModel
        delegate: contactsDelegate
        header: DialogHeader { title: jids.length > 0 ? qsTr("Selected: %n", "Sharing menu title text", jids.length) : "Mitakuuluu" }
        section.property: "nickname"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: sectionDelegate
        FastScroll { id: fastScroll }
    }

    Component {
        id: sectionDelegate
        SectionHeader {
            text: section
        }
    }

    Component {
        id: contactsDelegate

        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium
            highlighted: down || checked
            property bool checked: root.jids.indexOf(model.jid) != -1

            AvatarHolder {
                id: ava
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                source: model.avatar
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: nickname
                font.pixelSize: Theme.fontSizeMedium
                text: Utilities.emojify(model.nickname, emojiPath)
                anchors.left: ava.right
                anchors.leftMargin: 16
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: status
                font.pixelSize: Theme.fontSizeSmall
                text: model.jid.indexOf("-") > 0 ? qsTr("Group chat", "Contacts group page text in status message line") : Utilities.emojify(model.message, emojiPath)
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                truncationMode: TruncationMode.Fade
            }

            onClicked: {
                if (root.jids.length > 1 && model.jid.indexOf("-") == -1 && root.jids[0].indexOf("-") == -1) {
                    selectMany(model.jid)
                }
                else {
                    selectOne(model.jid)
                }
            }
            onPressAndHold: {
                if (model.jid.indexOf("-") == -1 && root.jids[0].indexOf("-") == -1) {
                    selectMany(model.jid)
                }
                else {
                    selectOne(model.jid)
                }
            }

            function selectMany(jid) {
                var value = root.jids
                var exists = value.indexOf(model.jid)
                if (exists != -1) {
                    value.splice(exists, 1)
                }
                else {
                    value.splice(0, 0, model.jid)
                }
                root.jids = value
                root.canAccept = root.jids.length > 0
            }

            function selectOne(jid) {
                root.jids = [model.jid]
                root.canAccept = root.jids.length > 0
            }
        }
    }

    ShareContactsModel {
        id: contactsModel
    }
}
