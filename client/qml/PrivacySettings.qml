import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Page {
    id: page
    objectName: "privacySettings"

    onStatusChanged: {
        if (status == PageStatus.Active) {
            Mitakuuluu.getPrivacySettings()
        }
    }

    ScrollDecorator {}

    Connections {
        target: Mitakuuluu
        onPrivacySettings: {
            if (values) {
                lastPrivacy.currentIndex = privacyValueToIndex(values.last)
                statusPrivacy.currentIndex = privacyValueToIndex(values.status)
                photoPrivacy.currentIndex = privacyValueToIndex(values.profile)
            }
        }
    }

    function privacyValueToIndex(value) {
        if (value == "all")
            return 0
        else if (value == "contacts")
            return 1
        return 2
    }

    function privacyIndexToValue(index) {
        switch (index) {
        case 0: return "all"
        case 1: return "contacts"
        default: return "none"
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Privacy") }

            ComboBox {
                id: lastPrivacy
                width: parent.width
                label: qsTr("Last seen")
                currentIndex: 0
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: privacyModel
                        delegate: privacyDelegate
                    }
                }
                onCurrentIndexChanged: {
                    if (page.status == PageStatus.Active) {
                        console.log("last seen privacy: " + privacyIndexToValue(currentIndex))
                        Mitakuuluu.setPrivacySettings("last", p-rivacyIndexToValue(currentIndex))
                    }
                }
            }

            ComboBox {
                id: statusPrivacy
                width: parent.width
                label: qsTr("Status")
                currentIndex: 0
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: privacyModel
                        delegate: privacyDelegate
                    }
                }
                onCurrentIndexChanged: {
                    if (page.status == PageStatus.Active) {
                        console.log("status privacy: " + privacyIndexToValue(currentIndex))
                        Mitakuuluu.setPrivacySettings("status", privacyIndexToValue(currentIndex))
                    }
                }
            }

            ComboBox {
                id: photoPrivacy
                width: parent.width
                label: qsTr("Profile photo")
                currentIndex: 0
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: privacyModel
                        delegate: privacyDelegate
                    }
                }
                onCurrentIndexChanged: {
                    if (page.status == PageStatus.Active) {
                        console.log("profile photo privacy: " + privacyIndexToValue(currentIndex))
                        Mitakuuluu.setPrivacySettings("profile", privacyIndexToValue(currentIndex))
                    }
                }
            }
        }
    }

    Component {
        id: privacyDelegate
        MenuItem {
            text: model.name
        }
    }

    ListModel {
        id: privacyModel
        Component.onCompleted: {
            append({ name: qsTr("Everybody")})
            append({ name: qsTr("Contacts")})
            append({ name: qsTr("Nobody")})
        }
    }
}
