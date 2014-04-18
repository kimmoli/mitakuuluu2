#include "dbusobject.h"

#include "constants.h"
#include <QDebug>

DBusObject::DBusObject(QObject *parent) :
    QObject(parent)
{
}

DBusObject::~DBusObject()
{
    qDebug() << "Disconnecting DBus objects";
    QDBusConnection::sessionBus().unregisterObject(OBJECT_NAME);
    qDebug() << "Disconnecting DBus services";
    QDBusConnection::sessionBus().unregisterService(SERVICE_NAME);
    qDebug() << "Removing DBus objects";
    Q_EMIT doExit();
}

void DBusObject::initialize()
{
    bool ret =
            QDBusConnection::sessionBus().registerService(SERVICE_NAME) &&
            QDBusConnection::sessionBus().registerObject(OBJECT_NAME,
                                                         this,
                                                         QDBusConnection::ExportAllContents);
    if (!ret) {
        exit();
    }
    else {
        qDebug() << "DBus Registered";
    }
}


void DBusObject::exit()
{
    qDebug() << "Requested exiting";

    deleteLater();
}

void DBusObject::notificationCallback(const QString &jid)
{
    qDebug() << "notification callback:" << jid;
    Q_EMIT notification(jid);
}
