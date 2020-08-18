#include "serialportimu.h"
#include<QtMath>
#include <complex.h>
#include <cmath>
#include <fftw3.h>


#define BUFSIZE 256
using namespace std;

SerialPortImu::SerialPortImu(QObject *parent) : QObject(parent)
{
    /**
     * Constructor - The object is constructed in QML
     *
     * @param   QObject *parent : this class parent is QML. this
     *      param used for garbage collector
     *
     * @return  --
     *
     * @throws  --
     */

    // List all available serial ports
    refreshDevices();

    // Initilization
    initialize();

    // Config threads
    thread_config();

    /*
     * Log list of available standard baud rates
     * supported by the target platform
     */
    qInfo() << "standard baud rates supported by this platform:"
            << _serial_ports_info.standardBaudRates();
}

SerialPortImu::~SerialPortImu()
{
    //    delete _timer;

    workerThread.quit();
    workerThread.wait();
}

void SerialPortImu::initialize()
{
    /**
     * initializatoin:
     *      supported Baud Rates
     *      Serial Port configuration
     *      Elapesed Time
     *
     *
     * @param --
     *
     * @return --
     *
     * @throws --
     */

    // Init Baud Rate List
    _baud_rate_list.append("2000000");
    _baud_rate_list.append("115200");
    _baud_rate_list.append("9600");

    // Init current speed & appropriate packet length
    _speed = Speed::_2KHz;

    // Init Serial Port config
    _baud_rate = 2000000;
    _data_bits = QSerialPort::Data8;
    _parity = QSerialPort::NoParity;
    _stop_bits = QSerialPort::OneStop;
    _direction = QSerialPort::AllDirections;
    _flow_control = QSerialPort::NoFlowControl;

    _EMG.setBaudRate(_baud_rate);
    _EMG.setDataBits(_data_bits);
    _EMG.setParity(_parity);
    _EMG.setFlowControl(_flow_control);
    _EMG.setStopBits(_stop_bits);

    _IMU.setBaudRate(_baud_rate);
    _IMU.setDataBits(_data_bits);
    _IMU.setParity(_parity);
    _IMU.setFlowControl(_flow_control);
    _IMU.setStopBits(_stop_bits);

    // Init Elapesed Time
    _max_elpsd_time_between_two_intrupt =
            _max_elpsd_time_for_proccessing
            = 0;

    // Init Timer
    //    _timer = new QTimer(this);
    //    connect(_timer, SIGNAL(timeout()), this, SLOT(waiting()));
    //    _timer->start(1000);
    //    _first_packet = true;

    // Init _received_data list
    for (int i = 0; i < NUM_OF_CHANNELS; i++) {
        _received_data.append(QQueue<qint16>());
        _multichannel_offline_data.append(QQueue<double>());
        _multichannel_filtered_data.append(QQueue<double>());
    }
    for (int i = 0; i < NUM_OF_IMU_DATA; i++) {
        _received_data.append(QQueue<qint16>());
    }

    // Init processing index & last plotted data
    //    _proccessing_index = 0;
    //    _last_plotted_data = 0;

    //    _reverse_plot = 1;




    //*************************************************
    //*************************************************
    // Filter Combobox Data
    _filter_list.append("my_filter");
    _filter_list.append("butter_filter");
    _filter_list.append("rectifiction");
    _filter_list.append("rms");
    _filter_list.append("integral");
    _filter_list.append("mean_absolute_value");
    _filter_list.append("zero_crossing");
    _filter_list.append("moving_averaging");
    _filter_list.append("spectrum");
    _filter_list.append("power_spectrum");
    _filter_list.append("mean_frequency");
    _filter_list.append("median_frequency");
    _current_filter_index=0;
    _current_channel=0;
    //*************************************************
    //*************************************************

}

void SerialPortImu::thread_config()
{
    worker = new MyThreadImu(&_received_data, &_last_filename, &_lock_received_data);
    worker->moveToThread(&workerThread);
    connect(&workerThread, &QThread::finished, worker, &QObject::deleteLater);

    // Serial signal/slot
    connect(this, SIGNAL(dataReceiverThread(QByteArray)), worker, SLOT(dataReceiver(QByteArray)));
    connect(this, SIGNAL(dataReceiverThread1(QByteArray)), worker, SLOT(dataReceiver1(QByteArray)));
    connect(this, SIGNAL(portCloseSignal()), worker, SLOT(portClosed()));
    //    connect(this, SIGNAL(speedChangeSignal(quint8)), worker, SLOT(speedChanged(quint8)));

    // File signal/slot
    connect(this, &SerialPortImu::doWriteFile, worker, &MyThreadImu::writeSerialData);
    connect(worker, &MyThreadImu::writeFileDone, this, &SerialPortImu::writeFileDoneSlot);

    workerThread.start();
}

void SerialPortImu::callDoWriteFile()
{
    emit doWriteFile(_selected_file_for_save, _selected_file_for_save_extention);
}

QList<QVariant> SerialPortImu::imuAngles()
{
//    QList<QVariant> angles = {1, 2, 3, 4.5, 5.1, 6.2, 7.3, 8, 9.5, 10.6, 11.0, 12.7, 13.8, 14.9, 45.0};
    QList<QVariant> angles = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
//    QList<QVariant> angles;
//    srand(time(NULL));
//    for (int i = 0; i < angles.size(); i++) {
//        angles[i] = rand()%(60-0+1)+0;
//    }
//    qDebug() << "11";
    _lock_received_data.lockForRead();
//    qDebug() << "22";
//    qDebug() << "index: " << index;
    for (int i = 6, k = 0; i < NUM_OF_IMU_DATA; i += NUM_OF_IMU_SENSOR_DATA) {
        for (int j = 0; j < IMU_EACH_COMPONENT_LEN; j++, k++) {
//            angles.append(_received_data.at(NUM_OF_CHANNELS + i + j)[index]);
            if(_received_data.at(NUM_OF_CHANNELS + i + j).size() > 0){
                angles[k] = static_cast<float>(_received_data.at(NUM_OF_CHANNELS + i + j)[_received_data.at(NUM_OF_CHANNELS + i + j).size()-1]) / static_cast<float>(100);
            }
        }
    }
//    qDebug() << "44";
    _lock_received_data.unlock();
    return angles;
}

QStringList SerialPortImu::getSerialPortsList() const
{
    /**
     *  Getter function for _serial_ports_list. Read available serial
     * port list from _serial_ports_list property and copy them to
     * device_list var for show in QML ComboBox
     *
     * @param   --
     *
     * @return  Available serial port list.
     *
     * @throws  --
     */

    QStringList device_list; // Model for QML ComboBox
    foreach (QSerialPortInfo serialPortInfo, _serial_ports_list) {
        // Fill the model
        device_list.append(serialPortInfo.description() + " "
                           + serialPortInfo.manufacturer() + " ("
                           + serialPortInfo.portName() + ")");
    }
    return device_list;
}

QStringList SerialPortImu::getBaudRateList() const
{
    /**
     *  Getter function for _baud_rate_list. It is used for show baud
     * rate list in GUI.
     *
     * @param   --
     *
     * @return  Supported baud rate list.
     *
     * @throws  --
     */

    return _baud_rate_list;
}

QStringList SerialPortImu::getSpeedList() const
{
    /**
     *  Getter function for _speed_list. It is used for show speed
     * list in GUI.
     *
     * @param   --
     *
     * @return  Supported speed.
     *
     * @throws  --
     */

    QStringList _speed_list;
    _speed_list.append("4 KHz");
    _speed_list.append("2 KHz");
    _speed_list.append("1 KHz");
    _speed_list.append("4800 Hz");
    _speed_list.append("2400 Hz");
    _speed_list.append("1200 Hz");
    _speed_list.append("600 Hz");
    return _speed_list;
}

QStringList SerialPortImu::getFilterList() const
{
    return _filter_list;
}

//qint16 SerialPortImu::getNextData()
//{
//    /**
//     *  Getter function for next unplotted data. It is used for send
//     * next data to customplotitem.cpp for plot
//     *
//     * @param   --
//     *
//     * @return  qint16: next data
//     *
//     * @throws  --
//     */

//    // If there are any non ploted data: return it and increase index
//    _lock_received_data.lockForRead();
//    if (_proccessing_index < _received_data.size()){
////        qDebug() << "Index:" << _proccessing_index;
//        _last_plotted_data = _received_data.at(_proccessing_index++);
//        _lock_received_data.unlock();
//        return _last_plotted_data;
//    }

////    if (_proccessing_index < _received_data.size()){
////        _last_plotted_data = _received_data.at(_proccessing_index);
////        _lock_received_data.unlock();
////        qDebug() << "Index:" << _proccessing_index;
////        _proccessing_index = _proccessing_index + 5;
////        return _last_plotted_data;
////    }

////    if (_received_data.size() > 0) {
////        _proccessing_index = _received_data.size();
////        _last_plotted_data = _received_data.at(_proccessing_index - 1);
////        _lock_received_data.unlock();
////        qDebug() << "Index:" << _proccessing_index;
////        return _last_plotted_data;
////    }

//    // else: plot 0
//    _lock_received_data.unlock();
//    return _last_plotted_data;
//}

//qint16 SerialPortImu::getPrevData()
//{
//    qDebug() << "Get prev:" << _reverse_plot;
////    qDebug() << "val:" << _proccessing_index - _reverse_plot;
////    qDebug() << "cond1:" << (_proccessing_index - _reverse_plot > 0 ? "true" : "false");
////    qDebug() << "cond2:" << (_proccessing_index - _reverse_plot < _received_data.size() ? "true" : "false");
//    _lock_received_data.lockForRead();
//    if (_proccessing_index - _reverse_plot > 0 && _proccessing_index - _reverse_plot < _received_data.size()){
//        _last_plotted_data = _received_data.at(_proccessing_index - _reverse_plot++);
////        qDebug() << "Get prev:" << _reverse_plot;
//    }
//    _lock_received_data.unlock();
//    return _last_plotted_data;
//}



//quint32 SerialPortImu::getProccessingIndex()
//{
//    /**
//     *  Getter function for proccessing index. It is used as time in
//     * plot.
//     *
//     * @param   --
//     *
//     * @return  quint32: _proccessing_index
//     *
//     * @throws  --
//     */

//    return _proccessing_index;
//}


void SerialPortImu::dataReceived()
{
    /**
     * Serial port data receive handler
     *
     * @param   --
     *
     * @return  Save new data to _received_data queue
     *
     * @throws  --
     *
     */

    // The size of data buffered for read
    //    qInfo() << "Available:" << _EMG.bytesAvailable();

    //    _lock_received_data.lockForRead();
    //    if(_received_data.at(0).size() - _proccessing_index > currentSpeed()/2)
    //        _proccessing_index = _received_data.at(0).size() - 1;
    //    _lock_received_data.unlock();
    //    _reverse_plot = 1;

    // process incoming data in another thread
    emit dataReceiverThread(_EMG.readAll());

    //    if(_first_packet){
    //        _first_packet = false;
    //        _timestamp = QDateTime::currentMSecsSinceEpoch();
    //    }
}

void SerialPortImu::dataReceived1()
{
    qInfo() << "Available 1:" << _IMU.bytesAvailable();
    emit dataReceiverThread1(_IMU.readAll());
}


//void SerialPortImu::proccessData()
//{
//    /**
//     * 1 millisecond timer handler for plotting data
//     *
//     * @param   --
//     *
//     * @return  --
//     *
//     * @throws  --
//     *
//     * @emit    `plotData` signal
//     */

//    //    qDebug() << "Proccess Data!";

//    qDebug() << "_timestamp:" << _timestamp << "----" << QDateTime::currentMSecsSinceEpoch();
//    if(_timestamp <= QDateTime::currentMSecsSinceEpoch()){
//        emit plotData();
//        _timestamp++;
//    }
////    qDebug() << "Current timestamp:" << QDateTime::currentMSecsSinceEpoch();
////    emit plotData();

//}

//void SerialPortImu::waiting()
//{
//    /**
//     * 1 second timer handler for when no device is connected
//     *
//     * @param   --
//     *
//     * @return  --
//     *
//     * @throws  --
//     *
//     * @emit    `waiting4Connection` signal
//     */

//    //    qDebug() << "Waiting for connection...";
//    emit waiting4Connection();
//}

bool SerialPortImu::openPort(/*QSerialPortInfo selected_port*/)
{
    /**
     *  If a port is selected by User in QML ComboBox, this function
     * try to open the port and connect `readyRead` signal to
     * `dataReceived` function
     *
     * @param QSerialPortInfo selected_port: The serial port that is
     *      selected by User
     *
     * @return  --
     *
     * @throws  --
     *
     * @emit    `clearPlot` signal
     *
     */

    // Set new port name
//    _EMG.setPort(selected_port);
    _EMG.setPort(_serial_ports_list[_device_index]);
    _IMU.setPort(_serial_ports_list[_device1_index]);

    if(_EMG.open(QIODevice::ReadWrite) && _IMU.open(QIODevice::ReadWrite)) {
//        _EMG.clear();
        _IMU.clear();

        // Clear previous data
        _lock_received_data.lockForWrite();
        for (int i = 0; i < NUM_OF_CHANNELS; i++) {
            _received_data[i].clear();
        }
        for (int i = NUM_OF_CHANNELS; i < NUM_OF_CHANNELS + NUM_OF_IMU_DATA; i++) {
            _received_data[i].clear();
        }
        _lock_received_data.unlock();

        //        _proccessing_index = 0;

        //        if (_timer->isActive()) {
        //            // Stop waiting timer
        //            qDebug() << "Stop waiting timer";
        //            _timer->stop();
        //            _timer->disconnect(SIGNAL(timeout()));
        //        }

        emit clearPlot();

        // Start plot timer
        //        _timestamp = QDateTime::currentMSecsSinceEpoch();
        //        connect(_timer, SIGNAL(timeout()), this, SLOT(proccessData()));
        //        _timer->start(0);
        // Connect serial readyRead to dataReceived function
        connect(&_EMG, SIGNAL(readyRead()), this, SLOT(dataReceived()));
        connect(&_IMU, SIGNAL(readyRead()), this, SLOT(dataReceived1()));

        qInfo() << "Serial port opened";

        _my_timer.start();

        // Start elapsed time between open serial port & close
        // serial port
        _elpsd_time_btwn_open_close.start();

        emit portOpenSignal();

        return true;
    } else {
        qCritical() << "Serial port ERROR!";
        return false;
    }
}

void SerialPortImu::closePort()
{
    /**
     * This function try to close current open serial port
     *
     * @param   --
     *
     * @return  --
     *
     * @throws  --
     *
     */

    //    _lock_received_data.lockForWrite();
    //    for(int s=0;s<100;s++)
    //    {
    //        for(int a=0;a<NUM_OF_CHANNELS;a++)
    //            _received_data[a].append(s);
    //    }
    //    _lock_received_data.unlock();

    if (!_IMU.isOpen()){
        emit writeFileDone();
        emit portCloseSignal();
        return;
    }
    // Lost
    //    _first_packet = true;
    //    _lock_received_data.lockForRead();
    //    double LOST = (is2KHz()
    //                   ? (static_cast<double>(_received_data.at(0).size())/(static_cast<double>(_elpsd_time_btwn_open_close.elapsed())*2))*100
    //                   : (static_cast<double>(_received_data.at(0).size())/static_cast<double>(_elpsd_time_btwn_open_close.elapsed()))*100);
    //    qInfo() << "\n\nWhole Time:"
    //            << _elpsd_time_btwn_open_close.elapsed()
    //            << "ms";
    //    qInfo() << "#data:" << _received_data.at(0).size() << "Bytes";
    //    _lock_received_data.unlock();
    //    qInfo() << "LOST:"
    //            << 100-LOST
    //            << "%\n";

    // Stop Plot Timer
    //    _timer->stop();
    //    _timer->disconnect(SIGNAL(timeout()));

    // Close any opened serial port
    _EMG.close();
    _IMU.close();

    // Disconnect data received handler
    if(_EMG.disconnect(SIGNAL(readyRead())) && _IMU.disconnect(SIGNAL(readyRead())))
        qInfo() << "Disconnected successfully";
    else
        qWarning() << "There is not any signal slot connection";

    // Save data to file
    qDebug() << "MainThread: emit doWriteFile()";

    //    _proccessing_index = 0;
    _max_elpsd_time_between_two_intrupt =
            _max_elpsd_time_for_proccessing = 0;

    emit portCloseSignal();
}

void SerialPortImu::refreshDevices()
{
    /**
     *  If User click on refresh button, this function try to refresh
     * serial ports list that is connected to the computer
     *
     * @param   --
     *
     * @return  --
     *
     * @throws  --
     *
     * @emit `SerialPortsListChanged` to inform QML ComboBox
     *
     */

    // List all available serial ports
    _serial_ports_list = _serial_ports_info.availablePorts();

    // Log all available serial ports in console
    foreach (QSerialPortInfo serialPortInfo, _serial_ports_list) {
        qInfo() << serialPortInfo.description()
                << serialPortInfo.manufacturer()
                << serialPortInfo.portName()
                << serialPortInfo.serialNumber()
                << serialPortInfo.systemLocation();
    }

    emit serialPortsListChanged();
}

void SerialPortImu::deviceChanged(quint8 current_index)
{
    /**
     *  If User select another device from QML ComboBox, this function
     * try to close previous port and open new port
     *
     * @param   quint8 current_index: The index of selected port in
     *      QML ComboBox
     *
     * @return  --
     *
     * @throws  --
     *
     */

    qDebug() << "Current Device 0"
             << _serial_ports_list[current_index].portName();

    // Close last port
    if (_EMG.isOpen())
        closePort();

    _device_index = current_index;

    // Open new port
//    openPort(_serial_ports_list[current_index]);
}

void SerialPortImu::deviceChanged1(quint8 current_index)
{
    qDebug() << "Current Device 1"
             << _serial_ports_list[current_index].portName();

    _device1_index = current_index;
}

void SerialPortImu::baudRateChanged(quint8 current_index)
{
    /**
     *  If User select another baud rate from QML ComboBox, this
     * function try to set new baud rate on serial port
     *
     * @param   quint8 current_index: The index of selected baud rate
     *      QML ComboBox
     *
     * @return  --
     *
     * @throws  --
     *
     */

    qDebug() << "Current Baudrate"
             << _baud_rate_list[current_index];
    _baud_rate = _baud_rate_list[current_index].toInt();
    _EMG.setBaudRate(_baud_rate);
}

void SerialPortImu::speedChanged(quint8 current_index)
{
    /**
     *  If User select another speed from QML ComboBox, this
     * function try to set new speed (sample rate)
     *
     * @param   quint8 current_index: The index of selected speed
     *      QML ComboBox
     *
     * @return  --
     *
     * @throws  --
     *
     */

    _speed = _all_speed[current_index];
    qDebug() << "Current speed:" << currentSpeed();

    //    switch (current_index) {

    //    default:
    //    case 0:
    //        qDebug() << "Current speed:" << "2 KHz";
    //        _speed = Speed::_2KHz;
    //        break;

    //    case 1:
    //        qDebug() << "Current speed:" << "1 KHz";
    //        _speed = Speed::_1KHz;
    //        break;
    //    }

    emit speedChangeSignal(current_index);
}

//bool SerialPortImu::is1KHz()
//{
//    /**
//     *  Is current selected speed 1 KHz?
//     *
//     * @param   --
//     *
//     * @return  true:   if current selected speed is 1 KHz
//     *          false:  if current selected speed is not 1 KHz
//     *
//     * @throws  --
//     *
//     */

//    return _speed == Speed::_1KHz;
//}

//bool SerialPortImu::is2KHz()
//{
//    /**
//     *  Is current selected speed 2 KHz?
//     *
//     * @param   --
//     *
//     * @return  true:   If current selected speed is 2 KHz
//     *          false:  If current selected speed is not 2 KHz
//     *
//     * @throws  --
//     *
//     */

//    return _speed == Speed::_2KHz;
//}

//bool SerialPortImu::thereIsUnplottedData()
//{
//    /**
//     *  Is there any unplotted data?
//     *
//     * @param   --
//     *
//     * @return  true:   If there is unplotted data
//     *          false:  If all data were plotted
//     *
//     * @throws  --
//     *
//     */

//    qDebug() << "_proccessing_index:" << _proccessing_index;
//    _lock_received_data.lockForRead();
//    qDebug() << "_received_data.size():" << _received_data.at(0).size();
////    qDebug() << "thereIsUnplottedData():" << (_proccessing_index < _received_data.size());
//    bool result = _proccessing_index < _received_data.at(0).size();
//    _lock_received_data.unlock();
//    return result;
//}

int SerialPortImu::currentSpeed() const
{
    /**
     *  return current speed (sample rate)
     *
     * @param   --
     *
     * @return  return current speed (sample rate)
     *
     * @throws  --
     *
     */
    return static_cast<int>(_speed);
}

QString SerialPortImu::lastFilename()
{
    /**
     *  Return last filename that contain device data
     *
     * @param   --
     *
     * @return  return last filename
     *
     * @throws  --
     *
     */
    return _last_filename;
}

void SerialPortImu::writeFileDoneSlot()
{
    qDebug() << "MainThread: writeFileDoneSlot()";
    emit writeFileDone();
}


QList<qint16> SerialPortImu::getOfflineData()
{
    return _offline_data;
}

QQueue<double> SerialPortImu::getMultichannelOfflineData()
{
    return _multichannel_offline_data[_current_channel];
}

QQueue<double> SerialPortImu::getMultichannelFilteredData()
{
    qDebug() << "cuurent channel" << _current_channel ;
    return _multichannel_filtered_data[_current_channel];
}

void SerialPortImu::setCurrentChannel(quint8 id)
{
    _current_channel=id;
    //qDebug() << "cuurent channel" << id ;
}

QString SerialPortImu::getSelectedFileForSave()
{
    return _selected_file_for_save;
}

void SerialPortImu::setSelectedFileForSave(QString value)
{
    _selected_file_for_save=value;
}

QString SerialPortImu::getSelectedFileForSaveExtention()
{
    return _selected_file_for_save_extention;
}

void SerialPortImu::setSelectedFileForSaveExtention(QString value)
{
    _selected_file_for_save_extention=value;
}

void SerialPortImu::setCurrentFilterIndex(quint8 index)
{
    _current_filter_index=index;
}

void SerialPortImu::plot_offline()
{

    _multichannel_offline_data.clear();
    for (int i = 0; i < NUM_OF_CHANNELS; i++) {
        _multichannel_offline_data.append(QQueue<double>());
    }


    _selected_file_for_save.remove(0,7);
    if(QSysInfo::productType()=="windows")
        _selected_file_for_save.remove(0,1);


    if(_selected_file_for_save_extention=="Text files (*.txt)")
    {
        QFile inputFile(_selected_file_for_save);
        if (inputFile.open(QIODevice::ReadOnly))
        {
            QTextStream in(&inputFile);
            while (!in.atEnd())
            {
                QString line = in.readLine();
                QStringList dataList = line.split(',');
                for(int j=0;j<16;j++)
                {
                    _multichannel_offline_data[j].push_back(dataList.at(j).QString::toDouble());
                }
            }
        }
        inputFile.close();
    }
    else if (_selected_file_for_save_extention=="Csv Files (*.csv)") {
        QFile inputFile(_selected_file_for_save);
        if (inputFile.open(QIODevice::ReadOnly))
        {
            while (!inputFile.atEnd())
            {
                QString line = inputFile.readLine();
                QStringList dataList = line.split(',');
                for(int j=0;j<NUM_OF_CHANNELS;j++)
                {
                    _multichannel_offline_data[j].push_back(dataList.at(j).QString::toDouble());
                }
            }
        }
        inputFile.close();
    }
    else if (_selected_file_for_save_extention=="Xlsx Files (*.xlsx)") {
        QXlsx::Document xlsx(_selected_file_for_save);
        int index=1;
        QVariant line;
        QStringList Letters={"A","B","C","D","E","F","G","H","I","J",
                             "K","L","M","N","O","P"};
        for(int i=0;i<NUM_OF_CHANNELS;i++)
        {
            while ((line=xlsx.read(Letters.at(i)+QString::number(index))).isValid())
            {
                _last_offline_data=line.toString().QString::toDouble();
                _multichannel_offline_data[i].push_back(_last_offline_data);
                index++;
            }
            index=1;
        }
    }
    emit plotOfflineData();

}

QString SerialPortImu::resultForPopup()
{
    return _result_for_popup;
}

void SerialPortImu::applyFilter(QList<QVariant> channels)
{
    _result_for_popup="";
    _multichannel_filtered_data.clear();
    for (int i = 0; i < NUM_OF_CHANNELS; i++) {
        _multichannel_filtered_data.append(QQueue<double>());
    }
    qDebug() << "Apply Filter:" << _filter_list[_current_filter_index];


    for(int i=0;i<channels.size();i++)
    {
        _input.clear();
        _current_channel=channels.at(i).toInt();
        _len= _multichannel_offline_data.at(_current_channel).size();
        ProcessSignal();
    }
    if(_current_filter_index==6||_current_filter_index==10||_current_filter_index==11)
    {
        emit viewResultPopup();
    }
    else
    {
        emit plotFilteredData();
    }

}

void SerialPortImu::ProcessSignal()
{
    //    qDebug() << "len:" << len;
    //**********************************************************************
    // my_Filter
    if(_current_filter_index==0)
    {
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        for(int i=0;i<_output.size();i++)
        {
            _multichannel_filtered_data[_current_channel].push_back(_output.at(i));
        }

        //***************************
        // write to test file
        //        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\my_filter_me.txt";
        //        QFile file(path);
        //        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        //            qDebug() << "Can not open file!";
        //        QTextStream out(&file);
        //        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
        //            out << _multichannel_filtered_data.at(0).at(i);
        //            out << "\n";
        //        }
        //        file.close();
        //***************************


    }

    //**********************************************************************
    // my_Butter
    if(_current_filter_index==1)
    {

        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        for(int i=0;i<_output.size();i++)
        {
            _multichannel_filtered_data[_current_channel].push_back(_output.at(i));
        }

        //***************************
        // write to test file
        //        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\my_butter_me.txt";
        //        QFile file(path);
        //        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        //            qDebug() << "Can not open file!";
        //        QTextStream out(&file);
        //        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
        //            out << _multichannel_filtered_data.at(0).at(i);
        //            out << "\n";
        //        }
        //        file.close();
        //***************************
    }

    //**********************************************************************
    //rectifiction
    if(_current_filter_index==2)
    {

        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_rectifiction();
        for(int i=0;i<_output.size();i++)
        {
            _multichannel_filtered_data[_current_channel].push_back(_output.at(i));
        }

        //***************************
        // write to test file
        //        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\rectifiction_me.txt";
        //        QFile file(path);
        //        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        //            qDebug() << "Can not open file!";
        //        QTextStream out(&file);
        //        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
        //            out << _multichannel_filtered_data.at(0).at(i);
        //            out << "\n";
        //        }
        //        file.close();
        //***************************
    }

    //**********************************************************************
    //rms
    if(_current_filter_index==3)
    {
        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        //**********************


        QQueue<double> temp;
        int windowLength=30,overlap=10;
        bool zeropad=0;
        int delta = windowLength - overlap;
        int arrLength=_output.size()/delta;
        qDebug() << "len" << arrLength;
        double indices[arrLength];
        for(int i=0;i<arrLength;i++)
        {
            indices[i]=1+(i*delta);
        }
        int index=0;
        if(_output.size()-indices[arrLength-1]+1 < windowLength)
        {
            if(zeropad)
            {

            }
            else
            {
                for(int k=arrLength;k>0;k--)
                {
                    if(indices[k]+windowLength-1<=_output.size())
                    {

                        index=k;
                        break;
                    }
                }
            }
        }
        qDebug() << "index" << index;

        for(int i=0;i<_output.size();i++)
        {
            temp.push_back(qPow(_output.at(i),2));
        }
        for(int i=0;i<_output.size()-windowLength;)
        {
            double data=0;
            for(int j=i;j<i+windowLength;j++)
            {
                data+=temp.at(j);
            }
            _multichannel_filtered_data[_current_channel].push_back(sqrt(data/windowLength));
            i=i+delta;
            //qDebug() << "data" << data;
        }


        //***************************
        // write to test file
        //        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\rms_me.txt";
        //        QFile file(path);
        //        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        //            qDebug() << "Can not open file!";
        //        QTextStream out(&file);
        //        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
        //            out << _multichannel_filtered_data.at(0).at(i);
        //            out << "\n";
        //        }
        //        file.close();
        //***************************
    }


    //**********************************************************************
    //integral
    if(_current_filter_index==4)
    {

        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        //**********************


        QQueue<double> temp;
        int windowLength=30,overlap=10;
        int delta = windowLength - overlap;
        //        int arrLength=static_cast<int>(len/delta);
        //        qDebug() << "len" << arrLength;
        //        double indices[arrLength];
        //        for(int i=0;i<arrLength;i++)
        //        {
        //            indices[i]=1+(i*delta);
        //        }
        for(int i=0;i<_output.size();i++)
        {
            temp.push_back(pow(_output.at(i),2.0));
        }


        for(int i=0;i<_output.size()-windowLength;)
        {
            double data=0;
            for(int j=i;j<i+windowLength;j++)
            {
                data+=temp.at(j);
            }
            //qDebug() << "data:" << data;
            _multichannel_filtered_data[_current_channel].push_back(data);
            i=i+delta;
            //qDebug() << "data" << data;
        }

        //***************************
        // write to test file
        //        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\integral_me.txt";
        //        QFile file(path);
        //        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        //            qDebug() << "Can not open file!";
        //        QTextStream out(&file);
        //        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
        //            out << _multichannel_filtered_data.at(0).at(i);
        //            out << "\n";
        //        }
        //        file.close();
        //***************************
    }

    //**********************************************************************
    //mean absolute value
    if(_current_filter_index==5)
    {

        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        //**********************

        int windowLength=30,overlap=10;
        int delta = windowLength - overlap;
        for(int i=0;i<_output.size()-windowLength;)
        {
            double data=0;
            for(int j=i;j<i+windowLength;j++)
            {
                data+=qFabs(_output.at(j));
            }
            //            qDebug() << "data:" << data;
            _multichannel_filtered_data[_current_channel].push_back(data/windowLength);
            i=i+delta;
            //qDebug() << "data" << data;
        }

        //***************************
        // write to test file
//        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\mean_absolute_value_me.txt";
//        QFile file(path);
//        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
//            qDebug() << "Can not open file!";
//        QTextStream out(&file);
//        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
//            out << _multichannel_filtered_data.at(0).at(i);
//            out << "\n";
//        }
//        file.close();
        //***************************
    }

    //**********************************************************************
    //zero crossing
    if(_current_filter_index==6)
    {

        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        //**********************

        double thres=0.016;
        int ZC=0;
        for(int i=0;i<_output.size()-1;i++)
        {
            if(((_output.at(i)>0&&_output.at(i+1)<0)||
                (_output.at(i)<0&&_output.at(i+1)>0))&&
                    (abs(_output.at(i)-_output.at(i+1))>=thres))
                ZC++;
        }
        qDebug() << "ZC:" << ZC;

        _result_for_popup+="Zero Crossing For Channel '"+ QString::number(_current_channel+1) + "' Is Equal To : "+QString::number(ZC) +"<br>";
    }

    //**********************************************************************
    //moving averaging
    if(_current_filter_index==7)
    {
        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        //**********************


        QQueue<double> input;
        int h_size=150;
        double h[h_size],s=1.0;
        for (int k=0;k<h_size;k++) {
            h[k]=1.0/h_size;
        }
        for (int k=0;k<_output.size();k++) {
            input.push_back(_output.at(k));
            double rOutputY = 0.0;
            int j=0;
            for(int i=0;i<input.size();i++)
            {
                if(j<h_size)
                    rOutputY+=h[j]*input.at(input.size()-i-1);
                j++;

            }
            _multichannel_filtered_data[_current_channel].push_back(rOutputY);
        }
        //***************************
        // write to test file
//        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\moving_averaging_me.txt";
//        QFile file(path);
//        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
//            qDebug() << "Can not open file!";
//        QTextStream out(&file);
//        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
//            out << _multichannel_filtered_data.at(0).at(i);
//            out << "\n";
//        }
//        file.close();
        //***************************
    }

    //**********************************************************************
    //spectrum
    if(_current_filter_index==8)
    {
        double nfft = nextPowerOf2(_len);
        fftw_complex *in, *out;
        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * nfft);
        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * nfft);
        if(nfft>_len)
        {
            for (quint64 i = 0; i < nfft; i++)
            {
                if(i<_len)
                {
                    in[i][0]=_multichannel_offline_data.at(_current_channel).at(i);
                    in[i][1]=0.0;
                }
                else
                {
                    in[i][0]=0.0;
                    in[i][1]=0.0;
                }
            }
        }
        else
        {
            for (quint64 i = 0; i < nfft; i++)
            {
                in[i][0]=_multichannel_offline_data.at(_current_channel).at(i);
                in[i][1]=0.0;

            }
        }

        fftw_plan my_plan;
        my_plan = fftw_plan_dft_1d(nfft, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
        fftw_execute(my_plan);

        // Use 'out' for something
        double sum_real=0,sum_img=0;
        for (quint64 i = 0; i < nfft/2+1; i++)
        {
            sum_real=out[i][0]/_len;
            sum_img=out[i][1]/_len;
            //            qDebug() << "result" << i << ":" << sqrt(pow(sum_real,2)+pow(sum_img,2)) ;
            _multichannel_filtered_data[_current_channel].push_back(sqrt(pow(sum_real,2)+pow(sum_img,2)));
        }

        fftw_destroy_plan(my_plan);
        fftw_free(in);
        fftw_free(out);


        //***************************
        // write to test file
//        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\spectrum_me.txt";
//        QFile file(path);
//        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
//            qDebug() << "Can not open file!";
//        QTextStream out1(&file);
//        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
//            out1 << _multichannel_filtered_data.at(0).at(i);
//            out1 << "\n";
//        }
//        file.close();
        //***************************


    }
    //**********************************************************************
    //power spectrum
    if(_current_filter_index==9)
    {

        //*************************************************************************
        //*************************************************************************
        //*************************************************************************
        //*************************************************************************
        //*************************************************************************

        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_rectifiction();
        //**********************

        fftw_complex *in, *out;
        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _output.size());
        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _output.size());


        // Initialize 'in' with N complex entries
        for (quint64 i = 0; i < _output.size(); i++)
        {
            in[i][0]=_output.at(i);
            in[i][1]=0.0;
        }

        fftw_plan my_plan;
        my_plan = fftw_plan_dft_1d(_output.size(), in, out, FFTW_FORWARD, FFTW_ESTIMATE);
        fftw_execute(my_plan);

        // Use 'out' for something
        double sum_real=0,sum_img=0;
        for (quint64 i = 0; i < _output.size()/2+1; i++)
        {
            //            qDebug() << "out" << i << ":"  << out[i][0] << "..." << out[i][1];
            sum_real=out[i][0];
            sum_img=out[i][1];
            //            qDebug() << "result" << i << ":" << 10*log10(2*(1.0/(1200.0*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)) ;
            _multichannel_filtered_data[_current_channel].push_back(10*log10(2*(1.0/(static_cast<int>(_speed)*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)));
        }

        fftw_destroy_plan(my_plan);
        fftw_free(in);
        fftw_free(out);

        //        //***************************
        //        // write to test file
//        QString path="C:\\Users\\Hossein\\Desktop\\my_output\\power_spectrum_me.txt";
//        QFile file(path);
//        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
//            qDebug() << "Can not open file!";
//        QTextStream out1(&file);
//        for (int i = 0; i < _multichannel_filtered_data.at(0).size(); i++) {
//            out1 << _multichannel_filtered_data.at(0).at(i);
//            out1 << "\n";
//        }
//        file.close();
        //***************************

    }

    //**********************************************************************
    //mean frequency
    if(_current_filter_index==10)
    {

        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_rectifiction();
        //**********************

        double result=0,sum=0;
        QList<double> freq;
        //        qDebug() << "freq" <<":"<< (_output.size()+2)/2;
        for(int i=0;i<static_cast<int>((_output.size()+2)/2);i++)
        {
            //            freq[i]=i*static_cast<int>(_speed)/len;
            freq.push_back(i*static_cast<int>(_speed)/_output.size());
            //qDebug() << "freq" << i <<":"<< freq.at(i);
        }

        fftw_complex *in, *out;
        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _output.size());
        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _output.size());


        // Initialize 'in' with N complex entries
        for (int i = 0; i < _output.size(); i++)
        {
            in[i][0]=_output.at(i);
            in[i][1]=0.0;
        }

        fftw_plan my_plan;
        my_plan = fftw_plan_dft_1d(_output.size(), in, out, FFTW_FORWARD, FFTW_ESTIMATE);
        fftw_execute(my_plan);

        double sum_real=0,sum_img=0;
        for(int j=0;j<static_cast<int>((_output.size()+2)/2);j++)
        {
            sum_real=out[j][0];
            sum_img=out[j][1];
            if(j==0||j==static_cast<int>((_output.size()+2)/2)-1)
            {
                result+=(freq.at(j)*((1.0/(static_cast<int>(_speed)*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)));
                sum+=((1.0/(static_cast<int>(_speed)*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
            }
            else
            {
                result+=(freq.at(j)*(2*(1.0/(static_cast<int>(_speed)*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)));
                sum+=(2*(1.0/(static_cast<int>(_speed)*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
            }
        }

        result=result/sum;
        qDebug() << "mean frequency:" << result;

        _result_for_popup+="Mean Frequency For Channel '"+ QString::number(_current_channel+1) + "' Is Equal To : "+QString::number(result)+"<br>";
        emit viewResultPopup();


    }
    //**********************************************************************
    //median frequency
    if(_current_filter_index==11)
    {

        //**********************
        for(int i=0;i<_len;i++)
        {
            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        }
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_butter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        my_rectifiction();
        //**********************

        fftw_complex *in, *out;
        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _output.size());
        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _output.size());


        // Initialize 'in' with N complex entries
        for (int i = 0; i < _output.size(); i++)
        {
            in[i][0]=_output.at(i);
            in[i][1]=0.0;
        }

        fftw_plan my_plan;
        my_plan = fftw_plan_dft_1d(_output.size(), in, out, FFTW_FORWARD, FFTW_ESTIMATE);
        fftw_execute(my_plan);

        QQueue<double> psdx;
        double sum_real=0,sum_img=0;
        for(int i=0;i<static_cast<int>((_output.size()+2)/2);i++)
        {
            sum_real=out[i][0];
            sum_img=out[i][1];
            if(i==0||i==static_cast<int>((_output.size()+2)/2)-1)
            {
                psdx.push_back((1.0/(static_cast<int>(_speed)*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
            }
            else
            {
                psdx.push_back(2*(1.0/(static_cast<int>(_speed)*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
            }
            //            qDebug() << "psdx" <<i<<":"<< psdx.at(i);
        }


        //                        qDebug() << "sum:" << std::accumulate(psdx.begin(),psdx.end(),0);

        int low=1,high=static_cast<int>((_output.size()+2)/2),mid=ceil((low+high)/2);

        double sum_1_mid=0,sum_mid1_end=0,sum_1_mid1=0,sum_mid_end=0;

        //***********************************************
        for(int i=0;i<psdx.size();i++)
        {
            if(i<mid)
                sum_1_mid+=psdx.at(i);
            else if (i>=mid) {
                sum_mid1_end+=psdx.at(i);
            }
        }
        sum_1_mid1=sum_1_mid-psdx.at(mid-1);
        sum_mid_end=sum_mid1_end+psdx.at(mid-1);
        //***********************************************

        while(!(sum_1_mid>=sum_mid1_end&&sum_1_mid1<sum_mid_end))
        {
            if(sum_1_mid<sum_mid1_end)
                low=mid;
            else
                high=mid;
            mid=ceil((low+high)/2)+1;


            //***********************************************
            sum_1_mid=0;sum_mid1_end=0;sum_1_mid1=0;sum_mid_end=0;
            for(int i=0;i<psdx.size();i++)
            {
                if(i<mid)
                    sum_1_mid+=psdx.at(i);
                else if (i>=mid) {
                    sum_mid1_end+=psdx.at(i);
                }
            }
            sum_1_mid1=sum_1_mid-psdx.at(mid-1);
            sum_mid_end=sum_mid1_end+psdx.at(mid-1);
            //***********************************************
        }

        qDebug() << "median frequency:" << mid;

        _result_for_popup+="Median Frequency For Channel '"+ QString::number(_current_channel+1) + "' Is Equal To : "+QString::number(mid)+"<br>";
        emit viewResultPopup();

    }
}

void SerialPortImu::notch_filter(double w1, double w2, double Q)
{
    double Gb,beta,gain;
    //    static double num[3],den[3];

    w1=w1*M_PI;
    w2=w2*M_PI;

    Gb=qPow(10,-Q/20);
    beta=qSqrt(1-qPow(Gb,2))/Gb*qTan(w2/2);
    gain=1/(1+beta);


    _num[0]=gain;
    _num[1]=gain*(-2*qCos(w1));
    _num[2]=gain;

    _den[0]=1;
    _den[1]=-2*gain*qCos(w1);
    _den[2]=2*gain-1;

}

void SerialPortImu::butterworth(double n, double w,int pass)
{
    int l=static_cast<int>(n);
    complex<double> Q[l],sp[l],sz[l],P[l],Z[l],sg=1.0;
    double V = qTan(w * 1.5707963267948966),G;
    //    qDebug() << "test:" << V;
    complex<double> complexnumber(0, 1.5707963267948966),num1(1,0);
    for (int i=0;i<l;i++) {
        Q[i]=exp((complexnumber / n) * (n+1+(i*2)) );
    }

    if(pass==0)//low
    {
        sg=qPow(V,n);
        for(int i=0;i<l;i++)
        {
            sp[i]= V * Q[i];
            P[i]=(1.0+sp[i]) / (1.0-sp[i]);
            //            qDebug() << "P[i]:" << P[i].real() << "-" << P[i].imag();
            Z[i]=-1;

        }
        complex<double> spProd=1;
        for(int i=0;i<n;i++)
        {
            spProd=spProd*(1.0-sp[i]);
        }
        G=real(sg/spProd);

    }
    else if(pass==1) //high
    {
        for(int i=0;i<l;i++)
        {
            sg = sg * (-Q[i]);
            //            qDebug() << "sg:" << sg.real() << "_" << sg.imag();
            sp[i]= V / Q[i];
            sz[i]=0;
            P[i]=(1.0+sp[i]) / (1.0-sp[i]);
            Z[i]=-1.0;
        }
        sg = 1.0 / sg;
        complex<double> spProd=1.0,szProd=1.0;
        for(int i=0;i<l;i++)
        {
            spProd=spProd*(1.0-sp[i]);
            szProd=szProd*(1.0-sz[i]);
            Z[i] = (1.0+sz[i]) / (1.0-sz[i]);
        }
        G=real(sg*szProd/spProd);
    }




    //****************************************
    vietaFormula(Z,l);
    for(int i=0;i<l+1;i++)
    {
        _Z[i]=_coeff[i].real() * G;
        qDebug() << "Z:" << _Z[i];
    }
    vietaFormula(P,l);
    for(int i=0;i<l+1;i++)
    {
        _P[i]=_coeff[l-i].real();
        qDebug() << "P:" << _P[i];
    }
    //****************************************
}

unsigned int SerialPortImu::nextPowerOf2(unsigned int n)
{
    unsigned count = 0;

    // First n in the below condition
    // is for the case where n is 0
    if (n && !(n & (n - 1)))
        return n;

    while( n != 0)
    {
        n >>= 1;
        count += 1;
    }

    return 1 << count;

}

void SerialPortImu::vietaFormula(complex<double> roots[], int n)
{
    memset(_coeff, 0, sizeof(_coeff));

    // Set highest order coefficient as 1
    _coeff[n] = 1;

    for (int i = 1; i <= n; i++) {
        for (int j = n - i - 1; j < n; j++) {
            _coeff[j] = _coeff[j] + (-1.0) *
                    roots[i - 1] * _coeff[j + 1];
        }
    }
}

void SerialPortImu::my_filter()
{
    _output.clear();
    double f0,w1,w2,Q=1;
    f0=50;
    //        w1=f0/(static_cast<double>(_speed)/2);
    w1=f0/(static_cast<int>(_speed)/2);
    w2=w1/Q;
    notch_filter(w1,w2,Q);

    //        //*******************
    //        // test
    //        _num[0]=0.937215030814235;
    //        _num[1]=-1.810560406099549;
    //        _num[2]=0.937215030814235;
    //        _den[0]=1;
    //        _den[1]=-1.810560406099549;
    //        _den[2]=0.874430061628470;
    //        //*******************

    for (int i=0;i<3;i++)
    {
        _num[i]=_num[i] / _den[0];
        _den[i]=_den[i] / _den[0];
    }


    double z[3]={0,0,0};

    for(int i=0;i<_len;i++)
    {
        _output.push_back(_num[0]*_input.at(i)+z[0]);
        for (int j=1;j<3;j++)
        {
            z[j-1]=_num[j] * _input.at(i) + z[j] - _den[j] * _output.at(i);
        }
    }
}

void SerialPortImu::my_butter()
{
    _output.clear();
    QQueue<double> temp;
    double low_cut_off=20.0,high_cut_off=500.0;
    double n=4.0;
    //        butterworth(n,low_cut_off/(static_cast<double>(_speed)/2),1);
    butterworth(n,low_cut_off/(static_cast<int>(_speed)/2),1);

    //*******************
    // test
    //        _Z[0]=0.872060673053860;
    //        _Z[1]=-3.488242692215441;
    //        _Z[2]=5.232364038323161;
    //        _Z[3]=-3.488242692215441;
    //        _Z[4]=0.872060673053860;
    //        _P[0]=1;
    //        _P[1]=-3.726414498672261;
    //        _P[2]=5.216048195246090;
    //        _P[3]=-3.250018257412982;
    //        _P[4]=0.760489817530429;
    //*******************

    for (int i=0;i<static_cast<int>(n)+1;i++)
    {
        _Z[i]=_Z[i] / _P[0];
        _P[i]=_P[i] / _P[0];

        //            qDebug() << "num:" << _Z[i];
        //            qDebug() << "den:" << _P[i];
    }
    //qDebug() << "_Z[0]:" << _Z[0];

    //*******************************
    double z[static_cast<int>(n)+1];
    for(int i=0;i<static_cast<int>(n)+1;i++)
        z[i]=0.0;
    //*******************************

    for(int i=0;i<_input.size();i++)
    {
        temp.push_back(_Z[0]*_input.at(i)+z[0]);
        //            qDebug() << "temp::" << z[0];
        for (int j=1;j<static_cast<int>(n)+1;j++)
        {
            z[j-1]=_Z[j] * _input.at(i) + z[j] - _P[j] * temp.at(i);
        }
    }

    //        qDebug() << temp;

    //        butterworth(n,high_cut_off/(static_cast<double>(_speed)/2),0);
    butterworth(n,high_cut_off/(static_cast<int>(_speed)/2),0);

    //*******************
    // test
    //        _Z[0]=0.499814997569879;
    //        _Z[1]=1.999259990279517;
    //        _Z[2]=2.998889985419275;
    //        _Z[3]=1.999259990279517;
    //        _Z[4]=0.499814997569879;
    //        _P[0]=1;
    //        _P[1]=2.638627743891248;
    //        _P[2]=2.769309786151489;
    //        _P[3]=1.339280761265205;
    //        _P[4]=0.249821669810126;
    //*******************

    for (int i=0;i<static_cast<int>(n)+1;i++)
    {
        _Z[i]=_Z[i] / _P[0];
        _P[i]=_P[i] / _P[0];
        z[i]=0;
    }



    for(int i=0;i<_input.size();i++)
    {
        _output.push_back(_Z[0]*temp.at(i)+z[0]);
        for (int j=1;j<5;j++)
        {
            z[j-1]=_Z[j] * temp.at(i) + z[j] - _P[j] * _output.at(i);
        }
        //            qDebug() << "emg_2" <<i<<":"<< _multichannel_filtered_data.at(0).at(i);
    }
}

void SerialPortImu::my_rectifiction()
{
    _output.clear();
    for(int i=0;i<_input.size();i++)
    {
        _output.push_back(qFabs(_input.at(i)));
    }
}

//*************************************
