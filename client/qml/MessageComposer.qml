import QtQuick 2.1
import Sailfish.Silica 1.0

Dialog {
    id: page
    objectName: "messageComposer"

    property string message

    canAccept: textArea.text.trim().length > 0

    onAccepted: {
        page.message = textArea.text.trim()
    }

    onStatusChanged: {
        if (page.status == DialogStatus.Opened) {
            textArea.forceActiveFocus()
        }
    }

    DialogHeader {
        id: header
        title: qsTr("Broadcast message", "Broadcast text page title")
    }

    TextArea {
        id: textArea
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }
}
