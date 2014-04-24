import QtQuick 2.0
import Sailfish.Silica 1.0
import QtFeedback 5.0
import org.nemomobile.configuration 1.0
import harbour.mitakuuluu2.client 1.0

ApplicationWindow {
    id: appWindow
    objectName: "appWindow"
    cover: Qt.resolvedUrl("CoverPage.qml")
    initialPage: (Mitakuuluu.load("account/phoneNumber", "unregistered") === "unregistered") ?
                     Qt.resolvedUrl("RegistrationPage.qml") : Qt.resolvedUrl("ChatsPage.qml")

    property bool sendByEnter: false
    onSendByEnterChanged: Mitakuuluu.save("settings/sendByEnter", sendByEnter)

    property bool showTimestamp: true
    onShowTimestampChanged: Mitakuuluu.save("settings/showTimestamp", showTimestamp)

    property int fontSize: 32
    onFontSizeChanged: Mitakuuluu.save("settings/fontSize", fontSize)

    property bool followPresence: false
    onFollowPresenceChanged: {
        Mitakuuluu.save("settings/followPresence", followPresence)
        updateCoverActions()
        pageStack.push()
    }

    property alias locationEnabled: locationEnabledConfig.value

    ConfigurationValue {
        id: locationEnabledConfig
        key: "/jolla/location/enabled"
        defaultValue: false
    }

    property bool showSeconds: true
    onShowSecondsChanged: Mitakuuluu.save("settings/showSeconds", showSeconds)

    property bool showMyJid: false
    onShowMyJidChanged: Mitakuuluu.save("settings/showMyJid", showMyJid)

    property bool showKeyboard: false
    onShowKeyboardChanged: Mitakuuluu.save("settings/showKeyboard", showKeyboard)

    property bool acceptUnknown: true
    onAcceptUnknownChanged: Mitakuuluu.save("settings/acceptUnknown", acceptUnknown)

    property bool notifyActive: true
    onNotifyActiveChanged: Mitakuuluu.save("settings/notifyActive", notifyActive)

    property bool resizeImages: false
    onResizeImagesChanged: Mitakuuluu.save("settings/resizeImages", resizeImages)

    property bool resizeBySize: true
    onResizeBySizeChanged: Mitakuuluu.save("settings/resizeBySize", resizeBySize)

    property int resizeImagesTo: 1048546
    onResizeImagesToChanged: Mitakuuluu.save("settings/resizeImagesTo", resizeImagesTo)

    property double resizeImagesToMPix: 5.01
    onResizeImagesToMPixChanged: Mitakuuluu.save("settings/resizeImagesToMPix", resizeImagesToMPix)

    property string conversationTheme: "/usr/share/harbour-mitakuuluu2/qml/DefaultDelegate.qml"
    onConversationThemeChanged: Mitakuuluu.save("settings/conversationTheme", conversationTheme)

    property int conversationIndex: 0
    onConversationIndexChanged: Mitakuuluu.save("settings/conversationIndex", conversationIndex)

    property bool alwaysOffline: false
    onAlwaysOfflineChanged: {
        Mitakuuluu.save("settings/alwaysOffline", alwaysOffline)
        if (alwaysOffline)
            Mitakuuluu.setPresenceUnavailable()
        else
            Mitakuuluu.setPresenceAvailable()
        updateCoverActions()
    }
    property bool deleteMediaFiles: false
    onDeleteMediaFilesChanged: Mitakuuluu.save("settings/deleteMediaFiles", deleteMediaFiles)

    property bool importToGallery: true
    onImportToGalleryChanged: Mitakuuluu.save("settings/importToGallery", importToGallery)

    property bool showConnectionNotifications: false
    onShowConnectionNotificationsChanged: Mitakuuluu.save("settings/showConnectionNotifications", showConnectionNotifications)

    property bool lockPortrait: false
    onLockPortraitChanged: Mitakuuluu.save("settings/lockPortrait", lockPortrait)

    property string connectionServer: "c3.whatsapp.net"
    onConnectionServerChanged: Mitakuuluu.save("connection/server", connectionServer)

    property bool notificationsMuted: false
    onNotificationsMutedChanged: {
        Mitakuuluu.save("settings/notificationsMuted", notificationsMuted)
        updateCoverActions()
    }

    property bool threading: true
    onThreadingChanged: Mitakuuluu.save("connection/threading", threading)

    property bool hideKeyboard: false
    onHideKeyboardChanged: Mitakuuluu.save("settings/hideKeyboard", hideKeyboard)

    property bool notifyMessages: false
    onNotifyMessagesChanged: Mitakuuluu.save("settings/notifyMessages", notifyMessages)

    property bool keepLogs: false
    onKeepLogsChanged: Mitakuuluu.save("settings/keepLogs", keepLogs)

    property string mapSource: "here"
    onMapSourceChanged: Mitakuuluu.save("settings/mapSource", mapSource)

    property bool automaticDownload: false
    onAutomaticDownloadChanged: Mitakuuluu.save("settings/autodownload", automaticDownload)

    property int automaticDownloadBytes: 524288
    onAutomaticDownloadBytesChanged: Mitakuuluu.save("settings/automaticdownload", automaticDownloadBytes)

    property bool sentLeft: false
    onSentLeftChanged: Mitakuuluu.save("settings/sentLeft", sentLeft)

    property bool systemNotifications: true
    onSystemNotificationsChanged: Mitakuuluu.save("settings/systemNotifications", systemNotifications)

    property int currentOrientation: pageStack._currentOrientation

    /*property PeopleModel allContactsModel: PeopleModel {
        filterType: PeopleModel.FilterAll
        requiredProperty: PeopleModel.PhoneNumberRequired
    }*/

    property string coverIconLeft: "../images/icon-cover-location-left.png"
    property string coverIconRight: "../images/icon-cover-camera-right.png"
    property bool coverActionActive: false

    function coverLeftClicked() {
        coverAction(coverLeftAction)
    }

    function coverRightClicked() {
        coverAction(coverRightAction)
    }

    function coverAction(index) {
        switch (index) {
        case 0: //exit
            shutdownEngine()
            break
        case 1: //presence
            if (followPresence) {
                followPresence = false
                alwaysOffline = false
            }
            else {
                if (alwaysOffline) {
                    followPresence = true
                    alwaysOffline = false
                }
                else {
                    followPresence = false
                    alwaysOffline = true
                }
            }
            break
        case 2: //global muting
            notificationsMuted = !notificationsMuted
            break
        case 3: //camera
            coverActionActive = true
            captureAndSend()
            pageStack.currentPage.rejected.connect(coverReceiver.operationRejected)
            appWindow.activate()
            break
        case 4: //location
            coverActionActive = true
            locateAndSend()
            pageStack.currentPage.rejected.connect(coverReceiver.operationRejected)
            appWindow.activate()
            break
        case 5: //voice
            coverActionActive = true
            recordAndSend()
            pageStack.currentPage.rejected.connect(coverReceiver.operationRejected)
            appWindow.activate()
            break
        default:
            break
        }
        updateCoverActions()
    }

    QtObject {
        id: coverReceiver

        function operationRejected() {
            coverActionActive = false
        }
    }

    function captureAndSend() {
        pageStack.push(Qt.resolvedUrl("Capture.qml"), {"broadcastMode": true})
        pageStack.currentPage.accepted.connect(captureReceiver.captureAccepted)
    }

    QtObject {
        id: captureReceiver
        property string imagePath: ""

        function captureAccepted() {
            pageStack.currentPage.accepted.disconnect(captureReceiver.captureAccepted)
            captureReceiver.imagePath = pageStack.currentPage.imagePath
            console.log("capture accepted: " + captureReceiver.imagePath)
            pageStack.busyChanged.connect(captureReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(captureReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(captureReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(captureReceiver.contactsRejected)
            }
        }

        function contactsUnbind() {
            pageStack.currentPage.accepted.disconnect(captureReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(captureReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsRejected() {
            contactsUnbind()
            Mitakuuluu.rejectMediaCapture(captureReceiver.imagePath)
        }

        function contactsSelected() {
            contactsUnbind()
            Mitakuuluu.sendMedia(pageStack.currentPage.jids, captureReceiver.imagePath)
        }
    }

    function locateAndSend() {
        pageStack.push(Qt.resolvedUrl("Location.qml"), {"broadcastMode": true})
        pageStack.currentPage.accepted.connect(locationReceiver.locationAccepted)
    }

    QtObject {
        id: locationReceiver
        property real latitude: 55.159479
        property real longitude: 61.402796
        property int zoom: 16
        property bool googlemaps: false

        function locationAccepted() {
            pageStack.currentPage.accepted.disconnect(locationReceiver.locationAccepted)
            latitude = pageStack.currentPage.latitude
            longitude = pageStack.currentPage.longitude
            zoom = pageStack.currentPage.zoom
            googlemaps = pageStack.currentPage.googlemaps
            pageStack.busyChanged.connect(locationReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(locationReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(locationReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(locationReceiver.contactsRejected)
            }
        }

        function contactsRejected() {
            pageStack.currentPage.accepted.disconnect(locationReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(locationReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsSelected() {
            contactsRejected()
            Mitakuuluu.sendLocation(pageStack.currentPage.jids, latitude, longitude, zoom, googlemaps)
        }
    }

    function recordAndSend() {
        pageStack.push(Qt.resolvedUrl("Recorder.qml"), {"broadcastMode": true})
        pageStack.currentPage.accepted.connect(recorderReceiver.recordingAccepted)
    }

    QtObject {
        id: recorderReceiver
        property string voicePath: ""

        function recordingAccepted() {
            console.log("recorder accepted")
            pageStack.currentPage.accepted.disconnect(recorderReceiver.recordingAccepted)
            recorderReceiver.voicePath = pageStack.currentPage.savePath
            pageStack.busyChanged.connect(recorderReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(recorderReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(recorderReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(recorderReceiver.contactsRejected)
            }
        }

        function contactsUnbind() {
            pageStack.currentPage.accepted.disconnect(recorderReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(recorderReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsRejected() {
            contactsUnbind()
            Mitakuuluu.rejectMediaCapture(recorderReceiver.voicePath)
        }

        function contactsSelected() {
            contactsUnbind()
            Mitakuuluu.sendMedia(pageStack.currentPage.jids, recorderReceiver.voicePath)
        }
    }

    function getMediaAndSend() {
        pageStack.push(Qt.resolvedUrl("MediaSelector.qml"), {"mode": "image", "datesort": true, "multiple": false})
        pageStack.currentPage.accepted.connect(mediaReceiver.mediaAccepted)
    }

    QtObject {
        id: mediaReceiver
        property variant mediaFile

        function mediaAccepted() {
            console.log("media accepted")
            pageStack.currentPage.accepted.disconnect(mediaReceiver.mediaAccepted)
            mediaFile = pageStack.currentPage.selectedFiles[0]
            pageStack.busyChanged.connect(mediaReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(mediaReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(mediaReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(mediaReceiver.contactsRejected)
            }
        }

        function contactsRejected() {
            pageStack.currentPage.accepted.disconnect(mediaReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(mediaReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsSelected() {
            contactsRejected()
            Mitakuuluu.sendMedia(pageStack.currentPage.jids, mediaReceiver.mediaFile)
        }
    }

    function typeAndSend() {
        pageStack.push(Qt.resolvedUrl("MessageComposer.qml"))
        pageStack.currentPage.accepted.connect(textReceiver.textAccepted)
    }

    QtObject {
        id: textReceiver
        property string message

        function textAccepted() {
            console.log("text accepted")
            pageStack.currentPage.accepted.disconnect(textReceiver.textAccepted)
            message = pageStack.currentPage.message
            pageStack.busyChanged.connect(textReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(textReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(textReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(textReceiver.contactsRejected)
            }
        }

        function contactsRejected() {
            pageStack.currentPage.accepted.disconnect(textReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(textReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsSelected() {
            contactsRejected()
            Mitakuuluu.sendBroadcast(pageStack.currentPage.jids, textReceiver.message)
        }
    }

    property int coverLeftAction: 4
    onCoverLeftActionChanged: {
        Mitakuuluu.save("settings/coverLeftAction", coverLeftAction)
        updateCoverActions()
    }
    property int coverRightAction: 3
    onCoverRightActionChanged: {
        Mitakuuluu.save("settings/coverRightAction", coverRightAction)
        updateCoverActions()
    }

    function updateCoverActions() {
        coverIconLeft = getCoverActionIcon(coverLeftAction, true)
        coverIconRight = getCoverActionIcon(coverRightAction, false)
    }

    function getCoverActionIcon(index, left) {
        switch (index) {
        case 0: //quit
            return "../images/icon-cover-quit-" + (left ? "left" : "right") + ".png"
        case 1: //presence
            if (followPresence)
                return "../images/icon-cover-autoavailable-" + (left ? "left" : "right") + ".png"
            else {
                if (alwaysOffline)
                    return "../images/icon-cover-unavailable-" + (left ? "left" : "right") + ".png"
                else
                    return "../images/icon-cover-available-" + (left ? "left" : "right") + ".png"
            }
        case 2: //global muting
            if (notificationsMuted)
                return "../images/icon-cover-muted-" + (left ? "left" : "right") + ".png"
            else
                return "../images/icon-cover-unmuted-" + (left ? "left" : "right") + ".png"
        case 3: //camera
            return "../images/icon-cover-camera-" + (left ? "left" : "right") + ".png"
        case 4: //location
            return "../images/icon-cover-location-" + (left ? "left" : "right") + ".png"
        case 5: //recorder
            return "../images/icon-cover-recorder-" + (left ? "left" : "right") + ".png"
        default:
            return ""
        }
    }

    function shutdownEngine() {
        Mitakuuluu.shutdown()
        Qt.quit()
    }

    onCurrentOrientationChanged: {
        if (Qt.inputMethod.visible) {
            Qt.inputMethod.hide()
        }
        pageStack.currentPage.forceActiveFocus()
    }

    onApplicationActiveChanged: {
        console.log("Application " + (applicationActive ? "active" : "inactive"))
        if (pageStack.currentPage.objectName === "conversationPage") {
            if (applicationActive) {
                Mitakuuluu.setActiveJid(pageStack.currentPage.jid)
            }
            else {
                Mitakuuluu.setActiveJid("")
            }
        }
        if (followPresence && Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn) {
            console.log("follow presence")
            if (applicationActive) {
                Mitakuuluu.setPresenceAvailable()
            }
            else {
                Mitakuuluu.setPresenceUnavailable()
            }
        }
        if (applicationActive) {
            Mitakuuluu.windowActive()
        }
    }

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            console.log("[PageStack] " + pageStack.currentPage.objectName)
        }
    }

    Connections {
        target: Mitakuuluu
        onConnectionStatusChanged: {
            console.log("connectionStatus: " + Mitakuuluu.connectionStatus)
        }
        onNotificationOpenJid: {
            activate()
            if (njid.length > 0) {
                console.log("should open " + njid)
                while (pageStack.depth > 1) {
                    pageStack.navigateBack(PageStackAction.Immediate)
                }
                pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {"initialModel": ContactsBaseModel.getModel(njid)}, PageStackAction.Immediate)
            }
        }
    }

    Component.onCompleted: {
        sendByEnter = Mitakuuluu.load("settings/sendByEnter", false)
        showTimestamp = Mitakuuluu.load("settings/showTimestamp", true)
        fontSize = Mitakuuluu.load("settings/fontSize", 32)
        followPresence = Mitakuuluu.load("settings/followPresence", false)
        showSeconds = Mitakuuluu.load("settings/showSeconds", true)
        showMyJid = Mitakuuluu.load("settings/showMyJid", false)
        showKeyboard = Mitakuuluu.load("settings/showKeyboard", false)
        acceptUnknown = Mitakuuluu.load("settings/acceptUnknown", true)
        notifyActive = Mitakuuluu.load("settings/notifyActive", true)
        resizeImages = Mitakuuluu.load("settings/resizeImages", false);
        resizeBySize = Mitakuuluu.load("settings/resizeBySize", true)
        resizeImagesTo = Mitakuuluu.load("settings/resizeImagesTo", parseInt(1048546))
        resizeImagesToMPix = Mitakuuluu.load("settings/resizeImagesToMPix", parseFloat(5.01))
        conversationTheme = Mitakuuluu.load("settings/conversationTheme", "/usr/share/harbour-mitakuuluu2/qml/DefaultDelegate.qml")
        alwaysOffline = Mitakuuluu.load("settings/alwaysOffline", false)
        deleteMediaFiles = Mitakuuluu.load("settings/deleteMediaFiles", false)
        importToGallery = Mitakuuluu.load("settings/importmediatogallery", true)
        showConnectionNotifications = Mitakuuluu.load("settings/showConnectionNotifications", false)
        lockPortrait = Mitakuuluu.load("settings/lockPortrait", false)
        connectionServer = Mitakuuluu.load("connection/server", "c3.whatsapp.net")
        threading = Mitakuuluu.load("connection/threading", true)
        hideKeyboard = Mitakuuluu.load("settings/hideKeyboard", false)
        notifyMessages = Mitakuuluu.load("settings/notifyMessages", false)
        keepLogs = Mitakuuluu.load("settings/keepLogs", false)
        mapSource = Mitakuuluu.load("settings/mapSource", "here")
        notificationsMuted = Mitakuuluu.load("settings/notificationsMuted", false)
        coverLeftAction = Mitakuuluu.load("settings/coverLeftAction", 4)
        coverRightAction = Mitakuuluu.load("settings/coverRightAction", 3)
        automaticDownload = Mitakuuluu.load("settings/autodownload", false)
        automaticDownloadBytes = Mitakuuluu.load("settings/automaticdownload", 524288)
        sentLeft = Mitakuuluu.load("settings/sentLeft", false)
        systemNotifications = Mitakuuluu.load("settings/systemNotifications", true)

        updateCoverActions()
    }

    Popup {
        id: banner
    }

    HapticsEffect {
        id: vibration
        intensity: 1.0
        duration: 200
        attackTime: 250
        fadeTime: 250
        attackIntensity: 0.0
        fadeIntensity: 0.0
    }
}

