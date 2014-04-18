import QtQuick 2.0
import Sailfish.Silica 1.0
import QtFeedback 5.0
import org.nemomobile.configuration 1.0
import harbour.mitakuuluu2.client 1.0

ApplicationWindow {
    id: appWindow
    objectName: "appWindow"
    cover: Qt.resolvedUrl("CoverPage.qml")
    initialPage: (Settings.value("account/phoneNumber", "unregistered") === "unregistered") ?
                     Qt.resolvedUrl("RegistrationPage.qml") : Qt.resolvedUrl("ChatsPage.qml")

    property bool sendByEnter: false
    onSendByEnterChanged: Settings.setValue("settings/sendByEnter", sendByEnter)

    property bool showTimestamp: true
    onShowTimestampChanged: Settings.setValue("settings/showTimestamp", showTimestamp)

    property int fontSize: 32
    onFontSizeChanged: Settings.setValue("settings/fontSize", fontSize)

    property bool followPresence: false
    onFollowPresenceChanged: {
        Settings.setValue("settings/followPresence", followPresence)
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
    onShowSecondsChanged: Settings.setValue("settings/showSeconds", showSeconds)

    property bool showMyJid: false
    onShowMyJidChanged: Settings.setValue("settings/showMyJid", showMyJid)

    property bool showKeyboard: false
    onShowKeyboardChanged: Settings.setValue("settings/showKeyboard", showKeyboard)

    property bool acceptUnknown: true
    onAcceptUnknownChanged: Settings.setValue("settings/acceptUnknown", acceptUnknown)

    property bool notifyActive: true
    onNotifyActiveChanged: Settings.setValue("settings/notifyActive", notifyActive)

    property bool resizeImages: false
    onResizeImagesChanged: Settings.setValue("settings/resizeImages", resizeImages)

    property bool resizeBySize: true
    onResizeBySizeChanged: Settings.setValue("settings/resizeBySize", resizeBySize)

    property int resizeImagesTo: 1048546
    onResizeImagesToChanged: Settings.setValue("settings/resizeImagesTo", resizeImagesTo)

    property double resizeImagesToMPix: 5.01
    onResizeImagesToMPixChanged: Settings.setValue("settings/resizeImagesToMPix", resizeImagesToMPix)

    property string conversationTheme: "/usr/share/harbour-mitakuuluu2/qml/DefaultDelegate.qml"
    onConversationThemeChanged: Settings.setValue("settings/conversationTheme", conversationTheme)

    property int conversationIndex: 0
    onConversationIndexChanged: Settings.setValue("settings/conversationIndex", conversationIndex)

    property bool alwaysOffline: false
    onAlwaysOfflineChanged: {
        Settings.setValue("settings/alwaysOffline", alwaysOffline)
        if (alwaysOffline)
            Mitakuuluu.setPresenceUnavailable()
        else
            Mitakuuluu.setPresenceAvailable()
        updateCoverActions()
    }
    property bool deleteMediaFiles: false
    onDeleteMediaFilesChanged: Settings.setValue("settings/deleteMediaFiles", deleteMediaFiles)

    property bool importToGallery: true
    onImportToGalleryChanged: Settings.setValue("settings/importToGallery", importToGallery)

    property bool showConnectionNotifications: false
    onShowConnectionNotificationsChanged: Settings.setValue("settings/showConnectionNotifications", showConnectionNotifications)

    property bool lockPortrait: false
    onLockPortraitChanged: Settings.setValue("settings/lockPortrait", lockPortrait)

    property string connectionServer: "c3.whatsapp.net"
    onConnectionServerChanged: Settings.setValue("connection/server", connectionServer)

    property bool notificationsMuted: false
    onNotificationsMutedChanged: {
        Settings.setValue("settings/notificationsMuted", notificationsMuted)
        updateCoverActions()
    }

    property bool threading: true
    onThreadingChanged: Settings.setValue("connection/threading", threading)

    property bool hideKeyboard: false
    onHideKeyboardChanged: Settings.setValue("settings/hideKeyboard", hideKeyboard)

    property bool notifyMessages: false
    onNotifyMessagesChanged: Settings.setValue("settings/notifyMessages", notifyMessages)

    property bool keepLogs: true
    onKeepLogsChanged: Settings.setValue("settings/keepLogs", keepLogs)

    property string mapSource: "here"
    onMapSourceChanged: Settings.setValue("settings/mapSource", mapSource)

    property int automaticDownload: 524288
    onAutomaticDownloadChanged: Settings.setValue("settings/automaticdownload", automaticDownload)

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
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"))
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
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"))
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
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"))
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
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"))
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
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"))
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
        Settings.setValue("settings/coverLeftAction", coverLeftAction)
        updateCoverActions()
    }
    property int coverRightAction: 3
    onCoverRightActionChanged: {
        Settings.setValue("settings/coverRightAction", coverRightAction)
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
    }

    Component.onCompleted: {
        sendByEnter = Settings.value("settings/sendByEnter", false)
        showTimestamp = Settings.value("settings/showTimestamp", true)
        fontSize = Settings.value("settings/fontSize", 32)
        followPresence = Settings.value("settings/followPresence", false)
        showSeconds = Settings.value("settings/showSeconds", true)
        showMyJid = Settings.value("settings/showMyJid", false)
        showKeyboard = Settings.value("settings/showKeyboard", false)
        acceptUnknown = Settings.value("settings/acceptUnknown", true)
        notifyActive = Settings.value("settings/notifyActive", true)
        resizeImages = Settings.value("settings/resizeImages", false);
        resizeBySize = Settings.value("settings/resizeBySize", true)
        resizeImagesTo = Settings.value("settings/resizeImagesTo", parseInt(1048546))
        resizeImagesToMPix = Settings.value("settings/resizeImagesToMPix", parseFloat(5.01))
        conversationTheme = Settings.value("settings/conversationTheme", "/usr/share/harbour-mitakuuluu2/qml/DefaultDelegate.qml")
        alwaysOffline = Settings.value("settings/alwaysOffline", false)
        deleteMediaFiles = Settings.value("settings/deleteMediaFiles", false)
        importToGallery = Settings.value("settings/importmediatogallery", true)
        showConnectionNotifications = Settings.value("settings/showConnectionNotifications", false)
        lockPortrait = Settings.value("settings/lockPortrait", false)
        connectionServer = Settings.value("connection/server", "c3.whatsapp.net")
        threading = Settings.value("connection/threading", true)
        hideKeyboard = Settings.value("settings/hideKeyboard", false)
        notifyMessages = Settings.value("settings/notifyMessages", false)
        keepLogs = Settings.value("settings/keepLogs", true)
        mapSource = Settings.value("settings/mapSource", "here")
        notificationsMuted = Settings.value("settings/notificationsMuted", false)
        coverLeftAction = Settings.value("settings/coverLeftAction", 4)
        coverRightAction = Settings.value("settings/coverRightAction", 3)
        automaticDownload = Settings.value("settings/automaticdownload", 524288)

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

