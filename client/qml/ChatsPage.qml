import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "rosterPage"

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (pageStack._currentContainer.attachedContainer == null) {
                pageStack.pushAttached(Qt.resolvedUrl("ContactsPage.qml"))
            }
        }
    }

    function parseConnectionAction(value) {
        var array = [qsTr("Restart engine", "Main menu action"),
                     qsTr("Force connect", "Main menu action"),
                     qsTr("Disconnect", "Main menu action"),
                     qsTr("Disconnect", "Main menu action"),
                     qsTr("Disconnect", "Main menu action"),
                     qsTr("Register", "Main menu action"),
                     qsTr("Connect", "Main menu action"),
                     qsTr("No action", "Main menu action"),
                     qsTr("Register", "Main menu action")]
        return array[value]
    }

    SilicaFlickable {
        id: flickView
        anchors.fill: parent
        clip: true
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                id: shutdown
                text: qsTr("Full quit", "Main menu action")
                font.bold: true
                onClicked: {
                    remorseDisconnect.execute(qsTr("Quit and shutdown engine", "Full quit remorse popup"),
                                              function() {
                                                  shutdownEngine()
                                              },
                                              5000)
                }
            }

            MenuItem {
                id: connectDisconnect
                text: parseConnectionAction(Mitakuuluu.connectionStatus)
                onClicked: {
                    if (Mitakuuluu.connectionStatus < Mitakuuluu.Connecting) {
                        Mitakuuluu.forceConnection()
                    }
                    else if (Mitakuuluu.connectionStatus > Mitakuuluu.WaitingForConnection && Mitakuuluu.connectionStatus < Mitakuuluu.LoginFailure) {
                        remorseDisconnect.execute(qsTr("Disconnecting", "Disconnect remorse popup"),
                                                   function() {
                                                       Mitakuuluu.disconnect()
                                                   },
                                                   5000)
                    }
                    else if (Mitakuuluu.connectionStatus == Mitakuuluu.Disconnected)
                        Mitakuuluu.authenticate()
                    else
                        pageStack.replace(Qt.resolvedUrl("RegistrationPage.qml"))
                }
            }

            MenuItem {
                text: qsTr("Muted contacts", "Main menu action")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("MutedContacts.qml"))
                }
            }

            MenuItem {
                text: qsTr("Broadcast", "Main menu action")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Broadcast.qml"))
                }
            }
            MenuItem {
                text: qsTr("Settings", "Main menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Settings.qml"))
                }
            }
        }

        PageHeader {
            id: header
            title: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn ? qsTr("Chats", "Contacts page title") : ""

            Label {
                id: headerText
                width: Math.min(implicitWidth, parent.width - Theme.paddingLarge)
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                visible: Mitakuuluu.connectionStatus != Mitakuuluu.LoggedIn
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: pageStack._pageStackIndicator.width
                }
                font {
                    pixelSize: Theme.fontSizeLarge
                    family: Theme.fontFamilyHeading
                }
                text: Mitakuuluu.connectionString
            }
        }

        SilicaListView {
            id: listView
            model: contactsModel
            delegate: listDelegate
            anchors.top: header.bottom
            width: parent.width
            anchors.bottom: parent.bottom
            clip: true
            cacheBuffer: page.height * 2
            pressDelay: 0
            spacing: Theme.paddingSmall
            section.property: "nickname"
            section.criteria: ViewSection.FirstCharacter
            currentIndex: -1
        }
    }

    Component {
        id: listDelegate
        ListItem {
            id: item
            width: ListView.view.width
            contentHeight: Theme.itemSizeMedium
            //visible: model.visible ? (model.jid !== Mitakuuluu.myJid || showMyJid) : false
            ListView.onRemove: animateRemoval(item)
            menu: contextMenu

            function remove() {
                remorseAction(model.jid.indexOf("-") > 0 ? qsTr("Leave group %1", "Group leave remorse action text").arg(model.nickname)
                                                         : qsTr("Delete", "Delete contact remorse action text"),
                              function() {
                                  if (model.jid.indexOf("-") > 0) {
                                      Mitakuuluu.groupLeave(model.jid)
                                  }
                                  ContactsBaseModel.deleteContact(model.jid)
                              })
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
                    text: model.typing ? qsTr("Typing...", "Contact status typing text")
                                       : (model.jid.indexOf("-") > 0 ? qsTr("Group chat", "Contacts group page text in status message line") : Utilities.emojify(model.message, emojiPath))
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: model.typing ? (item.highlighted ? Theme.highlightColor : Theme.primaryColor)
                                        : (item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                    textFormat: Text.RichText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.bold: model.typing
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
                        text: qsTr("Muting", "Contacts context menu muting item")
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("MutingSelector.qml"), {"jid": model.jid})
                        }
                    }

                    MenuItem {
                        text: (model.jid.indexOf("-") > 0)
                                ? qsTr("Leave group", "Contact context menu leave group item")
                                : qsTr("Delete", "Contact context menu delete contact item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            remove()
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

    RemorsePopup {
        id: remorseDisconnect
    }

    ContactsFilterModel {
        id: contactsModel
        contactsModel: ContactsBaseModel
        showActive: true
        showUnknown: true
    }
}
