import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import QtLocation 5.0
import QtPositioning 5.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "conversationPage"
    allowedOrientations: lockPortrait ? Orientation.Portrait : (Orientation.Portrait | Orientation.Landscape)

    property PositionSource positionSource
    property AudioRecorder audioRecorder
    property ConversationModel conversationModel: ConversationModel {}

    onStatusChanged: {
        if (page.status === PageStatus.Inactive && pageStack.depth === 1) {
            saveText()
            Mitakuuluu.setActiveJid("")
        }
        else if (page.status === PageStatus.Active) {
            if (pageStack._currentContainer.attachedContainer == null) {
                if (isGroup) {
                    pageStack.pushAttached(Qt.resolvedUrl("GroupProfile.qml"), {"conversationModel": conversationModel, "jid": jid})
                }
                else {
                    pageStack.pushAttached(Qt.resolvedUrl("UserProfile.qml"), {"conversationModel": conversationModel, "jid": jid})
                }
            }
        }
    }

    property variant initialModel
    onInitialModelChanged: {
        //console.log("should load model")
        //console.log("jid: " + initialModel.jid)
        jid = initialModel.jid
        //console.log("name: " + initialModel.name)
        name = initialModel.nickname
        //console.log("available: " + initialModel.available)
        available = initialModel.available
        //console.log("blocked: " + initialModel.blocked)
        blocked = initialModel.blocked
        //console.log("muted: " + initialModel.muted)
        //muted = initialModel.muted
        //console.log("avatar: " + initialModel.avatar)
        avatar = initialModel.avatar
        typing = initialModel.typing

        loadText()
        conversationModel.jid = jid

        Mitakuuluu.setActiveJid(jid)
        if (!available) {
            lastseen = timestampToDateTime(initialModel.timestamp)
            Mitakuuluu.requestLastOnline(jid)
        }
    }

    property bool isGroup: jid.indexOf("-") > 0
    property int muted: 0
    property bool blocked: false
    property bool available: false
    property string name: ""
    property string jid: ""
    property string avatar: ""
    property string lastseen: ""
    property bool typing: false

    function loadText() {
        sendBox.text = Mitakuuluu.load("typing/" + jid, "")
    }

    function saveText() {
        Mitakuuluu.save("typing/" + jid, sendBox.text.trim())
    }

    function getNicknameByJid(jid) {
        if (jid == Mitakuuluu.myJid)
            return qsTr("You", "Display You instead of your own nickname")
        var model = ContactsBaseModel.getModel(jid)
        if (model && model.nickname)
            return model.nickname
        else
            return jid.split("@")[0]
    }

    function getContactColor(jid) {
        if (isGroup) {
            if (jid == Mitakuuluu.myJid) {
                return Theme.highlightColor
            }
            else {
                return ContactsBaseModel.getColorForJid(jid)
            }
        }
        else {
            if (jid == Mitakuuluu.myJid) {
                return Theme.highlightColor
            }
            else {
                return "#FFFFFF"
            }
        }
    }

    function msgStatusColor(model) {
        if (model.author != Mitakuuluu.myJid) {
            return "transparent"
        }
        else {
            if  (model.msgstatus == 4)
                return "#60ffff00"
            else if  (model.msgstatus == 5)
                return "#6000ff00"
            else
                return "#60ff0000"
        }
    }

    function timestampToDateTime(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd.MM hh:mm:ss")
    }

    function timestampToTime(stamp) {
        var d = new Date(stamp*1000)
        if (showSeconds)
            return Qt.formatDateTime(d, "hh:mm:ss")
        else
            return Qt.formatDateTime(d, "hh:mm")
    }

    function getMediaPreview(model) {
        if (model.mediatype == 1) {
            if (model.localurl.length > 0) {
                return model.localurl
            }
            else {
                return "data:" + model.mediamime + ";base64," + model.mediathumb
            }
        }
        else {
            return "data:image/jpeg;base64," + model.mediathumb
        }
    }

    Connections {
        target: Mitakuuluu
        onPresenceAvailable: {
            if (mjid == page.jid) {
                lastseen = ""
                available = true
            }
        }
        onPresenceUnavailable: {
            if (mjid == page.jid) {
                available = false
                Mitakuuluu.requestLastOnline(page.jid)
            }
        }
        onPresenceLastSeen: {
            if (mjid == page.jid && !page.available) {
                lastseen = timestampToDateTime(seconds)
            }
        }
        onPictureUpdated: {
            if (pjid == page.jid) {
                avatar = ""
                avatar = path
            }
        }
        onContactTyping: {
            if (cjid == page.jid) {
                typing = true
            }
        }
        onContactPaused: {
            if (cjid == page.jid) {
                typing = false
            }
        }
        onMessageReceived: {
            if (applicationActive && !blocked && (data.jid === jid) && (data.author != Mitakuuluu.myJid)) {
                if (notifyActive)
                    vibration.start()
                if (!conversationView.atYEnd)
                    newMessageItem.opacity = 1.0
            }
            else if (data.author == Mitakuuluu.myJid) {
                //scrollDown.start()
            }
        }
        onNewGroupSubject: {
            if (data.jid == page.jid) {
                name = data.message
            }
        }
        onContactsBlocked: {
            if (!page.isGroup) {
                if  (list.indexOf(page.jid) !== -1) {
                    blocked = true
                }
                else {
                    blocked = false
                }
            }
        }
        onGroupsMuted: {
            if (page.isGroup) {
                if  (jids.indexOf(page.jid) !== -1) {
                    blocked = true
                }
                else {
                    blocked = false
                }
            }
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        pressDelay: 0
        contentHeight: height

        PullDownMenu {
            busy: typing
            MenuItem {
                text: qsTr("Clear all messages", "Conversation menu item")
                onClicked: {
                    remorseAll.execute(qsTr("Clear all messages", "Conversation delete all messages remorse popup"),
                                       function() {
                                           conversationModel.removeConversation(page.jid)
                                           ContactsBaseModel.reloadContact(page.jid)
                                       },
                                       5000)
                }
            }

            MenuItem {
                text: qsTr("Muting", "Contacts context menu muting item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("MutingSelector.qml"), {"jid": page.jid})
                }
            }
            MenuItem {
                text: qsTr("Load old conversation", "Conversation menu item")
                visible: conversationView.count > 19
                onClicked: {
                    conversationModel.loadOldConversation(20)
                }
            }
        }

        PushUpMenu {
            id: pushMedia

            _activeHeight: mediaSendRow.height

            Row {
                id: mediaSendRow
                x: width > parent.width ? 0 : ((parent.width - width) / 2)
                height: Theme.itemSizeMedium
                spacing: Theme.paddingSmall

                IconButton {
                    icon.source: "image://theme/icon-m-image"
                    visible: !audioRecorder
                    onClicked: {
                        pushMedia.hide()
                        pageStack.push(Qt.resolvedUrl("MediaSelector.qml"), {"mode": "image", "datesort": true, "multiple": true})
                        pageStack.currentPage.accepted.connect(mediaReceiver.mediaAccepted)
                    }
                }

                IconButton {
                    icon.source: "image://theme/icon-camera-shutter-release"
                    visible: !audioRecorder
                    onClicked: {
                        pushMedia.hide()
                        pageStack.push(Qt.resolvedUrl("Capture.qml"), {"broadcastMode": false})
                        pageStack.currentPage.accepted.connect(captureReceiver.captureAccepted)
                    }
                }

                IconButton {
                    icon.source: "image://theme/icon-m-gps"
                    visible: !audioRecorder
                    onClicked: {
                        pushMedia.hide()
                        if (locationEnabled)
                            positionSourceCreationTimer.start()
                        else
                            banner.notify(qsTr("Enable location in settings!", "Banner text if GPS disabled in settings"))
                    }
                }

                Item {
                    height: 64
                    width: 64 * 3 + Theme.paddingSmall
                    visible: audioRecorder

                    Label {
                        id: recordDuration
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        text: audioRecorder ? (Format.formatDuration(audioRecorder.duration / 1000, Format.DurationShort)) : ""
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    Label {
                        id: deleteVoiceLabel
                        anchors {
                            top: recordDuration.bottom
                            horizontalCenter: recordDuration.horizontalCenter
                        }
                        text: qsTr("Delete", "Conversation voice recorder delete label")
                        color: Theme.secondaryColor
                        visible: !voiceSend.containsMouse
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }

                IconButton {
                    id: voiceSend
                    icon.source: "image://theme/icon-cover-unmute"
                    icon.width: 64
                    icon.height: 64
                    property bool voiceReady: false
                    onClicked: {
                        voiceRecordTimer.stop()
                        banner.notify(qsTr("Hold button for recorfing, release to send", "Conversation voice recorder description label"))
                    }
                    onPressed: {
                        voiceRecordTimer.start()
                        page.forwardNavigation = false
                        page.backNavigation = false
                    }
                    onReleased: {
                        if (audioRecorder) {
                            audioRecorder.stop()
                            if (containsMouse) {
                                var voiceMedia = Mitakuuluu.saveVoice(audioRecorder.path)
                                Mitakuuluu.sendMedia([page.jid], voiceMedia)
                            }
                            Mitakuuluu.rejectMediaCapture(audioRecorder.path)
                            audioRecorder.destroy()
                            pushMedia.hide()
                        }
                        page.forwardNavigation = true
                        page.backNavigation = true
                    }
                    onPositionChanged: {
                        recordDuration.anchors.leftMargin = mouse.x
                        recordDuration.color = containsMouse ? Theme.primaryColor : "red"
                    }
                }

                Item {
                    width: 64
                    height: 64
                    visible: audioRecorder
                }

                IconButton {
                    icon.source: "image://theme/icon-m-people"
                    visible: !audioRecorder
                    onClicked: {
                        pushMedia.hide()
                        pageStack.push(Qt.resolvedUrl("SendContactCard.qml"))
                        pageStack.currentPage.accepted.connect(vcardReceiver.contactAccepted)
                    }
                }
            }
        }

        PageHeader {
            id: header
            clip: true
            Rectangle {
                smooth: true
                width: parent.width
                height: 20
                anchors.bottom: parent.bottom
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop {
                        position: 1.0
                        color: page.blocked ? Theme.rgba("red", 0.6)
                                            : (Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn ? (page.available ? Theme.rgba(Theme.highlightColor, 0.6)
                                                                                                                    : "transparent")
                                                                                                  : "transparent")
                    }
                }
            }
            AvatarHolder {
                id: pic
                height: parent.height - (Theme.paddingSmall * 2)
                width: height
                source: page.avatar
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
            }
            Column {
                id: hColumn
                anchors.left: parent.left
                anchors.leftMargin: pic.width
                anchors.right: pic.left
                spacing: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    id: nameText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    truncationMode: TruncationMode.Fade
                    text: Utilities.emojify(page.name, emojiPath)
                }
                Label {
                    id: lastSeenText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.family: Theme.fontFamily
                    text: typing
                            ? qsTr("Typing...", "Contact typing converstation text")
                            : qsTr("Last seen: %1", "Last seen converstation text").arg(lastseen)
                    visible: typing || (!available && page.jid.indexOf("-") == -1 && text.length > 0)
                }
            }
        }

        SilicaListView {
            id: conversationView
            model: conversationModel
            anchors {
                top: header.bottom
                bottom: sendBox.top
            }
            width: parent.width
            clip: true
            cacheBuffer: height * 2
            pressDelay: 0
            spacing: Theme.paddingMedium
            interactive: true
            currentIndex: -1
            verticalLayoutDirection: ListView.BottomToTop
            delegate: Component {
                id: delegateComponent
                Loader {
                    width: parent.width
                    asynchronous: false
                    source: Qt.resolvedUrl("ModernDelegate.qml")
                }
            }
            MouseArea {
                id: newMessageItem
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: visible ? (message.paintedHeight + (Theme.paddingLarge * 2)) : 0
                visible: opacity > 0
                opacity: 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.InOutQuad
                        properties: "opacity,height"
                    }
                }

                Rectangle {
                    id: bg
                    anchors.fill: parent
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    id: message
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingRight
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    text: qsTr("New message", "Conversation new message indicator")
                }

                onClicked: {
                    if (!conversationView.atYEnd)
                        scrollDownTimer.start()
                    opacity = 0.0
                }
            }

            onFlickStarted: {
                if (verticalVelocity < 0)
                {
                    iconDown.opacity = 0.0;
                    iconUp.opacity = 1.0;
                }
                else
                {
                    iconUp.opacity = 0.0;
                    iconDown.opacity = 1.0;
                }
            }
            onMovementEnded: {
                hideIconsTimer.start()
            }

            VerticalScrollDecorator {}
        }

        EmojiTextArea {
            id: sendBox
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: - Theme.paddingMedium
            anchors.right: parent.right
            anchors.rightMargin: - Theme.paddingMedium
            placeholderText: qsTr("Tap here to enter message", "Message composing tet area placeholder")
            focusOutBehavior: hideKeyboard ? FocusBehavior.ClearItemFocus : FocusBehavior.KeepFocus
            textRightMargin: sendByEnter ? 0 : 64
            property bool buttonVisible: sendByEnter
            maxHeight: page.isPortrait ? 200 : 140
            background: Component {
                Item {
                    anchors.fill: parent

                    IconButton {
                        id: sendButton
                        icon.source: "image://theme/icon-m-message"
                        highlighted: enabled
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: - Theme.paddingSmall
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingSmall
                        visible: !sendBox.buttonVisible
                        enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn && sendBox.text.trim().length > 0
                        onClicked: {
                            sendBox.send()
                        }
                    }
                }
            }
            EnterKey.enabled: sendByEnter ? (Mitakuuluu.connectionStatus == 4 && text.trim().length > 0) : true
            EnterKey.highlighted: text.trim().length > 0
            EnterKey.iconSource: sendByEnter ? "image://theme/icon-m-message" : "image://theme/icon-m-enter"
            EnterKey.onClicked: {
                if (sendByEnter) {
                    send()
                }
            }
            onTextChanged: {
                if (!typingTimer.running) {
                    Mitakuuluu.startTyping(page.jid)
                    typingTimer.start()
                }
                else
                    typingTimer.restart()
            }
            function send() {
                deselect()
                console.log("send: " + sendBox.text.trim())
                Mitakuuluu.sendText(page.jid, sendBox.text.trim())
                sendBox.text = ""
                if (hideKeyboard)
                    focus = false
                saveText()
            }
        }

        IconButton {
            id: iconUp
            anchors {
                top: header.bottom
                right: parent.right
                margins: Theme.paddingMedium
            }
            icon.source: "image://theme/icon-l-up"
            visible: opacity > 0.0
            opacity: 0.0
            onClicked: {
                if (!conversationView.atYBeginning)
                    scrollUpTimer.start()
            }
            Behavior on opacity {
                FadeAnimation {}
            }
        }

        IconButton {
            id: iconDown
            anchors {
                bottom: sendBox.top
                right: parent.right
                margins: Theme.paddingMedium
            }
            icon.source: "image://theme/icon-l-down"
            visible: opacity > 0.0
            opacity: 0.0
            onClicked: {
                if (!conversationView.atYEnd)
                    scrollDownTimer.start()
            }
            Behavior on opacity {
                FadeAnimation {}
            }
        }
    }

    RemorsePopup {
        id: remorseAll
    }

    Timer {
        id: forceTimer
        interval: 300
        triggeredOnStart: false
        repeat: false
        onTriggered: sendBox.forceActiveFocus()
    }

    Timer {
        id: typingTimer
        interval: 3000
        triggeredOnStart: false
        repeat: false
        onTriggered: Mitakuuluu.endTyping(page.jid)
    }

    Timer {
        id: hideIconsTimer
        interval: 3000
        onTriggered: {
            iconUp.opacity = 0.0
            iconDown.opacity = 0.0
        }
    }

    Timer {
        id: scrollDownTimer
        interval: 1
        repeat: true
        onTriggered: {
            conversationView.contentY += 100
            if (conversationView.atYEnd) {
                scrollDownTimer.stop()
                iconDown.opacity = 0.0
                conversationView.returnToBounds()
            }
        }
    }

    Timer {
        id: scrollUpTimer
        interval: 1
        repeat: true
        onTriggered: {
            conversationView.contentY -= 100
            if (conversationView.atYBeginning) {
                scrollUpTimer.stop()
                iconUp.opacity = 0.0
                conversationView.returnToBounds()
            }
        }
    }

    Timer {
        id: voiceRecordTimer
        interval: 500
        onTriggered: {
            createVoiceRecorder()
        }
    }

    function createVoiceRecorder() {
        console.log("creating recorder component")
        audioRecorder = recorderComponent.createObject(null)
        audioRecorder.record()
        recordDuration.anchors.leftMargin = 0
    }

    Component {
        id: recorderComponent
        AudioRecorder {}
    }

    Timer {
        id: positionSourceRecreationTimer
        interval: 1500
        onTriggered: {
            createPositionSource()
        }
    }

    Timer {
        id: positionSourceCreationTimer
        interval: 1
        onTriggered: {
            createPositionSource()
        }
    }

    function createPositionSource() {
        console.log("creating location component")
        positionSource = positionSourceComponent.createObject(null)
    }

    Component {
        id: positionSourceComponent
        PositionSource {
            active: true
            updateInterval : 1000

            onPositionChanged: {
                if (positionSource
                        && positionSource.position
                        && positionSource.position.longitudeValid
                        && positionSource.position.latitudeValid) {
                    Mitakuuluu.sendLocation(page.jid,
                                            positionSource.position.coordinate.latitude,
                                            positionSource.position.coordinate.longitude,
                                            16,
                                            false)
                    positionSource.destroy()
                }
            }

            Component.onCompleted: {
                banner.notify(qsTr("Waiting for coordinates...", "Conversation location sending banner text"))
                console.log("waiting for coordinates")
            }

            onSourceErrorChanged: {
                if (sourceError === PositionSource.ClosedError) {
                    console.log("Position source backend closed, restarting...")
                    positionSourceRecreationTimer.restart()
                    positionSource.destroy()
                }
            }
        }
    }

    QtObject {
        id: captureReceiver
        property string imagePath: ""

        function captureAccepted() {
            pageStack.currentPage.accepted.disconnect(captureReceiver.captureAccepted)
            imagePath = pageStack.currentPage.imagePath
            Mitakuuluu.sendMedia([page.jid], imagePath)
        }
    }

    QtObject {
        id: mediaReceiver
        property variant mediaFiles: []

        function mediaAccepted() {
            pageStack.currentPage.accepted.disconnect(mediaReceiver.mediaAccepted)
            mediaFiles = pageStack.currentPage.selectedFiles
            for (var i = 0; i < mediaFiles.length; i++) {
                Mitakuuluu.sendMedia([page.jid], mediaFiles[i])
            }
        }
    }

    QtObject {
        id: vcardReceiver
        property variant vcardData
        property string displayName

        function contactAccepted() {
            pageStack.currentPage.accepted.disconnect(vcardReceiver.contactAccepted)
            vcardData = pageStack.currentPage.vCardData
            displayName = pageStack.currentPage.displayLabel
            Mitakuuluu.sendVCard([page.jid], displayName, vcardData)
        }
    }
}
