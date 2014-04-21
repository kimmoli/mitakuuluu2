TARGET = harbour-mitakuuluu2
target.path = /usr/bin

QT += sql dbus core multimedia
CONFIG += sailfishapp link_pkgconfig
#CONFIG += qml_debug
PKGCONFIG += sailfishapp libexif gstreamer-0.10

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_BUILDNUM=\\\"$$RELEASE\\\"

images.files = images/
images.path = /usr/share/harbour-mitakuuluu2

emoji.files = emoji/
emoji.path = /usr/share/harbour-mitakuuluu2

dbus.files = dbus/harbour.mitakuuluu2.client.service
dbus.path = /usr/share/dbus-1/services

qmls.files = qml
qmls.path = /usr/share/$${TARGET}

desktops.files = $${TARGET}.desktop
desktops.path = /usr/share/applications

icons.files = $${TARGET}.png
icons.path = /usr/share/icons/hicolor/86x86/apps

INSTALLS = images dbus emoji qmls desktops icons

SOURCES += \
    src/audiorecorder.cpp \
    ../threadworker/threadworker.cpp \
    ../threadworker/queryexecutor.cpp \
    src/conversationmodel.cpp \
    src/mitakuuluu.cpp \
    src/contactsfiltermodel.cpp \
    src/contactsbasemodel.cpp \
    src/main.cpp

HEADERS += \
    ../threadworker/threadworker.h \
    ../threadworker/queryexecutor.h \
    src/constants.h \
    src/conversationmodel.h \
    src/mitakuuluu.h \
    src/audiorecorder.h \
    ../logging/logging.h \
    src/contactsfiltermodel.h \
    src/contactsbasemodel.h
