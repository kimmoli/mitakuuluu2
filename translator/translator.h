#ifndef TRANSLATOR_H
#define TRANSLATOR_H

#include <QObject>
#include <QLocale>
#include <QTranslator>
#include <QSettings>

class Translator : public QObject
{
    Q_OBJECT
public:
    explicit Translator(QObject *parent = 0);

private:
    QTranslator *translator;

};

#endif // TRANSLATOR_H
