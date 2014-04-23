import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    canAccept: false

    property string pendingGroup: ""
    property variant jids: []

    function checkCanAccept() {
        page.canAccept = groupTitle.text.trim().length > 0 && jids.length > 0
    }

    onStatusChanged: {
        if (status == DialogStatus.Opened) {
            //groupTitle.text = ""
            groupTitle.forceActiveFocus()
            fastScroll.init()
        }
    }

    onDone: {
        groupTitle.focus = false
        page.forceActiveFocus()
    }

    onAccepted: {
        groupTitle.deselect()
        Mitakuuluu.createGroup(groupTitle.text.trim(), avaholder.source, jids)
    }

    DialogHeader {
        id: header
        title: qsTr("Create group", "Greate group page title")
    }

    SilicaFlickable {
        id: flick
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: height

        Row {
            id: detailsrow
            width: parent.width
            height: avaholder.height
            spacing: Theme.paddingMedium

            AvatarHolder {
                id: avaholder
                width: Theme.itemSizeMedium
                height: Theme.itemSizeMedium

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        avatarView.show(avaholder.source)
                    }
                }
            }

            TextField {
                id: groupTitle
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - avaholder.width - Theme.paddingMedium
                onTextChanged: checkCanAccept()
                placeholderText: qsTr("Write name of new group here", "Create group subject area subtitle")
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: listView.forceActiveFocus()
            }
        }

        SilicaListView {
            id: listView
            anchors {
                top: detailsrow.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            model: contactsModel
            delegate: contactsDelegate
            clip: true
            section.property: "nickname"
            section.criteria: ViewSection.FirstCharacter
            section.delegate: Component {
                SectionHeader {
                    text: section
                }
            }
            onCountChanged: {
                fastScroll.init()
            }

            FastScroll {
                id: fastScroll
                listView: listView
                __hasPageHeight: false
            }
        }
    }

    ContactsFilterModel {
        id: contactsModel
        contactsModel: ContactsBaseModel
        hideGroups: true
        showUnknown: acceptUnknown
        showActive: false
        filterContacts: showMyJid ? [] : [Mitakuuluu.myJid]
        onContactsModelChanged: {
            fastScroll.init()
        }
        Component.onCompleted: {
            init()
        }
    }

    Component {
        id: contactsDelegate

        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium
            highlighted: down || checked
            property bool checked: page.jids.indexOf(model.jid) != -1 || model.jid === Mitakuuluu.myJid

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
                text: Utilities.emojify(model.message, emojiPath)
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
                if (model.jid !== Mitakuuluu.myJid) {
                    var value = page.jids
                    var exists = value.indexOf(jid)
                    if (exists != -1) {
                        value.splice(exists, 1)
                    }
                    else {
                        value.splice(0, 0, jid)
                    }
                    page.jids = value
                    checkCanAccept()
                }
            }
        }
    }

    Rectangle {
        id: avatarView
        anchors.fill: parent
        color: "#40FFFFFF"
        opacity: 0.0
        visible: opacity > 0.0
        onVisibleChanged: {
            console.log("avatarView " + (visible ? "visible" : "invisible"))
        }
        property string imgPath
        Behavior on opacity {
            FadeAnimation {}
        }
        function show(path) {
            avaView.source = path
            avatarView.opacity = 1.0
            page.backNavigation = false
        }
        function hide() {
            avaView.source = ""
            avatarView.opacity = 0.0
            page.backNavigation = true
        }
        function resizeAvatar() {
            pageStack.currentPage.accepted.disconnect(avatarView.resizeAvatar)
            pageStack.busyChanged.connect(avatarView.transitionDone)
            imgPath = pageStack.currentPage.selectedFiles[0]
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(avatarView.transitionDone)
                pageStack.push(Qt.resolvedUrl("ResizePicture.qml"), {"picture": imgPath, "jid": "new_page", "maximumSize": 480})
                pageStack.currentPage.accepted.connect(avatarView.setNewAvatar)
            }
        }
        function setNewAvatar() {
            pageStack.currentPage.accepted.disconnect(avatarView.setNewAvatar)
            avaView.source = ""
            avaView.source = pageStack.currentPage.filename
            avaholder.source = ""
            avaholder.source = pageStack.currentPage.filename
        }
        Image {
            id: avaView
            anchors.centerIn: parent
            asynchronous: true
            cache: false
        }
        MouseArea {
            enabled: avatarView.visible
            anchors.fill: parent
            onClicked: {
                console.log("avatarview clicked")
                avatarView.hide()
            }
        }
        Button {
            anchors.top: avaView.bottom
            anchors.horizontalCenter: avaView.horizontalCenter
            text: qsTr("Change", "Avatar view change button text")
            onClicked: {
                pageStack.push(Qt.resolvedUrl("MediaSelector.qml"), {"canChangeType": false})
                pageStack.currentPage.accepted.connect(avatarView.resizeAvatar)
            }
        }
    }
}
