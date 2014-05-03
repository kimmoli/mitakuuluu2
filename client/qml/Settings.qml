import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import harbour.mitakuuluu2.client 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "settings"
    property variant coverNames: []

    onStatusChanged: {
        if (status === PageStatus.Inactive) {

        }
        else if (status === PageStatus.Active) {
            updatePresence()
        }
    }

    function coverActionName(index) {
        if (typeof(coverNames[index]) == "undefined") {
            coverNames = [
                        qsTr("Quit", "Settings cover action name text"),
                        qsTr("Change presence", "Settings cover action name text"),
                        qsTr("Mute/unmute", "Settings cover action name text"),
                        qsTr("Take picture", "Settings cover action name text"),
                        qsTr("Send location", "Settings cover action name text"),
                        qsTr("Send voice note", "Settings cover action name text"),
                        qsTr("Send text", "Settings cover action name text")
                    ]
        }
        return coverNames[index]
    }

    Connections {
        target: appWindow
        onFollowPresenceChanged: updatePresence()
        onAlwaysOfflineChanged: updatePresence()
        onConnectionServerChanged: {
            connServer.currentIndex = (connectionServer == "c.whatsapp.net" ? 0
                                     :(connectionServer == "c2.whatsapp.net" ? 1
                                                                              : 2))
        }
    }

    function updatePresence() {
        presenceStatus.currentIndex = followPresence ? 0 : (alwaysOffline ? 2 : 1)
    }

    SilicaFlickable {
        id: flick
        anchors.fill: page

        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: qsTr("About", "Settings page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("About.qml"))
                }
            }
            MenuItem {
                text: qsTr("Send logfile to author", "Settings page menu item")
                visible: keepLogs && Mitakuuluu.checkLogfile()
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SendLogs.qml"))
                }
            }
            MenuItem {
                text: qsTr("Account", "Settings page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Account.qml"))
                }
            }
            MenuItem {
                text: qsTr("Traffic counter", "Settings page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("TrafficCounters.qml"))
                }
            }
            MenuItem {
                text: qsTr("Blacklist", "Settings page menu item")
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PrivacyList.qml"))
                }
            }
        }

        Column {
            id: content
            spacing: Theme.paddingSmall
            width: parent.width

            PageHeader {
                id: title
                title: qsTr("Settings", "Settings page title")
            }

            SectionHeader {
                text: qsTr("Conversation", "Settings page section name")
            }

            /*ComboBox {
                label: qsTr("Conversation theme")
                currentIndex: 0
                menu: ContextMenu {
                    MenuItem {
                        text: "Oldschool"
                    }
                    MenuItem {
                        text: "Bubbles"
                    }
                    MenuItem {
                        text: "Modern"
                    }
                    Repeater {
                        width: parent.width
                        model: conversationDelegates
                        delegate: MenuItem {
                            text: modelData
                        }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName !== "roster") {
                        if (currentIndex == 0) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu2/qml/DefaultDelegate.qml"
                        }
                        else if (currentIndex == 1) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu2/qml/BubbleDelegate.qml"
                        }
                        else if (currentIndex == 2) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu2/qml/ModernDelegate.qml"
                        }
                        else {
                            conversationTheme = "/home/nemo/.whatsapp/delegates/" + conversationDelegates[currentIndex - 3]
                        }
                        conversationIndex = parseInt(currentIndex)
                    }
                }
                Component.onCompleted: {
                    currentIndex = settings.value("conversationIndex", parseInt(0))
                }
            }*/

            TextSwitch {
                checked: sentLeft
                text: qsTr("Show sent messages at left side", "Settings option name")
                onClicked: sentLeft = checked
            }

            TextSwitch {
                checked: notifyActive
                text: qsTr("Vibrate in active conversation", "Settings option name")
                onClicked: notifyActive = checked
            }

            TextSwitch {
                id: timestamp
                checked: showTimestamp
                text: qsTr("Show messages timestamp", "Settings option name")
                onClicked: showTimestamp = checked
            }

            TextSwitch {
                id: seconds
                checked: showSeconds
                text: qsTr("Show seconds in messages timestamp", "Settings option name")
                enabled: showTimestamp
                onClicked: showSeconds = checked
            }

            TextSwitch {
                id: enter
                checked: sendByEnter
                text: qsTr("Send messages by Enter", "Settings option name")
                onClicked: sendByEnter = checked
            }

            TextSwitch {
                checked: showKeyboard
                text: qsTr("Automatically show keyboard when opening conversation", "Settings option name")
                onClicked: showKeyboard = checked
            }

            TextSwitch {
                checked: hideKeyboard
                text: qsTr("Hide keyboard after sending message", "Settings option name")
                onClicked: hideKeyboard = checked
            }

            /*TextSwitch {
                checked: deleteMediaFiles
                text: qsTr("Delete media files")
                description: qsTr("Delete received media files when deleting message")
                onClicked: deleteMediaFiles = checked
            }*/

            ComboBox {
                label: qsTr("Map source", "Settings option name")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: mapSourceModel
                        delegate: MenuItem { text: model.name }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        mapSource = mapSourceModel.get(currentIndex).value
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < mapSourceModel.count; i++) {
                        if (mapSourceModel.get(i).value == mapSource) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            TextSwitch {
                checked: lockPortrait
                text: qsTr("Lock conversation orientation in portrait", "Settings option name")
                onClicked: lockPortrait = checked
            }

            ListModel {
                id: mapSourceModel
                Component.onCompleted: {
                    append({name: qsTr("Here", "Map source selection"), value: "here"})
                    append({name: qsTr("Nokia", "Map source selection"), value: "nokia"})
                    append({name: qsTr("Google", "Map source selection"), value: "google"})
                    append({name: qsTr("OpenStreetMaps", "Map source selection"), value: "osm"})
                    append({name: qsTr("Bing", "Map source selection"), value: "bing"})
                    append({name: qsTr("MapQuest", "Map source selection"), value: "mapquest"})
                    append({name: qsTr("Yandex", "Map source selection"), value: "yandex"})
                    append({name: qsTr("Yandex usermap", "Map source selection"), value: "yandexuser"})
                    append({name: qsTr("2Gis", "Map source selection"), value: "2gis"})
                }
            }

            Slider {
                id: fontSlider
                width: parent.width
                maximumValue: 60
                minimumValue: 8
                label: qsTr("Chat font size", "Settings option name")
                value: fontSize
                valueText: qsTr("%1 px", "Settings option value label").arg(parseInt(value))
                onReleased: {
                    fontSize = parseInt(value)
                }
            }

            SectionHeader {
                text: qsTr("Notifications", "Settings page section name")
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Use system Chat notifier", "Settings option name")
                checked: systemNotifier
                onClicked: systemNotifier = checked
            }

            ValueButton {
                label: qsTr("Private message", "Settings page Private message tone selection")
                enabled: !systemNotifier
                value: Mitakuuluu.privateToneEnabled ? metadataReader.getTitle(Mitakuuluu.privateTone) : qsTr("no sound", "Private message tone not set")
                onClicked: {
                    var dialog = pageStack.push(dialogComponent, {
                        activeFilename: Mitakuuluu.privateTone,
                        activeSoundTitle: value,
                        activeSoundSubtitle: qsTr("Private message tone", "Sound chooser description text"),
                        noSound: !Mitakuuluu.privateToneEnabled
                        })

                    dialog.accepted.connect(
                       function() {
                            console.log("path: " + dialog.selectedFilename)
                            console.log("enabled: " + !dialog.noSound)
                            Mitakuuluu.privateToneEnabled = !dialog.noSound
                            if (!dialog.noSound) {
                                Mitakuuluu.privateTone = dialog.selectedFilename
                            }
                        })
                }
            }

            ComboBox {
                label: qsTr("Private message color", "Settings page Private message color selection")
                enabled: !systemNotifier
                menu: ContextMenu {
                    id: privatePatterns
                    Repeater {
                        id: privateItems
                        width: parent.width
                        model: patternsModel
                        delegate: MenuItem { text: model.color }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        console.log("private pattern: " + patternsModel.get(currentIndex).name)
                        Mitakuuluu.privateLedColor = patternsModel.get(currentIndex).name
                        console.log("success: " + Mitakuuluu.privateLedColor)
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < patternsModel.count; i++) {
                        if (patternsModel.get(i).name == Mitakuuluu.privateLedColor) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            ValueButton {
                label: qsTr("Group message", "Settings page Group message tone selection")
                enabled: !systemNotifier
                value: Mitakuuluu.groupToneEnabled ? metadataReader.getTitle(Mitakuuluu.groupTone) : qsTr("no sound", "Group message tone not set")
                onClicked: {
                    var dialog = pageStack.push(dialogComponent, {
                        activeFilename: Mitakuuluu.groupTone,
                        activeSoundTitle: value,
                        activeSoundSubtitle: qsTr("Group message tone", "Sound chooser description text"),
                        noSound: !Mitakuuluu.groupToneEnabled
                        })

                    dialog.accepted.connect(
                        function() {
                            Mitakuuluu.groupToneEnabled = !dialog.noSound
                            if (!dialog.noSound) {
                                Mitakuuluu.groupTone = dialog.selectedFilename
                            }
                        })
                }
            }

            ComboBox {
                label: qsTr("Group message color", "Settings page Group message color selection")
                enabled: !systemNotifier
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: patternsModel
                        delegate: MenuItem { text: model.color }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        console.log("group pattern: " + patternsModel.get(currentIndex).name)
                        Mitakuuluu.groupLedColor = patternsModel.get(currentIndex).name
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < patternsModel.count; i++) {
                        if (patternsModel.get(i).name == Mitakuuluu.groupLedColor) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            ValueButton {
                label: qsTr("Media message", "Settings page Media message tone selection")
                enabled: !systemNotifier
                value: Mitakuuluu.mediaToneEnabled ? metadataReader.getTitle(Mitakuuluu.mediaTone) : qsTr("no sound", "Medi message tone not set")
                onClicked: {
                    var dialog = pageStack.push(dialogComponent, {
                        activeFilename: Mitakuuluu.mediaTone,
                        activeSoundTitle: value,
                        activeSoundSubtitle: qsTr("Media message tone", "Sound chooser description text"),
                        noSound: !Mitakuuluu.mediaToneEnabled
                        })

                    dialog.accepted.connect(
                        function() {
                            Mitakuuluu.mediaToneEnabled = !dialog.noSound
                            if (!dialog.noSound) {
                                Mitakuuluu.mediaTone = dialog.selectedFilename
                            }
                        })
                }
            }

            ComboBox {
                label: qsTr("Media message color", "Settings page Media message color selection")
                enabled: !systemNotifier
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: patternsModel
                        delegate: MenuItem { text: model.color }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        console.log("media pattern: " + patternsModel.get(currentIndex).name)
                        Mitakuuluu.mediaLedColor = patternsModel.get(currentIndex).name
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < patternsModel.count; i++) {
                        if (patternsModel.get(i).name == Mitakuuluu.mediaLedColor) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            TextSwitch {
                checked: showConnectionNotifications
                text: qsTr("Show notifications when connection changing", "Settings option name")
                onClicked: showConnectionNotifications = checked
            }

            Binding {
                target: muteSwitch
                property: "checked"
                value: !notificationsMuted
            }

            TextSwitch {
                id: muteSwitch
                checked: !notificationsMuted
                text: qsTr("Show new messages notifications", "Settings option name")
                onClicked: notificationsMuted = !checked
            }

            Binding {
                target: notifySwitch
                property: "checked"
                value: notifyMessages
            }

            TextSwitch {
                id: notifySwitch
                checked: notifyMessages
                enabled: !notificationsMuted
                text: qsTr("Display messages text in notifications", "Settings option name")
                onClicked: notifyMessages = checked
            }

            SectionHeader {
                text: qsTr("Common", "Settings page section name")
            }

            ComboBox {
                label: qsTr("Language")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: Mitakuuluu.getLocalesNames()
                        delegate: MenuItem {
                            text: modelData
                        }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        Mitakuuluu.setLocale(currentIndex)
                        banner.notify(qsTr("Restart application to change language", "Language changing banner text"))
                    }
                }
                Component.onCompleted: {
                    //console.log("default: " + localeNames[localeIndex] + " locale: " + locales[localeIndex] + " index: " + localeIndex)
                    currentIndex = Mitakuuluu.getCurrentLocaleIndex()
                }
            }

            ComboBox {
                id: connServer
                label: qsTr("Connection server", "Settings option name") + " (*)"
                menu: ContextMenu {
                    MenuItem {
                        text: "c.whatsapp.net"
                        onClicked: {
                            connectionServer = "c.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c1.whatsapp.net"
                        onClicked: {
                            connectionServer = "c1.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c2.whatsapp.net"
                        onClicked: {
                            connectionServer = "c2.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c3.whatsapp.net"
                        onClicked: {
                            connectionServer = "c3.whatsapp.net"
                        }
                    }
                }
                Component.onCompleted: {
                    currentIndex = (connectionServer == "c.whatsapp.net" ? 0
                                : (connectionServer == "c1.whatsapp.net" ? 1
                                : (connectionServer == "c2.whatsapp.net" ? 2
                                                                         : 3)))
                }
            }

            TextSwitch {
                id: autostart
                checked: Mitakuuluu.checkAutostart()
                text: qsTr("Autostart", "Settings option name")
                onClicked: {
                    Mitakuuluu.setAutostart(checked)
                }
            }

            TextSwitch {
                checked: keepLogs
                text: qsTr("Allow saving application logs", "Settings option name")
                onClicked: {
                    keepLogs = checked
                    if (checked) {
                        banner.notify(qsTr("You need to full quit application to start writing logs. Send logfile to author appear in settings menu.", "Allow application logs option description"))
                    }
                }
            }

            TextSwitch {
                checked: importToGallery
                text: qsTr("Download media to Gallery", "Settings option name")
                description: qsTr("If checked downloaded files will be shown in Gallery", "Settings option description")
                onClicked: importToGallery = checked
            }

            TextSwitch {
                id: showMyself
                checked: showMyJid
                text: qsTr("Show yourself in contact list, if present", "Settings option name")
                onClicked: showMyJid = checked
            }

            TextSwitch {
                checked: acceptUnknown
                text: qsTr("Accept messages from unknown contacts", "Settings option name")
                onClicked: acceptUnknown = checked
            }

            SectionHeader {
                text: qsTr("Presence", "Settings page section name")
            }

            ComboBox {
                id: presenceStatus
                label: qsTr("Display presence", "Settings option name")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("Display online when app is open", "Settings option value text")
                        onClicked: {
                            followPresence = true
                            alwaysOffline = false
                        }
                    }
                    MenuItem {
                        text: qsTr("Always display online", "Settings option value text")
                        onClicked: {
                            alwaysOffline = false
                            followPresence = false
                        }
                    }
                    MenuItem {
                        text: qsTr("Always display offline", "Settings option value text")
                        onClicked: {
                            alwaysOffline = true
                            followPresence = false
                        }
                    }
                }
                Component.onCompleted: {
                    currentIndex = followPresence ? 0 : (alwaysOffline ? 2 : 1)
                }
            }

            SectionHeader {
                text: qsTr("Cover", "Settings page section name")
            }

            Binding {
                target: leftCoverAction
                property: "currentIndex"
                value: coverLeftAction
            }

            ComboBox {
                id: leftCoverAction
                label: qsTr("Left cover action", "Settings option name")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: 7
                        delegate: MenuItem {
                            text: coverActionName(index)
                            //onClicked: coverLeftAction = index
                        }
                    }
                }
                onCurrentItemChanged: {
                    coverLeftAction = currentIndex
                }
            }

            Binding {
                target: rightCoverAction
                property: "currentIndex"
                value: coverRightAction
            }

            ComboBox {
                id: rightCoverAction
                label: qsTr("Right cover action", "Settings option name")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: 7
                        delegate: MenuItem {
                            text: coverActionName(index)
                            //onClicked: coverRightAction = index
                        }
                    }
                }
                onCurrentItemChanged: {
                    coverRightAction = currentIndex
                }
            }

            SectionHeader {
                text: qsTr("Media", "Settings page section name")
            }

            Item {
                width: parent.width
                height: downloadSlider.height

                TextSwitch {
                    id: autoDownload
                    text: ""
                    width: Theme.itemSizeSmall
                    checked: automaticDownload
                    onClicked: {
                        automaticDownload = checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slider {
                    id: downloadSlider
                    enabled: automaticDownload
                    anchors.left: autoDownload.right
                    anchors.right: parent.right
                    maximumValue: 10485760
                    minimumValue: 204800
                    label: qsTr("Automatic download bytes", "Settings option name")
                    value: automaticDownloadBytes
                    valueText: Format.formatFileSize(parseInt(value))
                    onReleased: {
                        automaticDownloadBytes = parseInt(value)
                    }
                }
            }

            TextSwitch {
                text: qsTr("Auto download on WLAN only", "Settings option name")
                width: parent.width
                checked: autoDownloadWlan
                enabled: automaticDownload
                onClicked: autoDownloadWlan = checked
            }

            TextSwitch {
                checked: resizeImages
                text: qsTr("Resize sending images", "Settings option name")
                onClicked: {
                    resizeImages = checked
                    if (!checked) {
                        sizeResize.checked = false
                        pixResize.checked = false
                    }
                }
            }

            TextSwitch {
                text: qsTr("Resize on WLAN only", "Settings option name")
                width: parent.width
                checked: resizeWlan
                enabled: resizeImages
                onClicked: resizeWlan = checked
            }

            Item {
                width: parent.width
                height: sizeSlider.height

                TextSwitch {
                    id: sizeResize
                    text: ""
                    width: Theme.itemSizeSmall
                    enabled: resizeImages
                    checked: resizeImages && resizeBySize
                    onClicked: {
                        resizeBySize = checked
                        pixResize.checked = !checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }


                Slider {
                    id: sizeSlider
                    enabled: resizeImages && sizeResize.checked
                    anchors.left: sizeResize.right
                    anchors.right: parent.right
                    maximumValue: 5242880
                    minimumValue: 204800
                    label: qsTr("Maximum image size by file size", "Settings option name")
                    value: resizeImagesTo
                    valueText: Format.formatFileSize(parseInt(value))
                    onReleased: {
                        resizeImagesTo = parseInt(value)
                    }
                }
            }

            Item {
                width: parent.width
                height: pixSlider.height

                TextSwitch {
                    id: pixResize
                    text: ""
                    width: Theme.itemSizeSmall
                    enabled: resizeImages
                    checked: resizeImages && !resizeBySize
                    onClicked: {
                        resizeBySize = !checked
                        sizeResize.checked = !checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slider {
                    id: pixSlider
                    enabled: resizeImages && pixResize.checked
                    anchors.left: pixResize.right
                    anchors.right: parent.right
                    maximumValue: 9.0
                    minimumValue: 0.2
                    label: qsTr("Maximum image size by resolution", "Settings option name")
                    value: resizeImagesToMPix
                    valueText: qsTr("%1 MPx", "Settings option value text").arg(parseFloat(value.toPrecision(2)))
                    onReleased: {
                        resizeImagesToMPix = parseFloat(value.toPrecision(2))
                    }
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                wrapMode: Text.Wrap
                text: qsTr("Options marked with (*) will take effect after reconnection", "Settings (*) options description")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: patternsModel
        Component.onCompleted: {
            append({"name": "PatternMitakuuluuRed", "color": qsTr("red", "Pattern led color")})
            append({"name": "PatternMitakuuluuGreen", "color": qsTr("green", "Pattern led color")})
            append({"name": "PatternMitakuuluuBlue", "color": qsTr("blue", "Pattern led color")})
            append({"name": "PatternMitakuuluuWhite", "color": qsTr("white", "Pattern led color")})
            append({"name": "PatternMitakuuluuYellow", "color": qsTr("yellow", "Pattern led color")})
            append({"name": "PatternMitakuuluuCyan", "color": qsTr("cyan", "Pattern led color")})
            append({"name": "PatternMitakuuluuPink", "color": qsTr("pink", "Pattern led color")})
        }
    }

    AlarmToneModel {
        id: alarmToneModel
    }

    MetadataReader {
        id: metadataReader
    }

    Component {
        id: dialogComponent

        SoundDialog {
            alarmModel: alarmToneModel
        }
    }
}
