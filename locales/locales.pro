TEMPLATE = aux

TS_FILE = $$PWD/mitakuuluu2.ts

ts.commands += lupdate $$PWD/.. -ts $$TS_FILE
ts.CONFIG += no_check_exist no_link
ts.output = $$TS_FILE
ts.input = ..

#make transifex site happy. sigh...
transifex.commands += sed -i -e \"s@<numerusform></numerusform>@<numerusform></numerusform>\\n            <numerusform></numerusform>@\" $$TS_FILE
transifex.CONFIG += no_check_exist no_link
transifex.output = $$TS_FILE
transifex.input = ..

QMAKE_EXTRA_TARGETS += ts transifex
PRE_TARGETDEPS += ts transifex

TRANSLATIONS += \
    es.ts \
    zh_HK.ts \
    fr_FR.ts \
    zh_CN.ts \
    it_IT.ts \
    ru_RU.ts \
    nl_BE.ts \
    da_DK.ts \
    fi.ts \
    en_US.ts \
    nl.ts \
    de.ts \
    el.ts \
    tr_TR.ts \
    cs.ts \
    ca.ts \
    $${NULL}

build_translations.target = build_translations
build_translations.commands += lrelease \"$${_PRO_FILE_}\"

QMAKE_EXTRA_TARGETS += build_translations
POST_TARGETDEPS += build_translations

qm.files = $$replace(TRANSLATIONS, .ts, .qm)
qm.path = /usr/share/harbour-mitakuuluu2/locales
qm.CONFIG += no_check_exist

INSTALLS += qm

OTHER_FILES += $$TRANSLATIONS

