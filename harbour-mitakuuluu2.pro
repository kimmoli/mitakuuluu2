TEMPLATE = subdirs
SUBDIRS = \
    locales \
    server \
    client \
    filemodel \
    shareui \
    sharecontacts \
    translator \
#    andriodhelper \
    $${NULL}

OTHER_FILES = \
    rpm/harbour-mitakuuluu2.spec
