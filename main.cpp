#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QSettings>
#include <QStandardPaths>
#include "serialport.h"
#include "customplotitem.h"
#include "defaultsettings.h"
#include "client.h"
#include <QQmlEngine>

void myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{

    QByteArray localMsg = msg.toLocal8Bit();
    const char *file = context.file ? context.file : "";
    const char *function = context.function ? context.function : "";
    switch (type) {
    case QtDebugMsg:
//        fprintf(stderr, "Debug: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
        break;
    case QtInfoMsg:
//        fprintf(stderr, "Info: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
        break;
    case QtWarningMsg:
//        fprintf(stderr, "Warning: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
        break;
    case QtCriticalMsg:
        fprintf(stderr, "Critical: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
        break;
    case QtFatalMsg:
        fprintf(stderr, "Fatal: %s (%s:%u, %s)\n", localMsg.constData(), file, context.line, function);
        break;
    }
}

void first_run() {
    QSettings settings;
    QStringList keys = settings.allKeys();
    QDir dir(QStandardPaths::displayName(QStandardPaths::DocumentsLocation) + "/FUM_EMG");
    if (keys.size() == 0) {
        // Set default setting
        settings.setValue("speeds", "4800-4000-2400-2000-1200-1000-600");
        settings.setValue("current_speed_index", "3");
        settings.setValue("active_channels", "1111111111111111");
        settings.setValue("save_file_path", dir.absolutePath());
        settings.setValue("darkMode","true");
        settings.setValue("fontSize","10");
        settings.setValue("fonts","Bahnschrift,Arial,Candara,Kristen ITC");
        settings.sync();
    }

    if (!dir.exists())
        dir.mkpath(".");
}

int main(int argc, char *argv[])
{
//    qInstallMessageHandler(myMessageOutput); // qDebug global handler

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    // Set Organization Name & Domain & App name for saving global settings
    // For more information visit: https://doc.qt.io/qt-5/qsettings.html#basic-usage
    QCoreApplication::setOrganizationName("FUM_Robotics_Lab");
    QCoreApplication::setOrganizationDomain("robotics.um.ac.ir/");
    QCoreApplication::setApplicationName("EMG");

    first_run();

    QApplication app(argc, argv);

    QThread::currentThread()->setPriority(QThread::TimeCriticalPriority);

    QQuickStyle::setStyle("Material");

    //***************************************************
    // new_gui
//    QQuickStyle::setStyle(QStringLiteral("qrc:/qml/Style"));
    QIcon::setThemeName(QStringLiteral("emg_fum"));
    //***************************************************

    qmlRegisterType<SerialPort>("SerialPort", 1, 0, "SerialPort");
    qmlRegisterType<CustomPlotItem>("CustomPlot", 1, 0, "CustomPlotItem");
    qmlRegisterType<DefaultSettings>("DefaultSettings", 1, 0, "DefaultSettings");
    qmlRegisterType<client>("Client", 1, 0, "Client");
    qmlRegisterType<connection>("Connection", 1, 0, "Connection");

    QQmlApplicationEngine engine;
//    const QUrl url(QStringLiteral("qrc:/main.qml"));
    const QUrl url(QStringLiteral("qrc:/new_gui.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);
    return app.exec();
}
