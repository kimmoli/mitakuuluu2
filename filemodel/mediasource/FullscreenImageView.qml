import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Ambience 1.0
import Sailfish.Gallery 1.0
import Sailfish.TransferEngine 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.signonuiservice 1.0

SplitViewPage {
    id: fullscreenPage

    property variant model
    property int currentIndex: -1
    property string name
    property string path

    signal removeItem

    allowedOrientations: window.allowedOrientations

    Component.onCompleted: slideshowView.positionViewAtIndex(currentIndex, PathView.Center)


    SailfishTransferMethodsModel {
        id: transferMethodsModel
        filter: fullscreenPage.model.get(fullscreenPage.currentIndex).mime
    }

    background: ShareMethodList {
        id: menuList

        objectName: "menuList"
        model: transferMethodsModel
        source: fullscreenPage.model.get(fullscreenPage.currentIndex).path
        anchors.fill: parent

        //% "Share"
        listHeader: qsTrId("gallery-la-share")

        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                Component {
                    id: detailsComponent
                    Details {}
                }

                //% "Details"
                text: qsTrId("gallery-me-details")
                onClicked: window.pageStack.push(detailsComponent, {"modelItem": fullscreenPage.model.get(fullscreenPage.currentIndex)} )
            }

            MenuItem {
                //% "Delete"
                text: qsTrId("gallery-me-delete")
                onClicked: {
                    fullscreenPage.removeItem()
                    pageStack.pop()
                }
            }

            MenuItem {
                //% "Create ambience"
                text: qsTrId("gallery-me-create_ambience")

                onClicked: Ambience.source = model.get(currentIndex).path
            }
        }

        header: Item {
            height: Theme.itemSizeLarge
            width: menuList.width * 0.7 - Theme.paddingLarge
            x: menuList.width * 0.3

            Label {
                text: model.get(currentIndex).name
                width: parent.width
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                anchors.verticalCenter: parent.verticalCenter
                objectName: "imageTitle"
                horizontalAlignment: Text.AlignRight
                font {
                    pixelSize: Theme.fontSizeLarge
                    family: Theme.fontFamilyHeading
                }
            }
        }

        // Add "add account" to the footer. User must be able to
        // create accounts in a case there are none.
        footer: BackgroundItem {
            Label {
                //% "Add account"
                text: qsTrId("gallery-la-add_account")
                x: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            onClicked: {
                jolla_signon_ui_service.inProcessParent = fullscreenPage
                accountCreator.startAccountCreation()
            }
        }

        SignonUiService {
            id: jolla_signon_ui_service
            inProcessServiceName: "com.jolla.gallery"
            inProcessObjectPath: "/JollaGallerySignonUi"
        }

        AccountCreationManager {
            id: accountCreator
            serviceFilter: ["sharing"]
            endDestination: fullscreenPage
            endDestinationAction: PageStackAction.Pop
        }
    }

    SlideshowView {
        id: slideshowView

        model: fullscreenPage.model
        currentIndex: fullscreenPage.currentIndex
        onCurrentIndexChanged: fullscreenPage.currentIndex = currentIndex
        interactive: !itemScaled && count > 1
        property bool itemScaled: currentItem !== null && currentItem.itemScaled
        property Item _activeItem

        Component.onCompleted: {
            if (!slideshowView._activeItem && currentItem) {
                slideshowView._activeItem = currentItem
                slideshowView._activeItem.active = true
            }
        }

        onCurrentItemChanged: {
            if (!moving && currentItem) {
                if (slideshowView._activeItem) {
                    slideshowView._activeItem.active = false
                }

                slideshowView._activeItem = currentItem
                slideshowView._activeItem.active = true
            }
        }

        onMovingChanged: {
            if (!moving && slideshowView._activeItem != currentItem) {
                if (slideshowView._activeItem) {
                    slideshowView._activeItem.active = false
                }
                slideshowView._activeItem = currentItem
                if (slideshowView._activeItem) {
                    slideshowView._activeItem.active = true
                }
            }
        }

        delegate: Item {
            id: mediaItem

            readonly property bool itemScaled: imageViewer.scaled != undefined && imageViewer.scaled
            property bool active

            width: fullscreenPage.isPortrait ? Screen.width : Screen.height
            height: fullscreenPage.height

            visible: fullscreenPage.moving || active

            opacity: Math.abs(x) <= fullscreenPage.width ? 1.0 -  (Math.abs(x) / fullscreenPage.width) : 0

            ImageViewer {
                id: imageViewer
                width: mediaItem.width
                height: mediaItem.height
                source: model.path
                fit: fullscreenPage.isPortrait ? Fit.Width : Fit.Height
                //orientation: model.orientation
                enableZoom: !fullscreenPage.moving

                active: mediaItem.active
                maximumWidth: model.width
                maximumHeight: model.height

                onClicked: fullscreenPage.open = !fullscreenPage.open
            }
        }
    }
}
 
