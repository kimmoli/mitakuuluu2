#include "translator.h"

#include <QGuiApplication>
#include <QStringList>

Translator::Translator(QObject *parent) :
    QObject(parent)
{
    QSettings settings("coderus", "mitakuuluu2");
    QString currentLocale = settings.value("settings/locale", QString("%1.qm").arg(QLocale::system().name().split(".").first())).toString();

    translator = new QTranslator(this);
    if (translator->load(currentLocale, "/usr/share/harbour-mitakuuluu2/locales", QString(), ".qm")) {
        QGuiApplication::installTranslator(translator);
    }
}
