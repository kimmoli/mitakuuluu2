import QtQuick 2.0
import Sailfish.Silica 1.0

ImageBase {
    id: base

    Image {
        id: thumbnail

        source: parent.source
        width:  base.size
        height: base.size
        //sourceSize.width: base.size
        //sourceSize.height: base.size
        y: contentYOffset
        x: contentXOffset

        cache: true
        asynchronous: true
        smooth: true
        fillMode: Image.PreserveAspectCrop
        clip: true

        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter

        onStatusChanged: {
            if (status == Image.Error) {
                errorLabelComponent.createObject(thumbnail)
            }
            else if (status == Image.Ready) {
                if (sourceSize.width > sourceSize.height)
                    sourceSize.height = base.size
                else
                    sourceSize.width = base.size
            }
        }
    }

    Component {
        id: errorLabelComponent
        Label {
            //: Thumbnail Image loading failed
            //% "Oops, can't display the thumbnail!"
            text: qsTrId("components_gallery-la-image-thumbnail-loading-failed")
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.paddingMedium
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
