import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import harbour.mitakuuluu2.client 1.0

Dialog {
    id: page
    objectName: "selectPhonebook"

    property variant numbers: []
    property variant names: []
    property variant avatars: []

    signal finished

    property PeopleModel allContactsModel: PeopleModel {
        filterType: PeopleModel.FilterAll
        requiredProperty: PeopleModel.PhoneNumberRequired
    }

    onStatusChanged: {
        if (status == DialogStatus.Closed) {
            page.finished()
            numbers = []
            names = []
            avatars = []
        }
        else if (status == DialogStatus.Opening) {
            allContactsModel.search("")
        }
        else if (status == DialogStatus.Opened) {
            fastScroll.init()
        }
    }

    canAccept: numbers.length > 0

    onAccepted: {
        Mitakuuluu.syncContacts(numbers, names, avatars)
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        clip: true
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Sync all phonebook", "Add contacts page menu item")
                onClicked: {
                    Mitakuuluu.syncAllPhonebook()
                    page.reject()
                }
            }

            MenuItem {
                text: qsTr("Add number", "Add contacts page menu item")
                onClicked: {
                    addContact.open(true, false)
                }
            }

            /*MenuItem {
                text: (page.numbers.length > 0) ? "Deselect all" : "Select all"
                    onClicked: {
                    if (page.numbers.length > 0) {
                        page.numbers = []
                        page.names = []
                        page.avatars = []
                    }
                    else {
                        var vnumbers = []
                        var vnames = []
                        var vavatars = []
                        for (var i = 0; i < phonebookmodel.length; i++) {
                            vnumbers.splice(0, 0, phonebookmodel[i].number)
                            vnames.splice(0, 0, phonebookmodel[i].nickname)
                            vavatars.splice(0, 0, phonebookmodel[i].avatar)
                        }
                        page.numbers = vnumbers
                        page.names = vnames
                        page.avatars = vavatars
                    }
                }
            }*/
        }

        DialogHeader {
            id: header
            title: numbers.length > 0
                   ? ((numbers.length == 1) ? qsTr("Sync contact", "Add contacts page title")
                                            : qsTr("Sync %n contacts", "Add contacts page title", numbers.length))
                   : qsTr("Select contacts", "Add contacts page title")
        }

        SilicaListView {
            id: listView
            anchors {
                top: header.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            currentIndex: -1
            header: searchComponent
            model: allContactsModel
            delegate: contactsDelegate
            clip: true
            cacheBuffer: page.height * 2
            pressDelay: 0
            spacing: Theme.paddingMedium
            section {
                property: "displayLabel"
                criteria: ViewSection.FirstCharacter
                delegate: sectionDelegate
            }

            FastScroll {
                id: fastScroll
                __hasPageHeight: false
                listView: listView
            }
        }

        BusyIndicator {
            anchors.centerIn: listView
            size: BusyIndicatorSize.Large
            visible: listView.count == 0
            running: visible
        }
    }

    Component {
        id: searchComponent
        SearchField {
            width: parent.width
            placeholderText: qsTr("Search contacts", "Add contacts page search text")
            onTextChanged: {
                if (page.status == DialogStatus.Opened) {
                    allContactsModel.search(text)
                }
            }
        }
    }

    Component {
        id: sectionDelegate
        SectionHeader {
            text: section
        }
    }

    Component {
        id: contactsDelegate

        Column {
            width: parent.width
            Repeater {
                id: internal
                width: parent.width
                model: person.phoneDetails.length
                delegate: BackgroundItem {
                    id: innerItem
                    width: parent.width
                    height: Theme.itemSizeMedium
                    highlighted: down || checked
                    property bool checked: page.numbers.indexOf(number) != -1
                    property string number: person.phoneDetails[index].normalizedNumber

                    onClicked: {
                        var vnumbers = page.numbers
                        var vnames = page.names
                        var vavatars = page.avatars
                        var exists = vnumbers.indexOf(number)
                        if (exists != -1) {
                            vnumbers.splice(exists, 1)
                            vnames.splice(exists, 1)
                            vavatars.splice(exists, 1)
                        }
                        else {
                            vnumbers.splice(0, 0, number)
                            vnames.splice(0, 0, displayLabel)
                            vavatars.splice(0, 0, person.avatarPath)
                        }
                        page.numbers = vnumbers
                        page.names = vnames
                        page.avatars = vavatars
                    }

                    Rectangle {
                        id: avaplaceholder
                        anchors {
                            left: parent.left
                            leftMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }

                        width: ava.width
                        height: ava.height
                        color: ava.status == Image.Ready ? "transparent" : "#40FFFFFF"

                        Image {
                            id: ava
                            width: Theme.itemSizeMedium
                            height: width
                            source: person.avatarPath
                            cache: true
                            asynchronous: true
                        }
                    }

                    Column {
                        id: content
                        anchors {
                            left: avaplaceholder.right
                            right: parent.right
                            margins: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingMedium

                        Label {
                            width: parent.width
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            text: displayLabel
                            color: innerItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSizeSmall
                            text: number
                            color: innerItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }
            }
        }
    }
}
