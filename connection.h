#ifndef CONNECTION_H
#define CONNECTION_H
#include <iostream>
#include "QObject"
#include <QTcpSocket>
#include <QAbstractSocket>


class connection : public QObject
{

    Q_OBJECT

public:
    connection();
    ~connection();
    Q_INVOKABLE static bool connected;
    static QByteArray dataByte;
    static QTcpSocket *socket;

public slots:
    void start(QString, QString);
    void closeSocket();

signals:
    void startPlotSignal();
private:

};

#endif // CONNECTION_H
