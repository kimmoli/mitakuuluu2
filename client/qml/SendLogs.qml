import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Email 1.1

EmailComposerPage {
    id: sharePage

    allowedOrientations: Orientation.All
    emailTo: "coderusinbox@gmail.com"
    emailSubject: "Mitakuuluu bug"
    emailBody: "Please enter bug description here. In english. Step-by-step:\n\n1. Started Mitakuuluu at {time}\n2. Did something at {time}\n3. Expected some behaviour\n4. Got wrong result at {time}"

    Component.onCompleted: {
        attachmentsModel.append({"url": 'file:///tmp/mitakuuluu2.log', "title": "mitakuuluu2.log", "mimeType": "text/txt"})
    }
}
