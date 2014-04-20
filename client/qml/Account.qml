import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Dialog {
    id: page
    objectName: "account"

    property string pushname: ""
    property string presence: ""
    property int creation: 0
    property int expiration: 0
    property bool active: true
    property string kind: "free"
    property string avatar: Mitakuuluu.getAvatarForJid(Mitakuuluu.myJid)

    canAccept: (Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn)
               && (pushnameArea.text.length > 0)
               && (presenceArea.text.length > 0)

    Connections {
        target: Mitakuuluu

        onPictureUpdated: {
            if (pjid === Mitakuuluu.myJid) {
                page.avatar = ""
                page.avatar = path
            }
        }
    }

    onStatusChanged: {
        if (status == DialogStatus.Opened) {
            pushname = Mitakuuluu.load("account/pushname", "WhatsApp user")
            pushnameArea.text = pushname
            presence = Mitakuuluu.load("account/presence", "I'm using Mitakuuluu!")
            presenceArea.text = presence
            creation = Mitakuuluu.load("account/creation", 0)
            expiration = Mitakuuluu.load("account/expiration", 0)
            kind = Mitakuuluu.load("account/kind", "free")
            active = Mitakuuluu.load("account/accountstatus", "active") == "active"
        }
    }

    onAccepted: {
        page.pushname = pushnameArea.text
        Mitakuuluu.save("account/pushname", pushnameArea.text.trim())
        Mitakuuluu.setMyPushname(pushnameArea.text)
        ContactsBaseModel.renameContact(Mitakuuluu.myJid, pushnameArea.text.trim())
        pushnameArea.focus = false
        page.forceActiveFocus()

        page.presence = presenceArea.text
        Mitakuuluu.save("account/presence", presenceArea.text.trim())
        Mitakuuluu.setMyPresence(presenceArea.text)
        presenceArea.focus = false
        page.forceActiveFocus()
    }

    function timestampToFullDate(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd MMM yyyy")
    }

    SilicaFlickable {
        anchors.fill: page
        clip: true

        PullDownMenu {
            MenuItem {
                text: qsTr("Remove account", "Account page menu item")
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    deleteDialog.open()
                }
            }
            MenuItem {
                text: qsTr("Renew subscription", "Account page menu item")
                //visible: ((page.expiration * 1000) - (new Date().getTime())) < 259200000
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Payments.qml"))
                }
            }
        }

        DialogHeader {
            id: header
            title: qsTr("Account", "Account page title")
            acceptText: qsTr("Save", "Account page accept button text")
        }

        Label {
            id: pushnameLabel
            text: qsTr("Nickname:", "Account page nickname title")
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            anchors.top: pushnameArea.top
            anchors.topMargin: Theme.paddingSmall
        }

        TextField {
            id: pushnameArea
            anchors.top: header.bottom
            anchors.left: pushnameLabel.right
            anchors.right: parent.right
            text: page.pushname
            EnterKey.enabled: false//text.trim().length > 0
            EnterKey.highlighted: EnterKey.enabled
            //EnterKey.iconSource: "image://theme/icon-m-enter-next"
            //EnterKey.text: "save"
            /*EnterKey.onClicked: {
                page.pushname = text
                Mitakuuluu.save("account/pushname", text.trim())
                Mitakuuluu.setMyPushname(text.trim())
                pushnameArea.focus = false
                page.forceActiveFocus()
            }*/
            onActiveFocusChanged: {
                if (activeFocus)
                    selectAll()
            }
        }

        Label {
            id: presenceLabel
            text: qsTr("Status:", "Account page status title")
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            anchors.top: presenceArea.top
            anchors.topMargin: Theme.paddingSmall
        }

        TextField {
            id: presenceArea
            anchors.top: pushnameArea.bottom
            anchors.left: presenceLabel.right
            anchors.right: parent.right
            text: page.presence
            EnterKey.enabled: false//text.trim().length > 0
            EnterKey.highlighted: EnterKey.enabled
            //EnterKey.iconSource: "image://theme/icon-m-enter-next"
            //EnterKey.text: "save"
            /*EnterKey.onClicked: {
                page.presence = text
                Mitakuuluu.save("account/status", text.trim())
                Mitakuuluu.setMyPresence(text.trim())
                presenceArea.focus = false
                page.forceActiveFocus()
            }*/
            onActiveFocusChanged: {
                if (activeFocus)
                    selectAll()
            }
        }

        Label {
            id: labelCreated
            text: qsTr("Created: %1", "Account page created title").arg(timestampToFullDate(page.creation))
            anchors.top: presenceArea.bottom
            anchors.topMargin: Theme.paddingLarge
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingSmall
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall
        }

        Label {
            id: labelExpired
            text: qsTr("Expiration: %1", "Account page expiration title").arg(timestampToFullDate(page.expiration))
            anchors.top: labelCreated.bottom
            anchors.topMargin: Theme.paddingSmall
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingSmall
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall
        }

        Label {
            id: labelActive
            text: page.active ? qsTr("Account is active", "Account page account active label")
                              : qsTr("Account is blocked", "Account page account blocked label")
            anchors.top: labelExpired.bottom
            anchors.topMargin: Theme.paddingSmall
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingSmall
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall
        }

        Label {
            id: labelType
            text: qsTr("Account type: %1", "Account page account type label").arg(page.kind)
            anchors.top: labelActive.bottom
            anchors.topMargin: Theme.paddingSmall
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingSmall
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall
        }

        AvatarHolder {
            id: ava
            anchors.top: presenceArea.bottom
            anchors.topMargin: Theme.paddingLarge
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            width: 128
            height: 128
            source: page.avatar

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    avatarView.show(page.avatar)
                }
            }
        }
    }

    RemorsePopup {
        id: remorseAccount
    }

    Dialog {
        id: deleteDialog
        SilicaFlickable {
            anchors.fill: parent
            DialogHeader {
                id: dheader
                title: qsTr("Remove account", "Account page remove dialog title")
            }
            Column {
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.centerIn: parent
                spacing: Theme.paddingLarge
                Label {
                    width: parent.width
                    text: qsTr("This action will delete your account information from phone and from WhatsApp server.", "Account page remove dialog description")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
        onAccepted: {
            //pageStack.pop(roster, PageStackAction.Immediate)
            //pageStack.replace(removePage)
            Mitakuuluu.removeAccountFromServer()
            Mitakuuluu.clearGroup("account")
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
                pageStack.push(Qt.resolvedUrl("ResizePicture.qml"), {"picture": imgPath, "jid": Mitakuuluu.myJid, "maximumSize": 480})
                pageStack.currentPage.accepted.connect(avatarView.setNewAvatar)
            }
        }
        function setNewAvatar() {
            pageStack.currentPage.accepted.disconnect(avatarView.setNewAvatar)
            avaView.source = ""
            avaView.source = pageStack.currentPage.filename
            Mitakuuluu.setPicture(Mitakuuluu.myJid, avaView.source)
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
            text: qsTr("Change", "Account page avatar change button")
            onClicked: {
                pageStack.push(Qt.resolvedUrl("MediaSelector.qml"), {"canChangeType": false})
                pageStack.currentPage.accepted.connect(avatarView.resizeAvatar)
            }
        }
    }
}
