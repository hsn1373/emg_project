#include "mythreadimu.h"

MyThreadImu::MyThreadImu(QList<QQueue<qint16>> *_received_data, QString *_last_filename, QReadWriteLock *_lock_received_data, QObject *parent) : QObject(parent)
{
    this->_received_data = _received_data;
    this->_last_filename = _last_filename;
    this->_lock_received_data = _lock_received_data;
}

void MyThreadImu::dataReceiver(QByteArray data)
{
    /**
     * Serial port data receive handler
     *
     * @param   --
     *
     * @return  Save new data to _received_data queue
     *
     * @throws  --
     */

    //    qDebug() << "\033[36mThread:\033[0m" << "Start dataReceiver...";

    if (data.size()){
        // Read all incoming bytes
        //        qDebug() << "\033[36mThread:\033[0m" << "data size:" << data.size();
        //        qDebug() << "\033[36mThread:\033[0m" << data.toHex(' ');
        // Prepend remaining data
        //        qDebug() << "\033[36mThread:\033[0m" << "Remaining data:" << _remaining_data.toHex(' ');
        data.prepend(_remaining_data);
        //        qDebug() << "\033[36mThread:\033[0m" << "Whole data:" << data.toHex(' ');
        _remaining_data.clear();
        // Find begining of data
        quint8 begin_index = 0;
        for (; begin_index < PACKET_LEN-1; begin_index++) {
            if(data.at(begin_index) == START_SPECIFIER)
                break;
        }
        //        qDebug() << "\033[36mThread:\033[0m" << "begin_index:" << begin_index;
        // Add data to Queue
        for(int i = begin_index; i < data.size(); i+=PACKET_LEN)
        {
            //            qDebug() << "\033[36mThread:\033[0m" << "i:" << i;
            //            qDebug() << "\033[36mThread:\033[0m" << "PACKET_LEN:" << PACKET_LEN;
            /*
                 *  TODO::Find begining of data in each iteration
                 * inplace of PACKET_LEN step
                 */
            if (i + PACKET_LEN > data.size()) {
                // Incomplete packet
                //                qDebug() << "\033[36mThread:\033[0m" << "Incomplete packet";
                _remaining_data.append(data.mid(i));
                break;
            }
            // Convert value to Int
            quint16 Value;
            // Add data to proccessing queue
            for (int j = 0; j < PACKET_LEN-START_SPECIFIER_LEN; j += VALUE_LEN) {
                Value = hex2UInt16(data.mid(i + START_SPECIFIER_LEN + j, VALUE_LEN));
                //                qDebug() << "\033[36mThread:\033[0m" << "Value" << j/VALUE_LEN << "=" << Value << "##" << "Shift" << "=" << Value-VALUE_SHIFT;
                _lock_received_data->lockForWrite();
                (*_received_data)[j/VALUE_LEN].enqueue(Value-VALUE_SHIFT);
                _lock_received_data->unlock();
            }


            //            if(PACKET_LEN > 3){
            //                Value2 = hex2UInt16(data.mid(i + START_SPECIFIER_LEN + VALUE_LEN, VALUE_LEN));
            //                _lock_received_data->lockForWrite();
            //                _received_data->enqueue(Value2-VALUE_SHIFT);
            //                _lock_received_data->unlock();
            //                qDebug() << "\033[36mThread:\033[0m" << "Value2:" << Value2;
            //            }
        }

        //        qDebug() << "\033[32mThread:\033[0m" << "End dataReceiver...";
    } else {
        //        qDebug() << "\033[31mThread:\033[0m" << "No data available!";
    }
}

void MyThreadImu::dataReceiver1(QByteArray data)
{
    if (data.size()){
        // Read all incoming bytes
        //        qDebug() << "\033[36mThread:\033[0m" << "data size:" << data.size();
        qDebug() << "\033[36mThread:\033[0m" << data.toHex(' ');
        // Prepend remaining data
        qDebug() << "\033[36mThread:\033[0m" << "Remaining data:" << _remaining_data.toHex(' ');
        data.prepend(_remaining_data1);
        qDebug() << "\033[36mThread:\033[0m" << "Whole data:" << data.toHex(' ');
        _remaining_data1.clear();
        // Find begining of data
        quint8 begin_index = 0;
        if (_first_packet1 <= 1) {
            if(_first_packet1 == 0){
                qDebug() << "\033[36mThread (dataReceiver1):\033[0m" << "First";
                _first_packet1++;
                return;
            }

            qDebug() << "\033[36mThread (dataReceiver1):\033[0m" << "Second";

            for (; begin_index < PACKET_LEN_IMU_BASE64_ENCODED; begin_index++) {
                if(data.at(begin_index) == 0x00 || data.at(begin_index) == 0x01 || data.at(begin_index) == 0x02 || data.at(begin_index) == 0x03 || data.at(begin_index) == 0x04)
                    break;
            }
            _first_packet1++;
        }
        qDebug() << "\033[36mThread:\033[0m" << "begin_index:" << begin_index;
        // Add data to Queue
        for(int i = begin_index; i < data.size(); i+=PACKET_LEN_IMU_BASE64_ENCODED)
        {
            //            qDebug() << "\033[36mThread:\033[0m" << "i:" << i;
            //            qDebug() << "\033[36mThread:\033[0m" << "PACKET_LEN:" << PACKET_LEN;
            /*
                 *  TODO::Find begining of data in each iteration
                 * inplace of PACKET_LEN step
                 */
            if (i + PACKET_LEN_IMU_BASE64_ENCODED > data.size()) {
                // Incomplete packet
                qDebug() << "\033[36mThread:\033[0m" << "Incomplete packet";
                _remaining_data1.append(data.mid(i));
                break;
            }
            // Base64 decode
//            qDebug() << "\033[36mThread:\033[0m" << "Base64 packet:" << data.mid(i, PACKET_LEN_IMU_BASE64_ENCODED).toHex(' ');
            qDebug() << "\033[36mThread:\033[0m" << "Base64 packet:" << QString(data.mid(i+1, PACKET_LEN_IMU_BASE64_ENCODED));
            QByteArray decoded_data = QByteArray::fromBase64(data.mid(i+START_SPECIFIER_LEN, PACKET_LEN_IMU_BASE64_ENCODED-START_SPECIFIER_LEN));
            qDebug() << "\033[36mThread:\033[0m" << "Decoded packet:" << decoded_data.toHex(' ');
            // Convert value to Int
            qint16 Value;
            // Add data to proccessing queue
            qDebug() << "\033[36mThread:\033[0m" << "IMU Num" << static_cast<char>(data.at(i)+48);
            for (int j = 0, index = NUM_OF_CHANNELS + (data.at(i)*9); j < PACKET_LEN_IMU-START_SPECIFIER_LEN; j += VALUE_LEN_IMU, index++) {
                Value = hex2Int16(decoded_data.mid(j, VALUE_LEN_IMU));
                qDebug() << "\033[36mThread:\033[0m" << "Value" << j/VALUE_LEN << "=" << Value;
                qDebug() << "\033[36mThread:\033[0m" << "Index" << index;
                _lock_received_data->lockForWrite();
                qDebug() << "\033[36mThread:\033[0m" << "1";
                (*_received_data)[index].enqueue(Value);
                qDebug() << "\033[36mThread:\033[0m" << "2";
                _lock_received_data->unlock();
            }


            //            if(PACKET_LEN > 3){
            //                Value2 = hex2UInt16(data.mid(i + START_SPECIFIER_LEN + VALUE_LEN, VALUE_LEN));
            //                _lock_received_data->lockForWrite();
            //                _received_data->enqueue(Value2-VALUE_SHIFT);
            //                _lock_received_data->unlock();
            //                qDebug() << "\033[36mThread:\033[0m" << "Value2:" << Value2;
            //            }
        }
qDebug() << "\033[36mThread:\033[0m" << "3";
        //        qDebug() << "\033[32mThread:\033[0m" << "End dataReceiver...";
    } else {
        //        qDebug() << "\033[31mThread:\033[0m" << "No data available!";
    }
}

void MyThreadImu::writeSerialData(QString _selected_file_for_save, QString _selected_file_for_save_extention)
{

    // Save data to file
    //    qDebug() << "\033[36mThread:\033[0m" << "ReadWriteThread: Save to file thread...";

    //************************************************************************
    //************************************************************************
    //************************************************************************
    // Hokmabadi
    //************************************************************************
    //************************************************************************
    //************************************************************************

    // Save data to file
    /*QDir().mkdir("Output"); // Create "Output" directory if not exist
        QDateTime now = QDateTime::currentDateTime();
        //    qDebug() << now.toString("yyyy-MM-ddTHH-mm-ss");
        _last_filename = "Output_" + now.toString("yyyy-MM-ddTHH-mm-ss") + ".txt";
        QString fileName = "Output/" + _last_filename;*/

    _selected_file_for_save.remove(0,7);
    if(QSysInfo::productType()=="windows")
        _selected_file_for_save.remove(0,1);


    if(_selected_file_for_save_extention=="Text files (*.txt)"|| _selected_file_for_save_extention=="Csv Files (*.csv)")
    {
        QFile file(_selected_file_for_save);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            qDebug() << "Can not open file!";
        QTextStream out(&file);
        _lock_received_data->lockForRead();
        int min_emg_qeueue_size = _received_data->at(0).size(), min_imu_qeueue_size = _received_data->at(16).size();
        for (int i = 0; i < NUM_OF_CHANNELS; i++) {
            min_emg_qeueue_size = qMin(min_emg_qeueue_size, _received_data->at(i).size());
        }
        for (int i = NUM_OF_CHANNELS; i < NUM_OF_CHANNELS + NUM_OF_IMU_CHANNELS; i++) {
            min_imu_qeueue_size = qMin(min_imu_qeueue_size, _received_data->at(i).size());
        }
        qDebug() << "\033[36mThread:\033[0m" << "min_emg_qeueue_size:" << min_emg_qeueue_size;
        qDebug() << "\033[36mThread:\033[0m" << "min_imu_qeueue_size:" << min_imu_qeueue_size;
        quint8 proportion = qFloor(min_emg_qeueue_size/min_imu_qeueue_size);
        qDebug() << "\033[36mThread:\033[0m" << "Proportion:" << proportion;
        for (int i = 0; i < min_emg_qeueue_size && i < min_imu_qeueue_size*proportion; i++) {
            for(int j=0;j<NUM_OF_CHANNELS;j++)
            {
                if(j+1==NUM_OF_CHANNELS){
                    out << _received_data->at(j).at(i);
//                    qDebug() << "\033[36mThread:\033[0m" << "1: i=" << i << " j=" << j << "_received_data->at(j)=" << _received_data->at(j).size();
                }
                else{
                    out << _received_data->at(j).at(i) << ",";
//                    qDebug() << "\033[36mThread:\033[0m" << "2: i=" << i << " j=" << j << "_received_data->at(j)=" << _received_data->at(j).size();
                }
            }
            for(int j=NUM_OF_CHANNELS; j < NUM_OF_CHANNELS + NUM_OF_IMU_CHANNELS; j++)
            {
                out << ",";
                if ((j-NUM_OF_CHANNELS) > 0 && ((j-NUM_OF_CHANNELS+3) % 9 == 0 || (j-NUM_OF_CHANNELS+2) % 9 == 0 || (j-NUM_OF_CHANNELS+1) % 9 == 0)) {
                    // angle
                    out << static_cast<float>(_received_data->at(j).at(i/proportion)) / static_cast<float>(100);
                } else {
                    // Speed or Acceleration
                    out << _received_data->at(j).at(i/proportion);
                }

//                qDebug() << "\033[36mThread:\033[0m" << "3: i=" << i << " j=" << j << "_received_data->at(j)=" << _received_data->at(j).size() << " i/proportion=" << i/proportion;
            }
            out << "\n";
        }
        _lock_received_data->unlock();
        file.close();
    }
    else if (_selected_file_for_save_extention=="Xlsx Files (*.xlsx)") {
        QXlsx::Document xlsx;
        _lock_received_data->lockForRead();
        QStringList Letters={"A","B","C","D","E","F","G","H",
                             "I","J","K","L","M","N","O","P"};
        for (int i = 0; i < _received_data->at(0).size(); i++) {
            for(int j=0;j<NUM_OF_CHANNELS;j++)
            {
                xlsx.write(Letters.at(j)+QString::number(i+1), _received_data->at(j).at(i));
            }
        }

        _lock_received_data->unlock();
        xlsx.saveAs(_selected_file_for_save);
    }
    else if (_selected_file_for_save_extention=="Matlab Files (*.mat)")
    {

        MATFile *pmat;
        mxArray *pa1;

        _lock_received_data->lockForRead();
        int sizeOfArray=_received_data->at(0).size();
        _lock_received_data->unlock();


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

        pa1 = mxCreateDoubleMatrix(sizeOfArray,NUM_OF_CHANNELS,mxREAL);
        if (pa1 == NULL) {
        }

        double *data = mxGetPr(pa1);
        for(int i=0;i<NUM_OF_CHANNELS;i++)
        {
            for (int k=0;k<sizeOfArray;k++) {
                *data=_received_data->at(i).at(k);
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

    *_last_filename = _selected_file_for_save;


    //************************************************************************
    //************************************************************************
    //************************************************************************
    // Hokmabadi
    //************************************************************************
    //************************************************************************
    //************************************************************************

    //    QDir().mkdir("Output"); // Create "Output" directory if not exist
    //    QDateTime now = QDateTime::currentDateTime();
    //    //    qDebug() << now.toString("yyyy-MM-ddTHH-mm-ss");
    //    *_last_filename = "Output_" + now.toString("yyyy-MM-ddTHH-mm-ss") + ".txt";
    //    QString fileName = "Output/" + *_last_filename;
    //    QFile file(fileName);
    //    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
    //        qDebug() << "\033[31mThread:\033[0m" << "Can not open file!";
    //    QTextStream out(&file);
    //    _lock_received_data->lockForRead();
    //    for (int i = 0; i < _received_data->size(); ++i) {
    //        out << _received_data->at(i) << "\n";
    //    }
    //    _lock_received_data->unlock();
    //    file.close();
    qDebug() << "\033[32mThread:\033[0m" << "ReadWriteThread: emit writeFileDone";
    emit writeFileDone();
}

void MyThreadImu::portClosed()
{
    qDebug() << "\033[36mThread:\033[0m" << "portClosed slot.";
    _remaining_data.clear();
    _first_packet1 = 0;
}

//void MyThreadImu::speedChanged(quint8 current_index)
//{
//    switch (current_index) {

//    default:
//    case 0:
//        qDebug() << "\033[36mThread:\033[0m" << "Current speed:" << "2 KHz";
////        PACKET_LEN = 5;
//        break;

//    case 1:
//        qDebug() << "\033[36mThread:\033[0m" << "Current speed:" << "1 KHz";
////        PACKET_LEN = 3;
//        break;
//    }
//}

quint16 MyThreadImu::hex2UInt16(QByteArray data, bool little_endian)
{
    /**
     * Calculate unsigned int value of hex
     *
     * @param   QByteArray data: 2 byte data whitch should convert to
     *      int bool little_endian: specify that data is in LITTLE
     *      ENDIAN form or BIG ENDIAN form
     *
     * @return  quint16: equivalent unsigned int
     *
     * @throws  --
     */

    if (little_endian)
        return static_cast<quint16>(
                    (static_cast<quint8>(data.at(1)) << 8)
                    + static_cast<quint8>(data.at(0))
                    );
    else
        return static_cast<quint16>(
                    (static_cast<quint8>(data.at(0)) << 8)
                    + static_cast<quint8>(data.at(1))
                    );
}

qint16 MyThreadImu::hex2Int16(QByteArray data, bool little_endian)
{
    /**
     * Calculate unsigned int value of hex
     *
     * @param   QByteArray data: 2 byte data whitch should convert to
     *      int bool little_endian: specify that data is in LITTLE
     *      ENDIAN form or BIG ENDIAN form
     *
     * @return  quint16: equivalent unsigned int
     *
     * @throws  --
     */
    qDebug() << "\033[36mThread:\033[0m" << "hex2Int16 data (before swap): " << data.toHex(' ');
    if (little_endian){
        char swp = data.at(0);
        data[0] = data[1];
        data[1] = swp;
    }
    qDebug() << "\033[36mThread:\033[0m" << "hex2Int16 data (after swap): " << data.toHex(' ');
    QDataStream ds(data);
    qint16 value; // Since the size you're trying to read appears to be 2 bytes
    ds >> value;
    qDebug() << "\033[36mThread:\033[0m" << "hex2Int16 int: " << value;

    return value;
}

quint16 MyThreadImu::str2UInt16(QByteArray data)
{
    /**
     * Calculate unsigned int value of hex
     *
     * @param   QByteArray data: 2 byte data whitch should convert to
     *      int bool little_endian: specify that data is in LITTLE
     *      ENDIAN form or BIG ENDIAN form
     *
     * @return  quint16: equivalent unsigned int
     *
     * @throws  --
     */

    quint16 num = 0;
    for (int i = 0; i <= 4; i++) {
        num += ((data[i]-48) * qPow(10, 4-i));
    }
    return num;
}
