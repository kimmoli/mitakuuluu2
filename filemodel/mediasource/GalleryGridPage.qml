import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import Sailfish.Silica.theme 1.0
import com.jolla.gallery 1.0
import QtDocGallery 5.0

MediaSourcePage {
    id: gridPage

    property string albumIdentifier
    property variant model
    property string title
    allowedOrientations: window.allowedOrientations

    property int _animationDuration: 150

    function removeItem() {
        grid.expandItem.remove()
    }

    ImageGridView {
        id: grid
        property alias contextMenu: contextMenuItem
        property Item expandItem
        property int expandIndex: -1
        property real expandHeight: contextMenu.height
        property int minOffsetIndex: expandItem != null
                                     ? expandItem.modelIndex + columnCount - (expandItem.modelIndex % columnCount)
                                     : 0

        anchors.fill: parent
        model: gridPage.model
        unfocusHighlightEnabled: true
        forceUnfocusHighlight: expandHeight > 0

        header: PageHeader { title: gridPage.title }

        delegate: GalleryImage {
            id: img
            source: path
            size: grid.cellSize

            property bool isItemExpanded: grid.expandItem === img
            property int modelIndex: index

            width: grid.cellSize
            height: isItemExpanded ? grid.contextMenu.height + grid.cellSize : grid.cellSize
            contentYOffset: index >= grid.minOffsetIndex ? grid.expandHeight : 0.0
            z: isItemExpanded ? 1000 : 1
            enabled: isItemExpanded || !grid.contextMenu.active

            GridView.onAdd: AddAnimation { target: img; duration: _animationDuration }
            GridView.onRemove: SequentialAnimation {
                PropertyAction { target: img; property: "GridView.delayRemove"; value: true }
                NumberAnimation { target: img; properties: "opacity,scale"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                PropertyAction { target: img; property: "GridView.delayRemove"; value: false }
            }
            onClicked: {
                grid.expandItem = img
                grid.expandIndex = index
                pageStack.push(Qt.resolvedUrl("FullscreenImageView.qml"), {
                                   currentIndex: index,
                                   model: gridPage.model
                   })
                pageStack.currentPage.removeItem.connect(gridPage.removeItem)
            }

            onPressAndHold: {
                grid.expandItem = img
                grid.expandIndex = index
                grid.contextMenu.show(img)
            }
            function remove() {                
                var remorse = removalComponent.createObject(null)
                remorse.z = img.z + 1
                remorse.wrapMode = Text.Wrap
                remorse.horizontalAlignment = Text.AlignHCenter

                remorse.execute(remorseContainerComponent.createObject(img),
                                qsTrId("gallery-la-deleting"),
                                function() {
                                    gridPage.model.remove(grid.expandIndex)
                                })
            }
        }

        ContextMenu {
            id: contextMenuItem
            x: parent !== null ? -parent.x : 0.0

            MenuItem {
                objectName: "deleteItem"
                //% "Delete"
                text: qsTrId("gallery-me-delete")
                onClicked: gridPage.removeItem()
            }
        }
    }

    Component {
        id: remorseContainerComponent
        Item {
            y: parent.contentYOffset
            width: parent.width
            height: parent.height
        }
    }

    Component {
        id: removalComponent
        RemorseItem {
            //: RemorseItem cancel help text
            //% "Cancel"
            cancelText: qsTrId("gallery-la-cancel-deletion")
        }
    }
}
