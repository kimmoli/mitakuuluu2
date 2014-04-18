#include "settings.h"
#include <QStringList>
#include <QDebug>

Settings::Settings(QObject *parent) :
    QObject(parent)
{
    settings = new QSettings("coderus", "mitakuuluu2", this);
}

void Settings::setValue(const QString &key, const QVariant &value)
{
    if (settings) {
        settings->setValue(key, value);
        settings->sync();
    }
}

QVariant Settings::value(const QString &key, const QVariant &defaultValue)
{
    if (settings) {
        settings->sync();
        QVariant value = settings->value(key, defaultValue);
        switch (defaultValue.type()) {
        case QVariant::Bool:
            return value.toBool();
        case QVariant::Double:
            return value.toDouble();
        case QVariant::Int:
            return value.toInt();
        case QVariant::String:
            return value.toString();
        case QVariant::StringList:
            return value.toStringList();
        case QVariant::List:
            return value.toList();
        default:
            return value;
        }
    }
    return QVariant();
}

void Settings::sync()
{
    if (settings)
        settings->sync();
}

QVariantList Settings::group(const QString &name)
{
    if (settings) {
        settings->sync();
        settings->beginGroup(name);
        QVariantList result;
        foreach (const QString &key, settings->childKeys()) {
            QVariantMap item;
            item["jid"] = key;
            item["value"] = settings->value(key, 0);
            result.append(item);
        }
        settings->endGroup();
        return result;
    }
    return QVariantList();
}

void Settings::clearGroup(const QString &name)
{
    if (settings) {
        settings->beginGroup(name);
        settings->remove("");
        settings->endGroup();
        settings->sync();
    }
}
