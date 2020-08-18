#ifndef SERIALPORTIMU_H
#define SERIALPORTIMU_H

#include <QObject>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QDateTime>
#include <QTimer>
#include <QElapsedTimer>
#include <QDebug>
#include <QString>
#include <QtMath>
#include <QQueue>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QThread>
#include <qqmlcontext.h>
#include <QReadWriteLock>
#include <QList>
#include "mythreadimu.h"
#include <valarray>
#include <complex>


typedef std::complex<double> Complex;
typedef std::valarray<Complex> CArray;


#define NUM_OF_CHANNELS 16
#define NUM_OF_IMU_DATA 45
#define NUM_OF_IMU_SENSOR_DATA 9
#define IMU_EACH_COMPONENT_LEN 3

class SerialPortImu : public QObject
{
    Q_OBJECT
    // Property for list all available devices in GUI
    Q_PROPERTY(QStringList serial_ports_list READ getSerialPortsList NOTIFY serialPortsListChanged)
    // Property for list all available Baudrates in GUI
    Q_PROPERTY(QStringList baud_rate_list READ getBaudRateList NOTIFY baudRateListChanged)
    // Property for possible speeds in GUI
    Q_PROPERTY(QStringList speed_list READ getSpeedList)
    // Property for send next data to custom plot
//    Q_PROPERTY(qint16 next_data READ getNextData NOTIFY nextDataChanged)
    // Property for reverse plot
//    Q_PROPERTY(qint16 prev_data READ getPrevData NOTIFY prevDataChanged)
    // Property for send processing index to custom plot
//    Q_PROPERTY(quint32 proccessing_index READ getProccessingIndex NOTIFY proccessingIndexChanged)
    // Property for send processing index to custom plot
    Q_PROPERTY(QList<qint16> offline_data READ getOfflineData)

    //************* Test ************
    Q_PROPERTY(quint8 current_channel WRITE setCurrentChannel)
    Q_PROPERTY(QQueue<double> multichannel_offline_data READ getMultichannelOfflineData)
    Q_PROPERTY(QQueue<double> multichannel_filtered_data READ getMultichannelFilteredData)
    //************* Test ************

    // Property for possible filters in GUI
    Q_PROPERTY(QStringList filter_list READ getFilterList)

    Q_PROPERTY(quint8 current_filter_index WRITE setCurrentFilterIndex)

    // Property for send selected_file name & path when save file
    Q_PROPERTY(QString selected_file_for_save READ getSelectedFileForSave WRITE setSelectedFileForSave)
    // Property for send selected_file extention when save file
    Q_PROPERTY(QString selected_file_for_save_extention READ getSelectedFileForSaveExtention WRITE setSelectedFileForSaveExtention)

private:


    QTimer *_timer = new QTimer(this);

    QThread workerThread;                       // A thread for heavy loop operations
    MyThreadImu *worker;                           // MtThread is an object that run in above workerThread

    QSerialPort _EMG, _IMU;             // Object for communicate with serial port
    quint8 _device_index=0, _device1_index=1;
    QSerialPortInfo _serial_ports_info;         // Object for get available serial devices
    QList<QSerialPortInfo> _serial_ports_list;  // Object for list all available devices in GUI
    QStringList _baud_rate_list;                // Object for list all available devices in GUI

    // Serial Port config
    qint32 _baud_rate;
    QSerialPort::DataBits _data_bits;
    QSerialPort::Parity _parity;
    QSerialPort::StopBits _stop_bits;
    QSerialPort::Direction _direction;
    QSerialPort::FlowControl _flow_control;

    // Elapsed Time
    QElapsedTimer _my_timer, _elpsd_time_btwn_open_close;
    qint64 _max_elpsd_time_between_two_intrupt;
    qint64 _max_elpsd_time_for_proccessing;


    //*******************************
    // signal processing

    QQueue<double> _output,_input;
    // my_filter
    double _num[3],_den[3];

    // my_butter
    double _Z[5],_P[5];
    complex<double> _coeff[5];

    //***************
    // spectrum
    quint64 _i,_j;
    int _len;
    double _nfft,_df,_sum_real,_sum_img;

    //*******************************

    // Timer
//    QTimer *_timer;
//    qint64 _timestamp;
//    bool _first_packet;

    // ReceivedData
//    quint32 _proccessing_index;
//    qint16 _last_plotted_data;

    // Speed
    enum class Speed
    {
        _1KHz = 1000,
        _2KHz = 2000,
        _4KHz = 4000,
        _600Hz = 600,
        _1200Hz = 1200,
        _2400Hz = 2400,
        _4800Hz = 4800,
    };
    Speed _speed;
    Speed _all_speed[7] = { Speed::_4KHz, Speed::_2KHz, Speed::_1KHz, Speed::_4800Hz, Speed::_2400Hz, Speed::_1200Hz, Speed::_600Hz };

    QString _selected_file_for_save;
    QString _selected_file_for_save_extention;

    qint16 _last_offline_data;
    quint32 _proccessing_offline_index;

//    quint32 _reverse_plot;

public:

    QList<QQueue<qint16>> _received_data;
    QString _last_filename;
    QReadWriteLock _lock_received_data;

    QList<qint16> _offline_data;
    QList<QQueue<double>> _multichannel_offline_data;
    QList<QQueue<double>> _multichannel_filtered_data;
    quint8 _current_channel;
    QStringList _filter_list;
    QStringList _channel_list;
    quint8 _current_filter_index;
    QString _result_for_popup;

    explicit SerialPortImu(QObject *parent = nullptr);
    ~SerialPortImu();

    QStringList getSerialPortsList() const;
    QStringList getBaudRateList() const;
    QStringList getSpeedList() const;
    QStringList getFilterList() const;
//    qint16 getNextData();
//    qint16 getPrevData();
//    quint32 getProccessingIndex();
    QList<qint16> getOfflineData();
    QQueue<double> getMultichannelOfflineData();
    QQueue<double> getMultichannelFilteredData();
    void setCurrentChannel(quint8 id);
    QString getSelectedFileForSave();
    void setSelectedFileForSave(QString value);
    QString getSelectedFileForSaveExtention();
    void setSelectedFileForSaveExtention(QString value);
    void setCurrentFilterIndex(quint8 index);
    void initialize();
    void thread_config();

signals:
    void increaseProgress();
    void signalProcessingFinish();
    void viewResultPopup();
    void serialPortsListChanged();
    void baudRateListChanged();
    void nextDataChanged();
    void prevDataChanged();
    void proccessingIndexChanged();
    void plotData();
    void plotOfflineData();
    void plotFilteredData();
    void waiting4Connection();
    void clearPlot();
    void writeFileDone();
    void doWriteFile(QString, QString);
    void portOpenSignal();
    void portCloseSignal();
    void speedChangeSignal(quint8);

    //********************
    // thread signals
    void dataReceiverThread(QByteArray);
    void dataReceiverThread1(QByteArray);
    //********************

public slots:
    void dataReceived();
    void dataReceived1();
//    void proccessData();
//    void waiting();
    bool openPort(/*QSerialPortInfo selected_port*/);
    void closePort();
    void refreshDevices();
    void deviceChanged(quint8 current_index);
    void deviceChanged1(quint8 current_index);
    void baudRateChanged(quint8 current_index);
    void speedChanged(quint8 current_index);
//    bool is1KHz();
//    bool is2KHz();
//    bool thereIsUnplottedData();
    int currentSpeed() const;
    QString lastFilename();
    void callDoWriteFile();
    QList<QVariant> imuAngles();

    //********************
    // thread slots
    void writeFileDoneSlot();
    //********************

    //********************
    // hokm
    void plot_offline();


    //*******************
    // signal processing
    QString resultForPopup();
    void applyFilter(QList<QVariant> channels);
    void ProcessSignal();
    void notch_filter(double w1,double w2,double Q);
    void butterworth(double n,double w,int pass);
    unsigned int nextPowerOf2(unsigned int n);
    void vietaFormula(complex<double> roots[],int n);

    void my_filter();
    void my_butter();
    void my_rectifiction();

    //***************
    // spectrume


    //********************
};

#endif // SERIALPORTIMU_H
