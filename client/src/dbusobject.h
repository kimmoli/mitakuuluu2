#ifndef DBUSOBJECT_H
#define DBUSOBJECT_H

#include <QObject>

#include <QtDBus/QtDBus>

class DBusObject : public QObject
{
    Q_CLASSINFO("D-Bus Interface", "org.coderus.harbour_mitakuuluu")
    Q_OBJECT

public:
    explicit DBusObject(QObject *parent = 0);
    virtual ~DBusObject();
    void initialize();
    
signals:
    void doExit();
    void notification(QString jid);
    
public slots:
    void exit();
    void notificationCallback(const QString &jid);
    
};

#endif // DBUSOBJECT_H
