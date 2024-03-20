QT += quick
QT += concurrent
QT += svg

CONFIG += c++17

HEADERS += \
    include/FileReader.h

SOURCES += \
    sources/FileReader.cpp \
    sources/main.cpp

RESOURCES += \
    ui/ui.qrc \
    assets/assets.qrc \

