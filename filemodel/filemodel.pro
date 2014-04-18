TEMPLATE = lib
QT += quick
QT -= gui
CONFIG += qt plugin

TARGET = $$qtLibraryTarget(filemodel)
target.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/filemodel

SOURCES += \
    src/filemodelplugin.cpp \
    src/filemodel.cpp

HEADERS += \
    src/filemodelplugin.h \
    src/filemodel.h

qmldir.files = qmldir
qmldir.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/filemodel

#mediasource.files = Mitakuuluu2MediaSource.qml
#mediasource.path = /usr/share/jolla-gallery/mediasources/

#qml.files = mediasource
#qml.path = /usr/share/harbour-mitakuuluu2

INSTALLS += target qmldir #mediasource qml
