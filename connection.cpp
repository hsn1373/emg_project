#include "connection.h"
#include <iostream>
#include <QAbstractSocket>
#include <QDebug>
#include <QString>
#include "client.h"

bool connection::connected = true;
QByteArray connection::dataByte = 0;
QTcpSocket *connection::socket = new QTcpSocket;
connection::connection()
{

}

connection::~connection()
{

}

void connection::start(QString a, QString b)
{
    client::IP = a;
    client::port = b;
    connection::socket->connectToHost(a, b.toInt());
    connection::socket->waitForConnected(-1);

    if(socket->waitForConnected(10000)){
        connection::connected = true;
        while (connection::socket->state() == QTcpSocket::ConnectedState)
        {
            if (not connected)
            {
                socket->close();
                break;
            }
            if (connection::socket->waitForReadyRead(-1))
            {
                connection::dataByte = connection::socket->readAll();
                //qDebug()<<dataByte;
            }
        }
    }
}

void connection::closeSocket()
{
    connection::connected = false;
}
