import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

AvatarPickerCrop {
    id: page
    objectName: "avatarPicker"

    property string jid
    signal avatarSet(string avatarPath)

    onAvatarSourceChanged: {
        var avatar = Mitakuuluu.saveAvatarForJid(page.jid, avatarSource)
        Mitakuuluu.setPicture(page.jid, avatar)
        page.avatarSet(avatar)
    }
} 
