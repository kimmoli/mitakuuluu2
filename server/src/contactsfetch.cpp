#include "contactsfetch.h"

ContactsFetch::ContactsFetch(QObject *parent) :
    QObject(parent)
{
}

void ContactsFetch::allContacts()
{
    QContactManager *contactManager = new QContactManager(this);
    QList<QContact> results = contactManager->contacts();
    qDebug() << "Phone numbers retreived. Processing" << QString::number(results.size()) << "contacts.";
    QStringList syncList;
    QVariantMap syncContacts;
    QVariantMap syncAvatars;
    for (int i = 0; i < results.size(); ++i) {
        QString avatar;
        QList<QContactAvatar> avatars = results.at(i).details<QContactAvatar>();
        QList<QContactDisplayLabel> labels = results.at(i).details<QContactDisplayLabel>();
        QString label;
        if (labels.size() > 0 && !labels.first().isEmpty())
            label = labels.first().label();
        if (avatars.length() > 0 && !avatars.first().isEmpty())
            avatar = avatars.first().imageUrl().toString();
        foreach (QContactPhoneNumber number, results.at(i).details<QContactPhoneNumber>()) {
            if (!number.isEmpty()) {
                QString phone = QContactPhoneNumber(number).number();
                phone = phone.replace(QRegExp("/[^0-9+]/g"),"");
                if (!phone.isEmpty()) {
                    QVariantMap data;
                    data["avatar"] = avatar;
                    data["label"] = label;
                    if (!syncList.contains(phone)) {
                        syncContacts[phone] = label;
                        syncAvatars[phone] = avatar;
                        syncList.append(phone);
                    }
                    if (!phone.contains("+") && !syncList.contains("+" + phone)) {
                        syncContacts["+" + phone] = label;
                        syncAvatars["+" + phone] = avatar;
                        syncList.append("+" + phone);
                    }
                }
            }
        }
    }
    Q_EMIT contactsAvailable(syncList, syncContacts, syncAvatars);
    contactManager->deleteLater();
}
