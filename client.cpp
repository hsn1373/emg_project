#include "client.h"
#include "connection.h"
#include <QObject>



connection *client::connection_object = new connection;
QString client::IP = "0";
QString client::port = "0";
int client::receivedData = 0;

client::client()
{
    client::connection_object = new connection;
    connectionThread = new QThread;
    client::connection_object->moveToThread(connectionThread);
    connect(connectionThread, &QThread::finished, client::connection_object, &QObject::deleteLater);
    connect(this, SIGNAL(start(QString, QString)), client::connection_object, SLOT(start(QString, QString)));
    connect(this, SIGNAL(closeSocket()), client::connection_object, SLOT(closeSocket()));
    connectionThread->start();
}

bool client::returnStatus()
{
    return (connection_object->socket->state() == QTcpSocket::ConnectedState);
}
