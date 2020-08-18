#ifndef MYTHREADIMU_H
#define MYTHREADIMU_H

//#ifdef _WIN32
//    #include <windows.h>
//    #include <exception>
//#else

//#endif

#include <QObject>
#include <QDebug>
#include <QQueue>
#include <QDir>
#include <QFile>
#include <QDateTime>
#include <QString>
#include <QTextStream>
#include <QByteArray>
#include <QReadWriteLock>
#include <QtMath>
#include <QtEndian>

#include <iostream>
#include <fstream>
#include <string>


#include <stdio.h>
#include <string.h> /* For strcmp() */
#include <stdlib.h> /* For EXIT_FAILURE, EXIT_SUCCESS */
#include <vector>
#include "mat.h"
#include "xlsxdocument.h"
#include "xlsxchartsheet.h"
#include "xlsxcellrange.h"
#include "xlsxchart.h"
#include "xlsxrichstring.h"
#include "xlsxworkbook.h"

using namespace std;

#define START_SPECIFIER 'A'
#define START_SPECIFIER_LEN 1
#define VALUE_LEN 2
#define VALUE_LEN_IMU 2
#define VALUE_SHIFT 32768
#define NUM_OF_CHANNELS 16
#define NUM_OF_IMU_CHANNELS 45
#define PACKET_LEN 33
#define PACKET_LEN_IMU 19
#define PACKET_LEN_IMU_BASE64_ENCODED 25

class MyThreadImu : public QObject
{
    Q_OBJECT
private:
    QList<QQueue<qint16>> *_received_data;
    QString *_last_filename;
    QReadWriteLock *_lock_received_data;

    QByteArray _remaining_data, _remaining_data1;
    quint8 _first_packet1 = 0;

public:
    explicit MyThreadImu(QList<QQueue<qint16>> *, QString *, QReadWriteLock *, QObject *parent = nullptr);
    quint16 hex2UInt16(QByteArray data, bool little_endian = true);
    qint16 hex2Int16(QByteArray data, bool little_endian = true);
    quint16 str2UInt16(QByteArray data);

signals:
    void writeFileDone();

public slots:
    void dataReceiver(QByteArray);
    void dataReceiver1(QByteArray);
    void writeSerialData(QString, QString);
    void portClosed();
//    void speedChanged(quint8);
};

#endif // MYTHREADIMU_H
