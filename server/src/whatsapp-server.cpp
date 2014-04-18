#include <QGuiApplication>
#include <QDebug>
#include <sailfishapp.h>

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <grp.h>
#include <pwd.h>

#include <QFile>
#include <QTextStream>
#include <QDateTime>

#include <QLocale>
#include <QTranslator>

#include "client.h"

#include "../logging/logging.h"

Q_DECL_EXPORT
int main(int argc, char *argv[])
{
    setuid(getpwnam("nemo")->pw_uid);
    setgid(getgrnam("privileged")->gr_gid);
    qInstallMessageHandler(stdoutHandler);
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName("harbour-mitakuuluu2");
    app->setApplicationName("harbour-mitakuuluu2");
    qRegisterMetaType<FMessage>("FMessage");
    qDebug() << "Creating D-Bus class";
    QScopedPointer<Client> dbus(new Client(app.data()));
    qDebug() << "D-Bus working";
    int retval = app->exec();
    qDebug() << "App exiting with code:" << QString::number(retval);
    return retval;
}

