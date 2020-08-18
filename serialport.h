#ifndef SERIALPORT_H
#define SERIALPORT_H

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
#include "mythread.h"
#include <valarray>
#include <complex>
#include <QSettings>


typedef std::complex<double> Complex;
typedef std::valarray<Complex> CArray;


#define NUM_OF_CHANNELS 16

class SerialPort : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool usingWifiRead READ usingWifiRead WRITE usingWifiSloth NOTIFY usingWifiSignal) // receiving data from either wifi or serial
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

    Q_PROPERTY(quint8 current_channel WRITE setCurrentChannel)
    Q_PROPERTY(QQueue<double> multichannel_offline_data READ getMultichannelOfflineData)
    Q_PROPERTY(QQueue<double> multichannel_filtered_data READ getMultichannelFilteredData)

    //***********************************************
    // signal processing

    Q_PROPERTY(quint8 current_filter_index WRITE setCurrentFilterIndex)

    Q_PROPERTY(quint16 notch_ab WRITE setNotchAb)
    Q_PROPERTY(quint16 bandpass_fl WRITE setBandpassFL)
    Q_PROPERTY(quint16 bandpass_fh WRITE setBandpassFH)
    Q_PROPERTY(quint16 bandpass_order WRITE setBandpassOrder)
    Q_PROPERTY(quint16 timeanalysis_windowlength WRITE setTimeAnalysisWindowLengh)
    Q_PROPERTY(quint16 timeanalysis_overlap WRITE setTimeAnalysisOverlap)
    Q_PROPERTY(quint16 moving_averaging_val WRITE setMovingAveragingVal)

    Q_PROPERTY(bool notch_status WRITE setNotchStatus)
    Q_PROPERTY(bool lowpass_status WRITE setLowpassStatus)
    Q_PROPERTY(bool highpass_status WRITE setHighpassStatus)

    //***********************************************

    //***********************************************
    // settings
    Q_PROPERTY(QString save_file_path READ getSaveFilePath)
    Q_PROPERTY(QString active_channels READ getActiveChannels)
    //***********************************************

    // Property for send selected_file name & path when save file
    Q_PROPERTY(QString selected_file_for_save READ getSelectedFileForSave WRITE setSelectedFileForSave)
    // Property for send selected_file extention when save file
    Q_PROPERTY(QString selected_file_for_save_extention READ getSelectedFileForSaveExtention WRITE setSelectedFileForSaveExtention)

private:

    bool usingWifi;
    QTimer *_timer = new QTimer(this);

    QThread workerThread;                       // A thread for heavy loop operations
    MyThread *worker;                           // MtThread is an object that run in above workerThread

    static QSerialPort *_EMG;                           // Object for communicate with serial port
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

    //*******************************
    QString _save_file_path;
    QString _active_channels;
    QString _speeds_str;
    QStringList _speeds_list;
    QString _current_speed_index;
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
    quint16 _notch_ab;
    quint16 _bandpass_fl;
    quint16 _bandpass_fh;
    quint16 _bandpass_order;
    quint16 _timeanalysis_windowlength;
    quint16 _timeanalysis_overlap;
    quint16 _moving_averaging_val;
    bool _notch_status;
    bool _lowpass_status;
    bool _highpass_status;
    QString _result_for_popup;

    explicit SerialPort(QObject *parent = nullptr);
    ~SerialPort();

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
    void setNotchAb(quint16 value);
    void setBandpassFL(quint16 value);
    void setBandpassFH(quint16 value);
    void setBandpassOrder(quint16 value);
    void setTimeAnalysisWindowLengh(quint16 value);
    void setTimeAnalysisOverlap(quint16 value);
    void setMovingAveragingVal(quint16 value);
    void setNotchStatus(bool val);
    void setLowpassStatus(bool val);
    void setHighpassStatus(bool val);
    void initialize();
    void thread_config();

    //***************************
    // settings
    QString getSaveFilePath();
    QString getActiveChannels();
    //***************************

    static int speed;
    static bool notch;
    static bool high;
    static bool low;

    static double notchAb;
    static double highFl;
    static double highOrder;
    static double lowFl;
    static double lowOrder;

    static qint16 result;
    static double z[3], den[3], num[3];
    static complex<double> coeff[5];
    static double high_Z[5], high_P[5], high_n, high_z[3];
    static double low_Z[5], low_P[5], low_n, low_z[3];

    static bool activeChannels[16];

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
    void doWriteFile(QString,QString,QList<QVariant>);
    void portOpenSignal();
    void portCloseSignal();
    void speedChangeSignal(quint8);
    void usingWifiSignal();

    //********************
    // thread signals
    void dataReceiverThread(QByteArray);
    //********************

public slots:
    void dataReceived();
    //    void proccessData();
    //    void waiting();
    bool openPort(QSerialPortInfo selected_port);
    void openWifiPort();
    void closePort();
    void refreshDevices();
    void deviceChanged(quint8 current_index);
    void baudRateChanged(quint8 current_index);
    void speedChanged(quint8 current_index);
    //    bool is1KHz();
    //    bool is2KHz();
    //    bool thereIsUnplottedData();
    int currentSpeed() const;
    QString lastFilename();
    void callDoWriteFile(QList<QVariant> channels);

    //********************
    // thread slots
    void writeFileDoneSlot();
    //********************

    //********************
    // hokm
    bool plot_offline();

    bool returnStatus();


    //*******************
    // signal processing
    QString resultForPopup();
    void applyFilter(QList<QVariant> channels);
    void ProcessSignal();
    void writeFilteredInFile(QString active);
    void notch_filter(double w1,double w2,double Q);
    void butterworth(double n,double w,int pass);
    unsigned int nextPowerOf2(unsigned int n);
    void vietaFormula(complex<double> roots[],int n);
    void usingWifiSloth(bool);
    Q_INVOKABLE bool usingWifiRead();

    void my_filter();
    void low_pass();
    void high_pass();
    void my_butter();
    void my_rectifiction();

    //***************
    // spectrume


    ///////////////////////////////Online Filter//////////////////////////////////

    Q_INVOKABLE void getSpeed(QString a);
    Q_INVOKABLE void notchActive(bool a);
    Q_INVOKABLE void getNotchAb(QString b);
    Q_INVOKABLE void highActive(bool a);
    Q_INVOKABLE void getHighFl(QString b);
    Q_INVOKABLE void getHighOrder(QString b);
    Q_INVOKABLE void lowActive(bool a);
    Q_INVOKABLE void getLowFl(QString b);
    Q_INVOKABLE void getLowOrder(QString b);

    Q_INVOKABLE void initNotch();
    static void notchProc(quint16 data);
    void _vietaFormula(complex<double> roots[], int n);
    Q_INVOKABLE void initHigh();
    static void highProc(quint16 input_data);
    Q_INVOKABLE void initLow();
    static void lowProc(quint16 input_data);

    Q_INVOKABLE void getActiveChannels(int, bool);
    Q_INVOKABLE void disableFilters();
};

#endif // SERIALPORT_H
