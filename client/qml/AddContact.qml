import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Dialog {
    id: addContact
    property string jid
    function showData(ojid, oname) {
        jid = ojid
        nameField.text = oname
        addContact.open()
    }
    canAccept: (phoneField.text.trim().length > 0) && (aliasField.text.trim().length > 0)

    onDone: {
        phoneField.focus = false
        aliasField.focus = false
        roster.forceActiveFocus()
    }

    onAccepted: {
        aliasField.deselect()
        phoneField.deselect()
        Mitakuuluu.addPhoneNumber(aliasField.text.trim(), phoneField.text.trim())
    }

    onStatusChanged: {
        if (status == DialogStatus.Opened) {
            phoneField.text = ""
            aliasField.text = ""
            phoneField.forceActiveFocus()
        }
    }

    DialogHeader {
        title: qsTr("Add contact")
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - (Theme.paddingLarge * 2)
        spacing: Theme.paddingSmall

        Item {
            width: parent.width
            height: phoneField.height

            TextField {
                id: phoneField
                width: parent.width
                inputMethodHints: Qt.ImhDialableCharactersOnly
                placeholderText: qsTr("1234567890")
                validator: RegExpValidator{ regExp: /[0-9]*/;}
                EnterKey.enabled: acceptableInput && (text.trim().length > 0)
                EnterKey.highlighted: acceptableInput && (text.trim().length > 0)
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: {
                    if (aliasField.text.length == 0)
                        aliasField.forceActiveFocus()
                    else
                        phoneField.focus = false
                }
            }

        }

        TextField {
            id: aliasField
            width: parent.width
            placeholderText: qsTr("Enter contact name here")
            EnterKey.enabled: true//addContact.canAccept
            EnterKey.highlighted: text.length > 0 //addContact.canAccept
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: {
                aliasField.focus = false
            }
        }
    }
}
