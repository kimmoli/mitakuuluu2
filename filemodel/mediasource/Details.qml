import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: detailsPage
    property variant modelItem

    onStatusChanged: {
        if (status == PageStatus.Activating) {
            nameItem.value = modelItem.path
            sizeItem.value = Format.formatFileSize(modelItem.size)
            widthItem.value = modelItem.width
            heightItem.value = modelItem.height
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        PageHeader {
            //% "Details"
            title: qsTrId("gallery-he-details")
        }
        DetailsItem {
            id: nameItem
            //% "Filename"
            detail: qsTrId("gallery-la-filename")
        }
        DetailsItem {
            id: sizeItem
            //% "Size"
            detail: qsTrId("gallery-la-size")
        }
        DetailsItem {
            id: widthItem
            //% "Width"
            detail: qsTrId("gallery-la-width")
        }
        DetailsItem {
            id: heightItem
            //% "Height"
            detail: qsTrId("gallery-la-height")
        }
    }
}
