TEMPLATE = lib
QT += quick
QT -= gui
CONFIG += qt plugin

TARGET = $$qtLibraryTarget(filemodel)
target.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/filemodel

SOURCES += \
    src/filemodelplugin.cpp \
    src/filemodel.cpp \
    src/recursivesearch.cpp

HEADERS += \
    src/filemodelplugin.h \
    src/filemodel.h \
    src/recursivesearch.h

qmldir.files = qmldir
qmldir.path = /usr/share/harbour-mitakuuluu2/qml/harbour/mitakuuluu2/filemodel

INSTALLS += target qmldir
