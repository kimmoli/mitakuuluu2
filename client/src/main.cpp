/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <QtQuick>
#include <sailfishapp.h>

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <grp.h>
#include <pwd.h>

#include <QFile>
#include <QTextStream>
#include <QDateTime>

#include "constants.h"

#include "contactsbasemodel.h"
#include "contactsfiltermodel.h"
#include "conversationmodel.h"
#include "mitakuuluu.h"
#include "audiorecorder.h"

#include <QDebug>

#include <QLocale>
#include <QTranslator>

#include <gst/gst.h>
#include <gst/gstpreset.h>

#include "../logging/logging.h"

static QObject *mitakuuluu_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    static Mitakuuluu *mitakuuluu_singleton = NULL;
    if (!mitakuuluu_singleton) {
        mitakuuluu_singleton = new Mitakuuluu();
    }
    return mitakuuluu_singleton;
}

static QObject *contactsmodel_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);

    static ContactsBaseModel *contactsmodel_singleton = NULL;
    if (!contactsmodel_singleton) {
        contactsmodel_singleton = new ContactsBaseModel();
    }
    return contactsmodel_singleton;
}

Q_DECL_EXPORT
int main(int argc, char *argv[])
{
    setuid(getpwnam("nemo")->pw_uid);
    setgid(getgrnam("privileged")->gr_gid);

    QSettings settings("coderus", "mitakuuluu2");
    if (settings.value("settings/keepLogs", false).toBool())
        qInstallMessageHandler(fileHandler);
    else
        qInstallMessageHandler(stdoutHandler);

    qDebug() << "Init gst presets";
    gst_init(0, 0);
    gst_preset_set_app_dir("/usr/share/jolla-camera/presets/");

    qDBusRegisterMetaType<MyStructure>();
    qDBusRegisterMetaType<QList<MyStructure > >();

    qDebug() << "Starting application";
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName("harbour-mitakuuluu2");
    app->setApplicationName("harbour-mitakuuluu2");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setTitle("Mitakuuluu");

    view->rootContext()->setContextProperty("view", view.data());
    view->rootContext()->setContextProperty("app", app.data());

    view->rootContext()->setContextProperty("emojiPath", "/usr/share/harbour-mitakuuluu2/emoji/");

    view->rootContext()->setContextProperty("appVersion", APP_VERSION);
    view->rootContext()->setContextProperty("appBuildNum", APP_BUILDNUM);

    view->engine()->addImportPath("/usr/share/harbour-mitakuuluu2/qml");

    qDebug() << "Registering QML types";
    qmlRegisterType<ContactsFilterModel>("harbour.mitakuuluu2.client", 1, 0, "ContactsFilterModel");
    qmlRegisterType<ConversationModel>("harbour.mitakuuluu2.client", 1, 0, "ConversationModel");
    qmlRegisterType<AudioRecorder>("harbour.mitakuuluu2.client", 1, 0, "AudioRecorder");

    qmlRegisterSingletonType<ContactsBaseModel>("harbour.mitakuuluu2.client", 1, 0, "ContactsBaseModel", contactsmodel_singleton_provider);
    qmlRegisterSingletonType<Mitakuuluu>("harbour.mitakuuluu2.client", 1, 0, "Mitakuuluu", mitakuuluu_singleton_provider);

    qDebug() << "Showing main widow";
    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->showFullScreen();

    qDebug() << "View showed";;

    int retVal = app->exec();
    qDebug() << "App exiting with code:" << QString::number(retVal);
    return retVal;
}

