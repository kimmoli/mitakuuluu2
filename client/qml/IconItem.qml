import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root

    property alias name: label.text
    property url iconSource

    implicitHeight: Theme.itemSizeSmall

    Row {
        id: row
        x: Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.paddingMedium

        Image {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            source: (root.highlighted && root.iconSource != "")
                    ? root.iconSource + "?" + Theme.highlightColor
                    : root.iconSource
        }
        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
} 
