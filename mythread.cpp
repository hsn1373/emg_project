#include "mythread.h"

MyThread::MyThread(QList<QQueue<qint16>> *_received_data, QString *_last_filename, QReadWriteLock *_lock_received_data, QObject *parent) : QObject(parent)
{
    this->_received_data = _received_data;
    this->_last_filename = _last_filename;
    this->_lock_received_data = _lock_received_data;
}

void MyThread::dataReceiver(QByteArray data)
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
    //    std::cout<<std::string(data)<<std::endl;
    //    qDebug() << "\033[36mThread:\033[0m" << "Start dataReceiver...";

    if (data.size()){
        // Read all incoming bytes
        //        qDebug() << "\033[36mThread:\033[0m" << "data size:" << data.size();
        //                qDebug() << "\033[36mThread:\033[0m" << data.toHex(' ');
        // Prepend remaining data
        //        qDebug() << "\033[36mThread:\033[0m" << "Remaining data:" << _remaining_data.toHex(' ');
        data.prepend(_remaining_data);
        //                qDebug() << "\033[36mThread:\033[0m" << "Whole data:" << data.toHex(' ');
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
            for (int j = 0; j < PACKET_LEN - START_SPECIFIER_LEN; j += VALUE_LEN) {
                Value = hex2UInt16(data.mid(i + START_SPECIFIER_LEN + j, VALUE_LEN));
                //filter
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

void MyThread::writeSerialData(QString _selected_file_for_save, QString _selected_file_for_save_extention,QList<QVariant> channels)
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


    QList<int> active_channels;
    for (int i=0;i<channels.size();i++) {
        if(channels.at(i).toBool())
            active_channels.push_back(i);
    }

    _selected_file_for_save.remove(0,7);
    if(QSysInfo::productType()=="windows")
        _selected_file_for_save.remove(0,1);


    if(_selected_file_for_save_extention=="Text files (*.txt)"|| _selected_file_for_save_extention=="Csv Files (*.csv)")
    {
        QFile file(_selected_file_for_save);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            qDebug() << "Can not open file!";
        QTextStream out(&file);

        //qDebug()<<"hjfgvsdfvsafvsajgfbaj";
        //----write FRL in binary at the beginning of the file----//
        out << "010001100101001001001100\n";
        //--------------------------------------------------------//
        //******************************-******
        // write active channels to begin line
        for(int j=0;j<active_channels.size();j++)
        {
            if(j+1==active_channels.size())
                out << active_channels.at(j)+1;
            else
                out << active_channels.at(j)+1 << ",";
        }
        out << "\n";
        //*************************************


        _lock_received_data->lockForRead();
        for (int i = 0; i < _received_data->at(0).size(); i++) {
            for(int j=0;j<active_channels.size();j++)
            {
                if(j+1==active_channels.size())
                    out << _received_data->at(active_channels.at(j)).at(i);
                else
                    out << _received_data->at(active_channels.at(j)).at(i) << ",";
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

        //write FRL in binary at the beginning of the file
        xlsx.write("A"+QString::number(1),"01000110");
        xlsx.write("B"+QString::number(1),"01010010");
        xlsx.write("C"+QString::number(1),"01001100");
        //----------------------------------------------------//
        //******************************-******
        // write active channels to begin line
        for(int j=0;j<active_channels.size();j++)
        {
            xlsx.write(Letters.at(j)+QString::number(2), active_channels.at(j)+1);
        }
        //*************************************

        for (int i = 0; i < _received_data->at(0).size(); i++) {
            for(int j=0;j<active_channels.size();j++)
            {
                xlsx.write(Letters.at(j)+QString::number(i+3), _received_data->at(active_channels.at(j)).at(i));
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

        pa1 = mxCreateDoubleMatrix(sizeOfArray,active_channels.size(),mxREAL);
        if (pa1 == NULL) {
        }

        double *data = mxGetPr(pa1);
        for(int i=0;i<active_channels.size();i++)
        {
            for (int k=0;k<sizeOfArray;k++) {
                *data=_received_data->at(active_channels.size()).at(k);
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

void MyThread::portClosed()
{
    qDebug() << "\033[36mThread:\033[0m" << "portClosed slot.";
    _remaining_data.clear();
}

//void MyThread::speedChanged(quint8 current_index)
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

quint16 MyThread::hex2UInt16(QByteArray data, bool little_endian)
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
