import QtQuick 2.0
import com.jolla.gallery 1.0
import harbour.mitakuuluu2.filemodel 1.0

MediaSource {
    id: root

    //: Label of the Mitakuuluu album in Jolla Gallery application
    //% "Mitakuuluu"
    title: qsTrId("Mitakuuluu")
    icon: "/usr/share/harbour-mitakuuluu2/mediasource/GalleryIcon.qml"
    page: "/usr/share/harbour-mitakuuluu2/mediasource/GalleryGridPage.qml"
    model: _fm
    count: _fm.count
    ready: count > 0

    property Filemodel _fm: Filemodel {
    	sorting: true
        filter: ["*.*"]
        rpath: "home"
        onCountChanged: {
            root.count = _fm.count
        }
    }
}
