#include "serialport.h"
#include<QtMath>
#include <complex.h>
#include <cmath>
#include <fftw3.h>
#include "connection.h"
#include <QString>


#define BUFSIZE 256
using namespace std;
QSerialPort *SerialPort::_EMG = new QSerialPort;

qint16 SerialPort::result = 0;

int SerialPort::speed = 4800;
bool SerialPort::notch = false;
bool SerialPort::high = false;
bool SerialPort::low = false;

double SerialPort::notchAb = 0;
double SerialPort::highFl = 0;
double SerialPort::highOrder = 0;
double SerialPort::lowFl = 0;
double SerialPort::lowOrder = 0;

double SerialPort::den[3] = {0,0,0};
double SerialPort::num[3] = {0,0,0};
double SerialPort::z[3] = {0,0,0};
complex<double> SerialPort::coeff[5] = {0,0,0,0,0};
double SerialPort::high_Z[5] = {0,0,0,0,0};
double SerialPort::high_P[5] = {0,0,0,0,0};
double SerialPort::high_n = 0;
double SerialPort::high_z[3] = {0,0,0};
double SerialPort::low_Z[5] = {0,0,0,0,0};
double SerialPort::low_P[5] = {0,0,0,0,0};
double SerialPort::low_n = 0;
double SerialPort::low_z[3] = {0,0,0};

bool SerialPort::activeChannels[16] = {false, false, false, false, false, false,
                                      false, false, false, false, false,
                                       false,false, false, false, false};

SerialPort::SerialPort(QObject *parent) : QObject(parent)
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
    usingWifi = true;
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

SerialPort::~SerialPort()
{
    //    delete _timer;

    workerThread.quit();
    workerThread.wait();
}

void SerialPort::initialize()
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
    _speed = Speed::_1200Hz;

    // Init Serial Port config
    _baud_rate = 2000000;
    _data_bits = QSerialPort::Data8;
    _parity = QSerialPort::NoParity;
    _stop_bits = QSerialPort::OneStop;
    _direction = QSerialPort::AllDirections;
    _flow_control = QSerialPort::NoFlowControl;

    _EMG->setBaudRate(_baud_rate);
    _EMG->setDataBits(_data_bits);
    _EMG->setParity(_parity);
    _EMG->setFlowControl(_flow_control);
    _EMG->setStopBits(_stop_bits);

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

    // Init processing index & last plotted data
    //    _proccessing_index = 0;
    //    _last_plotted_data = 0;

    //    _reverse_plot = 1;




    //*************************************************
    //*************************************************
    _current_filter_index=0;
    _current_channel=0;
    //*************************************************
    //*************************************************



    //*************************************************
    // read default settings

    QSettings settings;
    QStringList keys = settings.allKeys();
    for(int i=0; i < keys.size(); i++)
    {
        //********************
        // get setting Name
        QString key = keys[i];
        //********************
        // get setting value
        QVariant value = settings.value(key);
        //****************************************************
        //****************************************************
        if(key=="speeds")
        {
            _speeds_str = value.toString();
            _speeds_list = _speeds_str.split("-");
        }
        else if(key=="current_speed_index")
            _current_speed_index = value.toString();
        else if(key=="save_file_path")
            _save_file_path = value.toString();
        else if (key=="active_channels")
            _active_channels = value.toString();

        //****************************************************
        //****************************************************

        qDebug() << key << ": " << value;
    }

    _speed=_all_speed[_current_speed_index.toInt()];
    qDebug() << "Current speed:" << currentSpeed();

    //************************************************************

}

void SerialPort::thread_config()
{
    worker = new MyThread(&_received_data, &_last_filename, &_lock_received_data);
    worker->moveToThread(&workerThread);
    connect(&workerThread, &QThread::finished, worker, &QObject::deleteLater);

    // Serial signal/slot
    connect(this, SIGNAL(dataReceiverThread(QByteArray)), worker, SLOT(dataReceiver(QByteArray)));
    connect(this, SIGNAL(portCloseSignal()), worker, SLOT(portClosed()));
    //    connect(this, SIGNAL(speedChangeSignal(quint8)), worker, SLOT(speedChanged(quint8)));

    // File signal/slot
    connect(this, &SerialPort::doWriteFile, worker, &MyThread::writeSerialData);
    connect(worker, &MyThread::writeFileDone, this, &SerialPort::writeFileDoneSlot);

    workerThread.start();
}

bool SerialPort::returnStatus()
{
    return _EMG->isOpen();
}

QString SerialPort::getSaveFilePath()
{
    return _save_file_path;
}

QString SerialPort::getActiveChannels()
{
    return _active_channels;
}

void SerialPort::callDoWriteFile(QList<QVariant> channels)
{
    emit doWriteFile(_selected_file_for_save, _selected_file_for_save_extention,channels);
}

QStringList SerialPort::getSerialPortsList() const
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

QStringList SerialPort::getBaudRateList() const
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

QStringList SerialPort::getSpeedList() const
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

QStringList SerialPort::getFilterList() const
{
    return _filter_list;
}

//qint16 SerialPort::getNextData()
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

//qint16 SerialPort::getPrevData()
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



//quint32 SerialPort::getProccessingIndex()
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


void SerialPort::dataReceived()
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
    std::cout<<usingWifi<<std::endl;
    if (usingWifi)
    {
        emit dataReceiverThread(connection::dataByte);
        //qDebug()<<connection::dataByte;
    }
    else
    {
        emit dataReceiverThread(_EMG->readAll());
        //    qDebug()<<_EMG.readAll();
    }
    //    if(_first_packet){
    //        _first_packet = false;
    //        _timestamp = QDateTime::currentMSecsSinceEpoch();
    //    }
}


//void SerialPort::proccessData()
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

//void SerialPort::waiting()
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

bool SerialPort::openPort(QSerialPortInfo selected_port)
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
    _EMG->setPort(selected_port);

    if(_EMG->open(QIODevice::ReadWrite)) {
        _EMG->clear();
        // Clear previous data
        _lock_received_data.lockForWrite();
        for (int i = 0; i < NUM_OF_CHANNELS; i++) {
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
        connect(_EMG, SIGNAL(readyRead()), this, SLOT(dataReceived()));

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

void SerialPort::openWifiPort()
{
    _lock_received_data.lockForWrite();
    for (int i = 0; i < NUM_OF_CHANNELS; i++) {
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

    connect(connection::socket, SIGNAL(readyRead()), this, SLOT(dataReceived()));
    // Start plot timer
    //        _timestamp = QDateTime::currentMSecsSinceEpoch();
    //        connect(_timer, SIGNAL(timeout()), this, SLOT(proccessData()));
    //        _timer->start(0);
    // Connect serial readyRead to dataReceived function
    _my_timer.start();

    // Start elapsed time between open serial port & close
    // serial port
    _elpsd_time_btwn_open_close.start();

    emit portOpenSignal();
}

void SerialPort::closePort()
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

    if (!_EMG->isOpen()){
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
    _EMG->close();

    // Disconnect data received handler
    if(_EMG->disconnect(SIGNAL(readyRead())))
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

void SerialPort::refreshDevices()
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

void SerialPort::deviceChanged(quint8 current_index)
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

    qDebug() << "Current Device"
             << _serial_ports_list[current_index].portName();

    // Close last port
    if (_EMG->isOpen())
        closePort();

    // Open new port
    openPort(_serial_ports_list[current_index]);
}

void SerialPort::baudRateChanged(quint8 current_index)
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
    _EMG->setBaudRate(_baud_rate);
}

void SerialPort::speedChanged(quint8 current_index)
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

//bool SerialPort::is1KHz()
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

//bool SerialPort::is2KHz()
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

//bool SerialPort::thereIsUnplottedData()
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

int SerialPort::currentSpeed() const
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

QString SerialPort::lastFilename()
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

void SerialPort::writeFileDoneSlot()
{
    qDebug() << "MainThread: writeFileDoneSlot()";
    emit writeFileDone();
}


QList<qint16> SerialPort::getOfflineData()
{
    return _offline_data;
}

QQueue<double> SerialPort::getMultichannelOfflineData()
{
    return _multichannel_offline_data[_current_channel];
}

QQueue<double> SerialPort::getMultichannelFilteredData()
{
    qDebug() << "cuurent channel" << _current_channel ;
    return _multichannel_filtered_data[_current_channel];
}

void SerialPort::setCurrentChannel(quint8 id)
{
    _current_channel=id;
    //qDebug() << "cuurent channel" << id ;
}

QString SerialPort::getSelectedFileForSave()
{
    return _selected_file_for_save;
}

void SerialPort::setSelectedFileForSave(QString value)
{
    _selected_file_for_save=value;
}

QString SerialPort::getSelectedFileForSaveExtention()
{
    return _selected_file_for_save_extention;
}

void SerialPort::setSelectedFileForSaveExtention(QString value)
{
    _selected_file_for_save_extention=value;
}

void SerialPort::setCurrentFilterIndex(quint8 index)
{
    _current_filter_index=index;
}

void SerialPort::writeFilteredInFile(QString active){
    //************************************************************************
    //************************************************************************
    //************************************************************************
    // Mollaei based on Hokmabadi codes
    //************************************************************************
    //************************************************************************
    //************************************************************************

    //----check which channels are selected----//
    short len =0;
    short channels[16];
    for(int i=0;i<16;i++){
        if(active.at(i) == '1'){
            channels[len]=i;
            len += 1;
        }
    }
    //---------------------------------------//

    //----remove extra chracters from save path----//
    _selected_file_for_save.remove(0,7);
    if(QSysInfo::productType()=="windows")
        _selected_file_for_save.remove(0,1);
    //--------------------------------------------//

    ///format is txt OR csv
    if(_selected_file_for_save_extention=="Text files (*.txt)"|| _selected_file_for_save_extention=="Csv Files (*.csv)"){
        qDebug()<< _selected_file_for_save;
        qDebug()<<_selected_file_for_save_extention;
        QFile file(_selected_file_for_save);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            qDebug() << "Can not open file!";
        QTextStream out(&file);
        //----write FRL and then selected channels at the begining----//
        out << "010001100101001001001100\n";
        len -= 1;
        for(int i=0;i<=len;i++){
            if(i!=len)
                out<<channels[i]+1<<",";
            else
                out<<channels[i]+1<<"\n";
        }

        len +=1;

        //-----------------------------------------------------------//

        //--write in file----//
        for (int i = 0; i < _multichannel_filtered_data.at(channels[0]).size(); i++) {
            for(int j=0;j<len;j++)
            {
                if(j+1==len)
                    out << _multichannel_filtered_data.at(channels[j]).at(i);
                else
                    out << _multichannel_filtered_data.at(channels[j]).at(i) << ",";
            }
            out << "\n";
        }

        file.close();
        //-----------------//

        ///format is xlsx
    }else if (_selected_file_for_save_extention=="Xlsx Files (*.xlsx)"){
        QXlsx::Document xlsx;
        QStringList Letters={"A","B","C","D","E","F","G","H",
                             "I","J","K","L","M","N","O","P"};


        //----write FRL in binary at the beginning of the file----//
        xlsx.write("A"+QString::number(1),"01000110");
        xlsx.write("B"+QString::number(1),"01010010");
        xlsx.write("C"+QString::number(1),"01001100");
        //-------------------------------------------------------//


        //---- write which channel is filtered ----//
        for(int i=0;i<len;i++)
            xlsx.write(Letters[i]+QString::number(2),channels[i]+1);
        //---------------------------------------//

        //---- write and save in file ----//
        for (int i = 0; i < _multichannel_filtered_data.at(channels[0]).size(); i++) {
            for(int j=0;j<len;j++)
            {
                xlsx.write(Letters.at(j)+QString::number(i+3), _multichannel_filtered_data.at(channels[j]).at(i));
            }
        }
        xlsx.saveAs(_selected_file_for_save);
        //------------------------------//
    }else if (_selected_file_for_save_extention=="Matlab Files (*.mat)")
    {

        MATFile *pmat;
        mxArray *pa1;

        int sizeOfArray=_multichannel_filtered_data.at(0).size();


        QByteArray ba = _selected_file_for_save.toLocal8Bit();
        const char *file = ba.data();
        //const char *file=_selected_file_for_save.toUtf8().data();
        //        const char *file=u8"C:\\Users\\Hossein\\Desktop\\my_output\\حسین.mat";
        //        QString x = QString::fromUtf8("C:\\Users\\Hossein\\Desktop\\my_output\\حسین.mat");
        //        QString myString("C:\\Users\\Hossein\\Desktop\\my_output\\حسین.mat");
        //        QByteArray inUtf8 = myString.toUtf8();
        //        const char *file = inUtf8.constData();
        //        qDebug() <<file;
        //        const char *file=_selected_file_for_save.toStdString().c_str();
        int status;
        pmat = matOpen(file, "w");
        if (pmat == NULL) {
            qDebug() << "Error creating file";
        }

        pa1 = mxCreateDoubleMatrix(sizeOfArray,len,mxREAL);
        if (pa1 == NULL) {
        }

        double *data = mxGetPr(pa1);
        for(int i=0;i<len;i++)
        {
            for (int k=0;k<sizeOfArray;k++) {
                *data=_multichannel_filtered_data.at(len).at(k);
                data++;
            }
        }

        status = matPutVariable(pmat,"Data", pa1);
        if (status != 0) {
        }

        if (matClose(pmat) != 0) {
            qDebug() <<"Error closing file :" << file;
        }


        mxDestroyArray(pa1);


    }


    _last_filename = _selected_file_for_save;

    emit writeFileDone();
}


void SerialPort::setNotchAb(quint16 value)
{
    _notch_ab=value;
}

void SerialPort::setBandpassFL(quint16 value)
{
    _bandpass_fl=value;
}

void SerialPort::setBandpassFH(quint16 value)
{
    _bandpass_fh=value;
}

void SerialPort::setBandpassOrder(quint16 value)
{
    _bandpass_order=value;
}

void SerialPort::setTimeAnalysisWindowLengh(quint16 value)
{
    _timeanalysis_windowlength=value;
}

void SerialPort::setTimeAnalysisOverlap(quint16 value)
{
    _timeanalysis_overlap=value;
}

void SerialPort::setMovingAveragingVal(quint16 value)
{
    _moving_averaging_val=value;
}

void SerialPort::setNotchStatus(bool val)
{
    _notch_status=val;
}

void SerialPort::setLowpassStatus(bool val)
{
    _lowpass_status=val;
}

void SerialPort::setHighpassStatus(bool val)
{
    _highpass_status=val;
}

bool SerialPort::plot_offline()
{
    bool isValid = false;
    int len = 0 ;
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


        // check if file is valid
        if (inputFile.open(QIODevice::ReadOnly))
        {
            QStringList dataList;
            QTextStream in(&inputFile);


            //**************************************
            //read active channels
            int channels[NUM_OF_CHANNELS];
            for(int i=0;i<NUM_OF_CHANNELS;i++)
                channels[i]=0;
            // every valid file must have FRL in hex at the beginning
            // this line cheks if selected file is valid
            isValid = in.readLine().contains("010001100101001001001100");
            if(isValid){
                QString line = in.readLine();
                dataList = line.split(',');
                for(int j=0;j<dataList.length();j++)
                    channels[dataList.at(j).QString::toInt()-1]=1;


                _active_channels="";
                for(int i=0;i<NUM_OF_CHANNELS;i++)
                {
                    _active_channels.append(QString::number(channels[i]));
                }

                //**************************************
                while (!in.atEnd())
                {
                    QString line = in.readLine();
                    QStringList dataList = line.split(',');
                    len = dataList.length();
                    for(int j=0;j<len;j++)
                        _multichannel_offline_data[j].push_back(dataList.at(j).QString::toDouble());
                }
            }
        }
        inputFile.close();
    }
    else if (_selected_file_for_save_extention=="Csv Files (*.csv)")
    {
        QStringList dataList;
        QFile inputFile(_selected_file_for_save);
        if (inputFile.open(QIODevice::ReadOnly))
        {

            // every valid file must have FRL in hex at the beginning
            // this line cheks if selected file is valid
            isValid = inputFile.readLine().contains("10001100101001001001100");
            //----------------------------------------------------------------//
            if(isValid){
                //**************************************
                //read active channels
                int channels[NUM_OF_CHANNELS];
                for(int i=0;i<NUM_OF_CHANNELS;i++)
                    channels[i]=0;
                QString line = inputFile.readLine();
                dataList = line.split(',');
                for(int j=0;j<dataList.length();j++)
                {
                    channels[dataList.at(j).QString::toInt()-1]=1;
                }

                _active_channels="";
                for(int i=0;i<NUM_OF_CHANNELS;i++)
                {
                    _active_channels.append(QString::number(channels[i]));
                }

                //**************************************


                while (!inputFile.atEnd())
                {
                    QString line = inputFile.readLine();
                    QStringList dataList = line.split(',');
                    for(int j=0;j<dataList.length();j++)
                    {
                        _multichannel_offline_data[j].push_back(dataList.at(j).QString::toDouble());
                    }
                }
            }
        }
        inputFile.close();
    }
    else if (_selected_file_for_save_extention=="Xlsx Files (*.xlsx)") {
        QXlsx::Document xlsx(_selected_file_for_save);
        int index=2;
        QVariant line;
        QStringList Letters={"A","B","C","D","E","F","G","H","I","J",
                             "K","L","M","N","O","P"};
        // every valid file must have FRL in hex at the beginning
        // this line cheks if selected file is valid
        isValid = xlsx.read("A"+QString::number(1)).toString().contains("1000110")
                && xlsx.read("B"+QString::number(1)).toString().contains("1010010")
                && xlsx.read("C"+QString::number(1)).toString().contains("1001100");
        //-------------------------------------------------------------------------------------------//
        if(isValid){
            //**************************************
            //read active channels
            int channels[NUM_OF_CHANNELS];
            for(int j=0;j<NUM_OF_CHANNELS;j++)
                channels[j]=0;
            //**************************************

            for(int i=0;i<xlsx.dimension().lastColumn();i++)
            {

                //**************************************
                //read active channels
                line=xlsx.read(Letters.at(i)+QString::number(index));
                channels[line.toInt()-1]=1;

                _active_channels="";
                for(int i=0;i<NUM_OF_CHANNELS;i++)
                {
                    _active_channels.append(QString::number(channels[i]));
                }
                index++;

                //**************************************

                while ((line=xlsx.read(Letters.at(i)+QString::number(index))).isValid())
                {
                    _last_offline_data=line.toString().QString::toDouble();
                    _multichannel_offline_data[i].push_back(_last_offline_data);
                    index++;
                }
                index=2;
            }
        }
    }

    if(isValid){
        emit plotOfflineData();
    }


    return isValid;
}


QString SerialPort::resultForPopup()
{
    return _result_for_popup;
}

void SerialPort::applyFilter(QList<QVariant> channels)
{
    _result_for_popup="";
    _multichannel_filtered_data.clear();
    for (int i = 0; i < NUM_OF_CHANNELS; i++) {
        _multichannel_filtered_data.append(QQueue<double>());
    }


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

void SerialPort::ProcessSignal()
{


    for(int i=0;i<_len;i++)
    {
        _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
    }
    if(_notch_status)
    {
        qDebug() << "in my_filter";
        my_filter();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
    }
    if(_highpass_status)
    {
        qDebug() << "in highpasss";
        high_pass();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
    }
    if(_lowpass_status)
    {
        qDebug() << "in lowpass";
        low_pass();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
    }

    //**********************************************************************
    //rectifiction
    if(_current_filter_index==2)
    {

        //        for(int i=0;i<_len;i++)
        //        {
        //            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        //        }
        //        my_filter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_butter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        my_rectifiction();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _multichannel_filtered_data[_current_channel].push_back(_output.at(i));
        //        }

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
        //        for(int i=0;i<_len;i++)
        //        {
        //            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        //        }
        //        my_filter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_butter();
        //**********************

        _output.clear();

        QQueue<double> temp;
        int windowLength=_timeanalysis_windowlength,overlap=_timeanalysis_overlap;
        bool zeropad=0;
        int delta = windowLength - overlap;
        int arrLength=_input.size()/delta;
        qDebug() << "len" << arrLength;
        double indices[arrLength];
        for(int i=0;i<arrLength;i++)
        {
            indices[i]=1+(i*delta);
        }
        int index=0;
        if(_input.size()-indices[arrLength-1]+1 < windowLength)
        {
            if(zeropad)
            {

            }
            else
            {
                for(int k=arrLength;k>0;k--)
                {
                    if(indices[k]+windowLength-1<=_input.size())
                    {

                        index=k;
                        break;
                    }
                }
            }
        }
        qDebug() << "index" << index;

        for(int i=0;i<_input.size();i++)
        {
            temp.push_back(qPow(_input.at(i),2));
        }
        for(int i=0;i<_input.size()-windowLength;)
        {
            double data=0;
            for(int j=i;j<i+windowLength;j++)
            {
                data+=temp.at(j);
            }
            _output.push_back(sqrt(data/windowLength));
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

        _output.clear();

        QQueue<double> temp;
        int windowLength=_timeanalysis_windowlength,overlap=_timeanalysis_overlap;
        int delta = windowLength - overlap;
        //        int arrLength=static_cast<int>(len/delta);
        //        qDebug() << "len" << arrLength;
        //        double indices[arrLength];
        //        for(int i=0;i<arrLength;i++)
        //        {
        //            indices[i]=1+(i*delta);
        //        }
        for(int i=0;i<_input.size();i++)
        {
            temp.push_back(pow(_input.at(i),2.0));
        }


        for(int i=0;i<_input.size()-windowLength;)
        {
            double data=0;
            for(int j=i;j<i+windowLength;j++)
            {
                data+=temp.at(j);
            }
            //qDebug() << "data:" << data;
            _output.push_back(data);
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

        _output.clear();

        int windowLength=_timeanalysis_windowlength,overlap=_timeanalysis_overlap;
        int delta = windowLength - overlap;
        for(int i=0;i<_input.size()-windowLength;)
        {
            double data=0;
            for(int j=i;j<i+windowLength;j++)
            {
                data+=qFabs(_input.at(j));
            }
            //            qDebug() << "data:" << data;
            _output.push_back(data/windowLength);
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
        double thres=0.016;
        int ZC=0;
        for(int i=0;i<_input.size()-1;i++)
        {
            if(((_input.at(i)>0&&_input.at(i+1)<0)||
                (_input.at(i)<0&&_input.at(i+1)>0))&&
                    (abs(_input.at(i)-_input.at(i+1))>=thres))
                ZC++;
        }
        qDebug() << "ZC:" << ZC;

        _result_for_popup+="Zero Crossing For Channel '"+ QString::number(_current_channel+1) + "' Is Equal To : "+QString::number(ZC) +"<br>";
    }

    //**********************************************************************
    //moving averaging
    if(_current_filter_index==7)
    {

        _output.clear();

        QQueue<double> input;
        int h_size=_moving_averaging_val;
        double h[h_size],s=1.0;
        for (int k=0;k<h_size;k++) {
            h[k]=1.0/h_size;
        }
        for (int k=0;k<_input.size();k++) {
            input.push_back(_input.at(k));
            double rOutputY = 0.0;
            int j=0;
            for(int i=0;i<input.size();i++)
            {
                if(j<h_size)
                    rOutputY+=h[j]*input.at(input.size()-i-1);
                j++;

            }
            _output.push_back(rOutputY);
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
                    in[i][0]=_input.at(i);
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
                in[i][0]=_input.at(i);
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
            _output.push_back(sqrt(pow(sum_real,2)+pow(sum_img,2)));
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

        //        //**********************
        //        for(int i=0;i<_len;i++)
        //        {
        //            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        //        }
        //        my_filter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_butter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_rectifiction();
        //        //**********************


        //****************************
        //****************************
        my_rectifiction();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        _output.clear();
        //****************************
        //****************************


        fftw_complex *in, *out;
        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _input.size());
        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _input.size());


        // Initialize 'in' with N complex entries
        for (quint64 i = 0; i < _input.size(); i++)
        {
            in[i][0]=_input.at(i);
            in[i][1]=0.0;
        }

        fftw_plan my_plan;
        my_plan = fftw_plan_dft_1d(_input.size(), in, out, FFTW_FORWARD, FFTW_ESTIMATE);
        fftw_execute(my_plan);

        // Use 'out' for something
        double sum_real=0,sum_img=0;
        for (quint64 i = 0; i < _input.size()/2+1; i++)
        {
            //            qDebug() << "out" << i << ":"  << out[i][0] << "..." << out[i][1];
            sum_real=out[i][0];
            sum_img=out[i][1];
            //            qDebug() << "result" << i << ":" << 10*log10(2*(1.0/(1200.0*_output.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)) ;
            _output.push_back(10*log10(2*(1.0/(static_cast<int>(_speed)*_input.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)));
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

        //        //**********************
        //        for(int i=0;i<_len;i++)
        //        {
        //            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        //        }
        //        my_filter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_butter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_rectifiction();
        //        //**********************



        //****************************
        //****************************
        my_rectifiction();
        _input.clear();
        for(int i=0;i<_output.size();i++)
        {
            _input.push_back(_output.at(i));
        }
        _output.clear();
        //****************************
        //****************************



        double result=0,sum=0;
        QList<double> freq;
        //        qDebug() << "freq" <<":"<< (_output.size()+2)/2;
        for(int i=0;i<static_cast<int>((_input.size()+2)/2);i++)
        {
            //            freq[i]=i*static_cast<int>(_speed)/len;
            freq.push_back(i*static_cast<int>(_speed)/_input.size());
            //qDebug() << "freq" << i <<":"<< freq.at(i);
        }

        fftw_complex *in, *out;
        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _input.size());
        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _input.size());


        // Initialize 'in' with N complex entries
        for (int i = 0; i < _input.size(); i++)
        {
            in[i][0]=_input.at(i);
            in[i][1]=0.0;
        }

        fftw_plan my_plan;
        my_plan = fftw_plan_dft_1d(_input.size(), in, out, FFTW_FORWARD, FFTW_ESTIMATE);
        fftw_execute(my_plan);

        double sum_real=0,sum_img=0;
        for(int j=0;j<static_cast<int>((_input.size()+2)/2);j++)
        {
            sum_real=out[j][0];
            sum_img=out[j][1];
            if(j==0||j==static_cast<int>((_input.size()+2)/2)-1)
            {
                result+=(freq.at(j)*((1.0/(static_cast<int>(_speed)*_input.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)));
                sum+=((1.0/(static_cast<int>(_speed)*_input.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
            }
            else
            {
                result+=(freq.at(j)*(2*(1.0/(static_cast<int>(_speed)*_input.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2)));
                sum+=(2*(1.0/(static_cast<int>(_speed)*_input.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
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

        //        //**********************
        //        for(int i=0;i<_len;i++)
        //        {
        //            _input.push_back(_multichannel_offline_data.at(_current_channel).at(i));
        //        }
        //        my_filter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_butter();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        my_rectifiction();
        //        //**********************


        //****************************
        //****************************
        //        my_rectifiction();
        //        _input.clear();
        //        for(int i=0;i<_output.size();i++)
        //        {
        //            _input.push_back(_output.at(i));
        //        }
        //        _output.clear();
        //****************************
        //****************************


        fftw_complex *in, *out;
        in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _input.size());
        out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * _input.size());


        // Initialize 'in' with N complex entries
        for (int i = 0; i < _input.size(); i++)
        {
            in[i][0]=_input.at(i);
            in[i][1]=0.0;
        }

        fftw_plan my_plan;
        my_plan = fftw_plan_dft_1d(_input.size(), in, out, FFTW_FORWARD, FFTW_ESTIMATE);
        fftw_execute(my_plan);

        QQueue<double> psdx;
        double sum_real=0,sum_img=0;
        for(int i=0;i<static_cast<int>((_input.size())/2)+2;i++)
        {
            sum_real=out[i][0];
            sum_img=out[i][1];
            if(i==0||i==static_cast<int>((_input.size())/2)+1)
            {
                psdx.push_back((1.0/(static_cast<int>(_speed)*_input.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
            }
            else
            {
                psdx.push_back(2*(1.0/(static_cast<int>(_speed)*_input.size()))*pow(sqrt(pow(sum_real,2)+pow(sum_img,2)),2));
            }
            //            qDebug() << "psdx" <<i<<":"<< psdx.at(i);
        }


        //                        qDebug() << "sum:" << std::accumulate(psdx.begin(),psdx.end(),0);


        psdx.pop_front();

        int low=1,high=static_cast<int>((_input.size())/2),mid=ceil((low+high)/2);
        qDebug() << "high" << high;

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
            //            qDebug() << "in while";
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
    //**********************************************************************



    //*****************************************************************
    //*****************************************************************
    //*****************************************************************
    //*****************************************************************

    for(int i=0;i<_output.size();i++)
    {
        _multichannel_filtered_data[_current_channel].push_back(_output.at(i));
    }

}

void SerialPort::notch_filter(double w1, double w2, double Q)
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

void SerialPort::butterworth(double n, double w,int pass)
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

unsigned int SerialPort::nextPowerOf2(unsigned int n)
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

void SerialPort::vietaFormula(complex<double> roots[], int n)
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

void SerialPort::usingWifiSloth(bool s)
{
    usingWifi = s;
}

bool SerialPort::usingWifiRead()
{
    return usingWifi;
}

void SerialPort::my_filter()
{
    _output.clear();
    double f0,w1,w2,Q=1;
    f0=_notch_ab;
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

void SerialPort::low_pass()
{
    _output.clear();
    double high_cut_off=_bandpass_fl;
    double n=_bandpass_order;
    double z[static_cast<int>(n)+1];
    butterworth(n,high_cut_off/(static_cast<int>(_speed)/2),0);

    for (int i=0;i<static_cast<int>(n)+1;i++)
    {
        _Z[i]=_Z[i] / _P[0];
        _P[i]=_P[i] / _P[0];
        z[i]=0;
    }



    for(int i=0;i<_input.size();i++)
    {
        _output.push_back(_Z[0]*_input.at(i)+z[0]);
        for (int j=1;j<5;j++)
        {
            z[j-1]=_Z[j] * _input.at(i) + z[j] - _P[j] * _output.at(i);
        }
    }
}

void SerialPort::high_pass()
{
    _output.clear();
    double low_cut_off=_bandpass_fh;
    qDebug() << "low_cut_off:" << low_cut_off;
    double n=_bandpass_order;
    butterworth(n,low_cut_off/(static_cast<int>(_speed)/2),1);

    for (int i=0;i<static_cast<int>(n)+1;i++)
    {
        _Z[i]=_Z[i] / _P[0];
        _P[i]=_P[i] / _P[0];
    }

    //*******************************
    double z[static_cast<int>(n)+1];
    for(int i=0;i<static_cast<int>(n)+1;i++)
        z[i]=0.0;
    //*******************************

    for(int i=0;i<_input.size();i++)
    {
        _output.push_back(_Z[0]*_input.at(i)+z[0]);
        for (int j=1;j<static_cast<int>(n)+1;j++)
        {
            z[j-1]=_Z[j] * _input.at(i) + z[j] - _P[j] * _output.at(i);
        }
    }
}

void SerialPort::my_butter()
{
    _output.clear();
    QQueue<double> temp;
    double low_cut_off=_bandpass_fh,high_cut_off=_bandpass_fl;
    double n=_bandpass_order;
    //    double low_cut_off=20.0,high_cut_off=500.0;
    //    double n=4.0;

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

void SerialPort::my_rectifiction()
{
    _output.clear();
    for(int i=0;i<_input.size();i++)
    {
        _output.push_back(qFabs(_input.at(i)));
    }
}

////////////////////////////////// Online Filter//////////////////////////////////////
void SerialPort::getSpeed(QString a)
{
    speed = a.toInt();
}

void SerialPort::notchActive(bool a)
{
    notch = a;
}

void SerialPort::getNotchAb(QString b)
{
    notchAb = b.toDouble();
}
////////////////////////////////////////////////

void SerialPort::highActive(bool a)
{
    high = a;
}

void SerialPort::getHighFl(QString b)
{
    highFl = b.toDouble();
}

void SerialPort::getHighOrder(QString b)
{
    highOrder = b.toDouble();
}
//////////////////////////////////////////////////
void SerialPort::lowActive(bool a)
{
    low = a;
}

void SerialPort::getLowFl(QString b)
{
    lowFl = b.toDouble();
}

void SerialPort::getLowOrder(QString b)
{
    lowOrder = b.toDouble();
}

void SerialPort::initNotch()
{
    //    qDebug()<<"ab:"<<notchAb<<notch;
    double f0,w1,w2,Q=1;
    double Gb,beta,gain;
    f0=notchAb; // input parameter

    w1=f0/(static_cast<int>(speed)/2);
    w2=w1/Q;

    w1=w1*M_PI;
    w2=w2*M_PI;

    Gb=qPow(10,-Q/20);
    beta=qSqrt(1-qPow(Gb,2))/Gb*qTan(w2/2);
    gain=1/(1+beta);


    num[0]=gain;
    num[1]=gain*(-2*qCos(w1));
    num[2]=gain;

    den[0]=1;
    den[1]=-2*gain*qCos(w1);
    den[2]=2*gain-1;


    for (int i=0;i<3;i++)
    {
        num[i]=num[i] / den[0];
        den[i]=den[i] / den[0];
    }
}

void SerialPort::notchProc(quint16 input_data)
{
    double res;
    //    double z[3]={0,0,0};


    res=num[0]*input_data+z[0];


    for (int j=1;j<3;j++)
    {
        z[j-1]=num[j] * input_data + z[j] - den[j] * res;
    }

    SerialPort::result = res;
}

void SerialPort::_vietaFormula(complex<double> roots[], int n)
{

    //complex<double> coeff[n];

    memset(coeff, 0, sizeof(coeff));

    // Set highest order coefficient as 1

    coeff[n] = 1;

    for (int i = 1; i <= n; i++) {
        for (int j = n - i - 1; j < n; j++) {
            coeff[j] = coeff[j] + (-1.0) *
                    roots[i - 1] * coeff[j + 1];
        }
    }
}

void SerialPort::initHigh()
{
    //    qDebug()<<"highFl:"<<highFl<<high;
    //    qDebug()<<"highOrder:"<<highOrder;
    double low_cut_off=highFl;// input_parameter
    double high_n=highOrder;// input_parameter

    double w=low_cut_off/(static_cast<int>(speed)/2);
    int pass=1;

    int l=static_cast<int>(high_n);
    complex<double> Q[l],sp[l],sz[l],P[l],Z[l],sg=1.0;
    //    double high_Z[static_cast<int>(high_n)+1],high_P[static_cast<int>(high_n)+1];
    double V = qTan(w * 1.5707963267948966),G;
    //    qDebug() << "test:" << V;
    complex<double> complexnumber(0, 1.5707963267948966),num1(1,0);
    for (int i=0;i<l;i++) {
        Q[i]=exp((complexnumber / high_n) * (high_n+1+(i*2)) );
    }

    if(pass==0)//low
    {
        sg=qPow(V,high_n);
        for(int i=0;i<l;i++)
        {
            sp[i]= V * Q[i];
            P[i]=(1.0+sp[i]) / (1.0-sp[i]);
            //            qDebug() << "P[i]:" << P[i].real() << "-" << P[i].imag();
            Z[i]=-1;

        }
        complex<double> spProd=1;
        for(int i=0;i<high_n;i++)
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
    _vietaFormula(Z,l);
    for(int i=0;i<l+1;i++)
    {
        //        qDebug()<<coeff[i].real()<<G;
        high_Z[i]=coeff[i].real() * G;
    }
    _vietaFormula(P,l);
    for(int i=0;i<l+1;i++)
    {
        high_P[i]=coeff[l-i].real();
    }
    //****************************************



    for (int i=0;i<static_cast<int>(high_n)+1;i++)
    {
        high_Z[i]=high_Z[i] / high_P[0];
        high_P[i]=high_P[i] / high_P[0];

    }

    for(int i=0;i<static_cast<int>(high_n)+1;i++)
        high_z[i]=0.0;

    for(int i=0;i<5;i++)
    {
        qDebug()<<high_Z[i]<<"****"<<high_P[i];
    }


    //***********************************************************
    //***********************************************************
    //***********************************************************




}

void SerialPort::highProc(quint16 input_data)
{
    double res;
    //    qDebug()<<high_Z[0]<<high_z[0];
    res=high_Z[0]*input_data+high_z[0];

    for (int j=1;j<static_cast<int>(high_n)+1;j++)
    {
        high_z[j-1]=high_Z[j] * input_data + high_z[j] - high_P[j] * res;
    }

    SerialPort::result = qint16(res);
}

void SerialPort::initLow()
{
    //    qDebug()<<"lowFl:"<<lowFl<<low;
    //    qDebug()<<"lowOrder:"<<lowOrder;
    double high_cut_off=lowFl; // input_parameter
    double low_n=lowOrder; // input_parameter

    double low_z[static_cast<int>(low_n)+1];

    double w=high_cut_off/(static_cast<int>(speed)/2);
    int pass=0;

    int l=static_cast<int>(low_n);
    complex<double> Q[l],sp[l],sz[l],P[l],Z[l],sg=1.0;
    //    double low_Z[static_cast<int>(low_n)+1],low_P[static_cast<int>(low_n)+1];
    double V = qTan(w * 1.5707963267948966),G;
    //    qDebug() << "test:" << V;
    complex<double> complexnumber(0, 1.5707963267948966),num1(1,0);
    for (int i=0;i<l;i++) {
        Q[i]=exp((complexnumber / low_n) * (low_n+1+(i*2)) );
    }

    if(pass==0)//low
    {
        sg=qPow(V,low_n);
        for(int i=0;i<l;i++)
        {
            sp[i]= V * Q[i];
            P[i]=(1.0+sp[i]) / (1.0-sp[i]);
            //            qDebug() << "P[i]:" << P[i].real() << "-" << P[i].imag();
            Z[i]=-1;

        }
        complex<double> spProd=1;
        for(int i=0;i<low_n;i++)
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
    _vietaFormula(Z,l);
    for(int i=0;i<l+1;i++)
    {
        low_Z[i]=coeff[i].real() * G;
    }
    _vietaFormula(P,l);
    for(int i=0;i<l+1;i++)
    {
        low_P[i]=coeff[l-i].real();
    }
    //****************************************



    for (int i=0;i<static_cast<int>(low_n)+1;i++)
    {
        low_Z[i]=low_Z[i] / low_P[0];
        low_P[i]=low_P[i] / low_P[0];
        low_z[i]=0;
    }

    for(int i=0;i<5;i++)
    {
        qDebug()<<low_Z[i]<<"****"<<low_P[i];
    }


    //***********************************************************
    //***********************************************************
    //***********************************************************



}

void SerialPort::lowProc(quint16 input_data)
{
    double res;

    res=low_Z[0]*input_data+low_z[0];

    for (int j=1;j<static_cast<int>(low_n)+1;j++)
    {
        low_z[j-1]=low_Z[j] * input_data + low_z[j] - low_P[j] * res;
    }

    SerialPort::result = qint16(res);
}

void SerialPort::getActiveChannels(int i, bool a)
{
    activeChannels[i] = a;
}

void SerialPort::disableFilters()
{
    SerialPort::high = false;
    SerialPort::low = false;
    SerialPort::notch = false;
}

//*************************************

