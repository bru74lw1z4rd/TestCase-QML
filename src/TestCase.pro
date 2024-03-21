QT += quick
QT += concurrent
QT += svg

CONFIG += c++17

HEADERS += \
    include/FileReader/FileReader.h

SOURCES += \
    sources/FileReader/FileReader.cpp \
    sources/main.cpp

RESOURCES += \
    ui/ui.qrc \
    assets/assets.qrc \

