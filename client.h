#ifndef CLIENT_H
#define CLIENT_H
#include "QObject"
#include "connection.h"
#include <QThread>
#include <QQueue>
#include <QTcpSocket>

class client : public QObject
{
    Q_OBJECT

public:
    client();
    Q_INVOKABLE static connection *connection_object;
    static QString IP;
    static QString port;
    static int receivedData;

public slots:
    Q_INVOKABLE bool returnStatus();

private:
    QThread *connectionThread;

signals:
    Q_INVOKABLE void start(QString, QString);
    Q_INVOKABLE void closeSocket();
    Q_INVOKABLE void plotData();
};

#endif // CLIENT_H
