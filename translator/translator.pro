TEMPLATE = lib
QT += quick sql core dbus
CONFIG += qt plugin

TARGET = $$qtLibraryTarget(translator)
target.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/translator

SOURCES += \
    translatorplugin.cpp \
    translator.cpp

HEADERS += \
    translatorplugin.h \
    translator.h

qmldir.files = qmldir
qmldir.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/translator

INSTALLS += target qmldir
