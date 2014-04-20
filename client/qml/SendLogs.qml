import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Email 1.1

EmailComposerPage {
    id: sharePage

    allowedOrientations: Orientation.All
    emailTo: "coderusinbox@gmail.com"
    emailSubject: "Mitakuuluu bug"
    emailBody: qsTr("Please enter bug description here.\n\n1. Started Mitakuuluu\n2. Did something\n3. Expected some behaviour\n4. Get wrong result", "Logs sending page email body")

    Component.onCompleted: {
        attachmentsModel.append({"url": 'file:///tmp/mitakuuluu2.log', "title": "mitakuuluu2.log", "mimeType": "text/txt"})
    }
}
