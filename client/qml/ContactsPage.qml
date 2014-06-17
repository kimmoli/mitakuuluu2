import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "contactsPage"

    onStatusChanged: {
        if (status == PageStatus.Active) {
            page.forceActiveFocus()
            searchField.text = ""
            contactsModel.filter = ""
            fastScroll.init()
            listView.recheckMuting()

            var firstStartContacts = Mitakuuluu.load("settings/firstStartContacts", true)
            if (firstStartContacts) {
                horizontalHint.stop()
                horizontalHint.direction = TouchInteraction.Right
                horizontalHint.start()
                Mitakuuluu.save("settings/firstStartContacts", false)
            }
            horizontalHint.visible = firstStartChats
            hintLabel.visible = firstStartChats
        }
    }

    Connections {
        target: ContactsBaseModel
        onTotalUnreadChanged: listView.recheckMuting()
    }

    SilicaFlickable {
        id: flickView
        anchors.fill: parent
        clip: true
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Blacklist", "Contacts page menu item")
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PrivacyList.qml"))
                }
            }
            MenuItem {
                text: qsTr("Create group", "Contacts page menu item")
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("CreateGroup.qml"))
                }
            }
            MenuItem {
                text: qsTr("Add contact", "Contacts page menu item")
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SelectPhonebook.qml"))
                }
            }
            MenuItem {
                text: qsTr("Settings", "Contacts page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Settings.qml"))
                }
            }
        }

        PageHeader {
            id: header
            title: qsTr("Contacts", "Contacts page title")
        }

        SearchField {
            id: searchField
            width: parent ? parent.width : Screen.width
            anchors {
                top: header.bottom
            }
            placeholderText: qsTr("Search contacts", "Contacts page search text")
            inputMethodHints: Qt.ImhNoPredictiveText
            onTextChanged: {
                contactsModel.filter = searchField.text
                fastScroll.init()
            }
        }

        SilicaListView {
            id: listView
            model: contactsModel
            delegate: listDelegate
            anchors.top: searchField.bottom
            width: parent.width
            anchors.bottom: parent.bottom
            clip: true
            cacheBuffer: page.height * 2
            pressDelay: 0
            currentIndex: -1
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
            signal recheckMuting

            FastScroll {
                id: fastScroll
                listView: listView
                __hasPageHeight: false
            }
        }
    }

    InteractionHintLabel {
        id: hintLabel
        anchors.bottom: page.bottom
        Behavior on opacity { FadeAnimation { duration: 1000 } }
        text: qsTr("Flick right to return to Chats page")
        visible: false
    }

    TouchInteractionHint {
        id: horizontalHint
        loops: Animation.Infinite
        anchors.verticalCenter: page.verticalCenter
        visible: false
    }

    Component {
        id: listDelegate
        ListItem {
            id: item
            width: ListView.view.width
            contentHeight: Theme.itemSizeMedium
            ListView.onRemove: animateRemoval(item)
            menu: contextMenu
            property bool muted: false
            property Timer mutingTimer

            function removeContact() {
                remorseAction(qsTr("Delete", "Delete contact remorse action text"),
                function() {
                    ContactsBaseModel.deleteContact(model.jid)
                })
            }

            function leaveGroup() {
                remorseAction(qsTr("Leave group %1", "Group leave remorse action text").arg(model.nickname),
                function() {
                    Mitakuuluu.groupLeave(model.jid)
                    ContactsBaseModel.deleteContact(model.jid)
                })
            }

            function removeGroup() {
                remorseAction(qsTr("Delete group %1", "Group delete remorse action text").arg(model.nickname),
                function() {
                    Mitakuuluu.groupRemove(model.jid)
                    ContactsBaseModel.deleteContact(model.jid)
                })
            }

            Connections {
                target: listView
                onRecheckMuting: {
                    checkMuting()
                }
            }

            Component.onCompleted: {
                checkMuting()
            }

            function checkMuting() {
                var timeNow = new Date().getTime()
                var mutingInterval = Mitakuuluu.load("muting/" + model.jid, timeNow)
                if (parseInt(mutingInterval) > timeNow) {
                    if (!mutingTimer) {
                        mutingTimer = mutingTimerComponent.createObject(null, {"interval": parseInt(mutingInterval) - new Date().getTime(), "running": true})
                        muted = true
                    }
                }
                else {
                    if (mutingTimer) {
                        removeMuting()
                    }
                }
            }

            Component.onDestruction: {
                removeMuting()
            }

            function removeMuting() {
                if (item.mutingTimer)
                    item.mutingTimer.destroy()
                muted = false
            }

            Component {
                id: mutingTimerComponent
                Timer {
                    onTriggered: {
                        item.muted = false
                        item.mutingTimer.destroy()
                    }
                }
            }

            Rectangle {
                id: presence
                height: ava.height
                anchors.left: parent.left
                anchors.right: ava.left
                anchors.verticalCenter: ava.verticalCenter
                color: model.blocked ? Theme.rgba("red", 0.6) : (Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn ? (model.available ? Theme.rgba(Theme.highlightColor, 0.6) : "transparent") : "transparent")
                border.width: model.blocked ? 1 : 0
                border.color: (Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn && model.blocked) ? Theme.rgba(Theme.highlightColor, 0.6) : "transparent"
                smooth: true
            }

            AvatarHolder {
                id: ava
                source: model.avatar == "undefined" ? "" : (model.avatar)
                emptySource: "../images/avatar-empty" + (model.jid.indexOf("-") > 0 ? "-group" : "") + ".png"
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall / 2
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge

                Rectangle {
                    id: unreadCount
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    smooth: true
                    radius: Theme.iconSizeSmall / 4
                    border.width: 1
                    border.color: Theme.highlightColor
                    color: Theme.secondaryHighlightColor
                    visible: model.unread > 0
                    anchors.right: parent.right
                    anchors.top: parent.top

                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: model.unread
                        color: Theme.primaryColor
                    }
                }

                Rectangle {
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    smooth: true
                    radius: Theme.iconSizeSmall / 4
                    border.width: 1
                    border.color: Theme.highlightColor
                    color: Theme.secondaryHighlightColor
                    visible: item.muted
                    anchors.left: parent.left
                    anchors.top: parent.top

                    Image {
                        source: "image://theme/icon-m-speaker-mute"
                        smooth: true
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        anchors.centerIn: parent
                    }
                }
            }

            Column {
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.verticalCenter: ava.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                clip: true
                spacing: Theme.paddingSmall

                Label {
                    id: nickname
                    font.pixelSize: Theme.fontSizeMedium
                    width: parent.width
                    text: Utilities.emojify(model.nickname, emojiPath)
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.RichText
                }

                Label {
                    id: status
                    width: parent.width
                    text: model.jid.indexOf("-") > 0 ? qsTr("Group chat", "Contacts group page text in status message line") : Utilities.emojify(model.message, emojiPath)
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    textFormat: Text.RichText
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {"initialModel": model})
            }

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Profile", "Contact context menu profile item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            if (model.jid.indexOf("-") > 0) {
                                pageStack.push(Qt.resolvedUrl("GroupProfile.qml"), {"jid": model.jid})
                            }
                            else {
                                if (model.jid === Mitakuuluu.myJid) {
                                    pageStack.push(Qt.resolvedUrl("Account.qml"))
                                }
                                else {
                                    pageStack.push(Qt.resolvedUrl("UserProfile.qml"), {"jid": model.jid})
                                }
                            }
                        }
                    }

                    MenuItem {
                        text: qsTr("Refresh", "Contact context menu refresh item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            Mitakuuluu.refreshContact(model.jid)
                        }
                    }

                    MenuItem {
                        text: qsTr("Rename", "Contact context menu profile item")
                        visible: model.jid.indexOf("-") < 0 && model.jid !== Mitakuuluu.myJid
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("RenameContact.qml"), {"jid": model.jid})
                        }
                    }

                    MenuItem {
                        text: qsTr("Delete group", "Contact context menu delete group item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        visible: model.owner === Mitakuuluu.myJid
                        onClicked: {
                            removeGroup()
                        }
                    }

                    MenuItem {
                        text: (model.jid.indexOf("-") > 0)
                                ? qsTr("Leave group", "Contact context menu leave group item")
                                : qsTr("Delete", "Contact context menu delete contact item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            if (model.jid.indexOf("-") > 0)
                                leaveGroup()
                            else
                                removeContact()
                        }
                    }

                    /*MenuItem {
                        text: model.jid.indexOf("-") > 0
                        //% "Contact context menu contact mute item"
                                ? (model.blocked ? qsTr("Unmute")
                        //% "Contact context menu contact unmute item"
                                                 : qsTr("Mute"))
                        //% "Contact context menu contact block item"
                                : (model.blocked ? qsTr("Unblock")
                        //% "Contact context menu contact unblock item"
                                                 : qsTr("Block"))
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            if (model.jid.indexOf("-") > 0)
                                Mitakuuluu.muteOrUnmuteGroup(model.jid)
                            else
                                Mitakuuluu.blockOrUnblockContact(model.jid)
                        }
                    }*/
                }
            }
        }
    }

    ContactsFilterModel {
        id: contactsModel
        contactsModel: ContactsBaseModel
        showActive: false
        showUnknown: acceptUnknown
        hideGroups: true
        filterContacts: showMyJid ? (hidden ? hiddenList : []) : (hidden ? hiddenList.splice(0, 0, Mitakuuluu.MyJid) : [Mitakuuluu.MyJid])
        onContactsModelChanged: {
            fastScroll.init()
        }
        Component.onCompleted: {
            init()
        }
    }
}
