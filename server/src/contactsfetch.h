#ifndef CONTACTSFETCH_H
#define CONTACTSFETCH_H

#include <QObject>

#include <QContactManager>
#include <QContactFetchRequest>
#include <QContactDetailFilter>
#include <QContactName>
#include <QContactPhoneNumber>
#include <QContactAvatar>

using namespace QtContacts;

class ContactsFetch : public QObject
{
    Q_OBJECT
public:
    explicit ContactsFetch(QObject *parent = 0);

signals:
    void contactsAvailable(const QStringList &contacts, const QVariantMap &labels, const QVariantMap &avatars);

public slots:
    void allContacts();
};

#endif // CONTACTSFETCH_H
