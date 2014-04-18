import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Page {
    id: page
    objectName: "mutingSelector"

    property string jid

    SilicaListView {
        id: flick
        anchors.fill: parent
        model: listModel
        delegate: listDelegate
        header: PageHeader { title: qsTr("Muting", "Contacts muting page title") }

        VerticalScrollDecorator {}
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
            width: parent.width
            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: model.name
                elide: Text.ElideRight
                truncationMode: TruncationMode.Fade
            }
            onClicked: {
                Settings.setValue("muting/" + jid, new Date().getTime() + model.value)
                pageStack.pop()
            }
        }
    }

    ListModel {
        id: listModel
        Component.onCompleted: {
            append({"name": qsTr("Disabled", "Comtacts muting duration text"), "value": 0})
            append({"name": qsTr("5 minutes", "Comtacts muting duration text"), "value": 300000})
            append({"name": qsTr("10 minutes", "Comtacts muting duration text"), "value": 600000})
            append({"name": qsTr("20 minutes", "Comtacts muting duration text"), "value": 1200000})
            append({"name": qsTr("30 minutes", "Comtacts muting duration text"), "value": 1800000})
            append({"name": qsTr("60 minutes", "Comtacts muting duration text"), "value": 3600000})
            append({"name": qsTr("2 hours", "Comtacts muting duration text"), "value": 7200000})
            append({"name": qsTr("6 hours", "Comtacts muting duration text"), "value": 21600000})
            append({"name": qsTr("12 hours", "Comtacts muting duration text"), "value": 43200000})
            append({"name": qsTr("24 hours", "Comtacts muting duration text"), "value": 86400000})
        }
    }
}
