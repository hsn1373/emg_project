QT += quick quickcontrols2 core serialport

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets printsupport
RC_ICONS = logo3.ico
CONFIG += c++11

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        client.cpp \
        connection.cpp \
        customplotitem.cpp \
        defaultsettings.cpp \
        main.cpp \
        mythread.cpp \
        mythreadimu.cpp \
        qcustomplot.cpp \
        serialport.cpp \
        serialportimu.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    client.h \
    connection.h \
    customplotitem.h \
    defaultsettings.h \
    mythread.h \
    mythreadimu.h \
    qcustomplot.h \
    serialport.h \
    serialportimu.h

INCLUDEPATH += $$PWD\include/


LIBS+= -L"$$PWD\libs"
LIBS += -lmx
LIBS += -lmat
LIBS += -leng
LIBS += -lfftw3-3
LIBS += -lws2_32



# QXlsx code for Application Qt project
QXLSX_PARENTPATH=./         # current QXlsx path is . (. means curret directory)
QXLSX_HEADERPATH=./header/  # current QXlsx header path is ./header/
QXLSX_SOURCEPATH=./source/  # current QXlsx source path is ./source/
include(./QXlsx.pri)

DISTFILES += \
    qtquickcontrols2.conf



