#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>

#include <QSettings>

class Settings : public QObject
{
    Q_OBJECT
public:
    explicit Settings(QObject *parent = 0);

private:
    QSettings *settings;
    
public slots:
    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);
    Q_INVOKABLE QVariant value(const QString &key, const QVariant &defaultValue = QVariant());
    Q_INVOKABLE void sync();
    Q_INVOKABLE QVariantList group(const QString &name);
    Q_INVOKABLE void clearGroup(const QString &name);
    
};

#endif // SETTINGS_H
