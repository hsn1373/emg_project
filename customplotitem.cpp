#include "customplotitem.h"
#include <QDebug>
#include <iostream>
#include <fstream>
#include "client.h"
#include <QString>
#include <serialport.h>


bool CustomPlotItem::darkmode = false;
CustomPlotItem::CustomPlotItem( QQuickItem* parent ) : QQuickPaintedItem( parent )
  , m_CustomPlot( nullptr )
{
    //qDebug()<<"customplotitem started";
    setFlag( QQuickItem::ItemHasContents, true );
    // setRenderTarget(QQuickPaintedItem::FramebufferObject);
    // setAcceptHoverEvents(true);
    setAcceptedMouseButtons( Qt::AllButtons );

    connect( this, &QQuickPaintedItem::widthChanged, this, &CustomPlotItem::updateCustomPlotSize );
    connect( this, &QQuickPaintedItem::heightChanged, this, &CustomPlotItem::updateCustomPlotSize );

    //    connect(_timer, SIGNAL(timeout()), this, SLOT(plotWaiting()));
    //    _timer->start(1000);
    //qDebug()<<"customplotitem finished";
}

CustomPlotItem::~CustomPlotItem()
{
    //qDebug()<<"customplotitem destructor started";
    delete m_CustomPlot;
    m_CustomPlot = nullptr;

    delete _timer;
    //qDebug()<<"customplotitem destructor finished";
}

void CustomPlotItem::initCustomPlot()
{

    //qDebug()<<"initcustomplot started";
    m_CustomPlot = new QCustomPlot();

    updateCustomPlotSize();
    setupCustomPlot( m_CustomPlot );
    try {
        connect( m_CustomPlot, &QCustomPlot::afterReplot, this, &CustomPlotItem::onCustomReplot );
    } catch (exception e) {
        qDebug()<<"here";
    }

    connect( m_CustomPlot, &QCustomPlot::afterReplot, this, &CustomPlotItem::onCustomReplot );

    connect( m_CustomPlot, &QCustomPlot::afterReplot, this, &CustomPlotItem::onCustomReplot );


    m_CustomPlot->replot();

    //qDebug()<<"initcustomplot finished";

}


void CustomPlotItem::paint( QPainter* painter )
{
    //qDebug()<<"paint started";
    if (m_CustomPlot)
    {
        QPixmap    picture( boundingRect().size().toSize() );
        QCPPainter qcpPainter( &picture );

        //m_CustomPlot->replot();
        m_CustomPlot->toPainter( &qcpPainter );

        painter->drawPixmap( QPoint(), picture );
    }
    //qDebug()<<"paint finished";
}

bool CustomPlotItem::getAutoMove()
{
    //qDebug()<<"getAutomove started";
    //qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "getAutoMove()";
    //qDebug()<<"getAutomove started";
    return _auto_move;
}

void CustomPlotItem::setAutoMove(bool checked)
{
    //qDebug()<<"setAutomove started";
    if (_auto_move != checked) {
        qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "setAutoMove()";
        _auto_move = checked;
        emit autoMoveChanged();
        if(_auto_move){
            m_CustomPlot->setInteraction(QCP::iRangeDrag, false);
            m_CustomPlot->setInteraction(QCP::iRangeZoom, false);
        } else {
            m_CustomPlot->setInteraction(QCP::iRangeDrag, true);
            m_CustomPlot->setInteraction(QCP::iRangeZoom, true);
        }
    }
    //qDebug()<<"setAutomove started";
}

void CustomPlotItem::setReceivedDataPointer(QObject * SerialPortObj)
{
    //qDebug()<<"setReceiveDataPointer started";
    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "setReceivedDataPointer()";
    SerialPort *sp = qobject_cast<SerialPort *>(SerialPortObj);
    this->_received_data = &sp->_received_data[_channel_num];
    this->_lock_received_data = &sp->_lock_received_data;

    _sample_rate = sp->currentSpeed();
    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "_sample_rate:" << _sample_rate;
    //qDebug()<<"setReceiveDataPointer finished";
}

void CustomPlotItem::mousePressEvent( QMouseEvent* event )
{

    //    qDebug() << Q_FUNC_INFO;
    routeMouseEvents( event );
}

void CustomPlotItem::mouseReleaseEvent( QMouseEvent* event )
{
    //    qDebug() << Q_FUNC_INFO;
    routeMouseEvents( event );
}

void CustomPlotItem::mouseMoveEvent( QMouseEvent* event )
{
    //    qDebug() << Q_FUNC_INFO;
    routeMouseEvents( event );
}

void CustomPlotItem::mouseDoubleClickEvent( QMouseEvent* event )
{
    //    qDebug() << Q_FUNC_INFO;
    routeMouseEvents( event );
}

void CustomPlotItem::wheelEvent( QWheelEvent *event )
{
    //    qDebug() << Q_FUNC_INFO;
    routeWheelEvents( event );
}

void CustomPlotItem::graphClicked( QCPAbstractPlottable* plottable )
{
    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << Q_FUNC_INFO << QString( "Clicked on graph '%1 " ).arg( plottable->name() );
}

void CustomPlotItem::routeMouseEvents( QMouseEvent* event )
{
    if (m_CustomPlot)
    {
        QMouseEvent* newEvent = new QMouseEvent( event->type(), event->localPos(), event->button(), event->buttons(), event->modifiers() );
        //QCoreApplication::sendEvent( m_CustomPlot, newEvent );
        QCoreApplication::postEvent( m_CustomPlot, newEvent );
    }
}

void CustomPlotItem::routeWheelEvents( QWheelEvent* event )
{
    if (m_CustomPlot)
    {
        QWheelEvent* newEvent = new QWheelEvent( event->pos(), event->delta(), event->buttons(), event->modifiers(), event->orientation() );
        QCoreApplication::postEvent( m_CustomPlot, newEvent );
    }
}

void CustomPlotItem::updateCustomPlotSize()
{
    //qDebug()<<"updatecustomPlotsize started";
    if (m_CustomPlot)
    {
        m_CustomPlot->setGeometry( 0, 0, width(), height() );
    }
    //qDebug()<<"updatecustomPlotsize finished";
}

void CustomPlotItem::startPlot()
{
    //    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "startPlot()";
    _proccessing_index = 0;

    if (_timer->isActive()) {
        // Stop waiting timer
        //        qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "Stop waiting timer";
        _timer->stop();
        _timer->disconnect(SIGNAL(timeout()));
    }

    plotClear();

    _skip_len = 1;

    _timestamp = QDateTime::currentMSecsSinceEpoch();
    connect(_timer, SIGNAL(timeout()), this, SLOT(plotData()));
    _timer->start(0);
    //qDebug()<<"startplot finished";
}

void CustomPlotItem::stopPlot()
{
    //    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "stopPlot()";
    // Stop Plot Timer
    _timer->stop();
    _timer->disconnect(SIGNAL(timeout()));

    // Stop _skip_len timer
    _elpsd_timer.invalidate();

    _first_packet = true;

    //qDebug()<<"stopPlot finished";
}

void CustomPlotItem::speedChanged(quint32 speed)
{
    _sample_rate = speed;
    //    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "_sample_rate:" << _sample_rate;
}

bool CustomPlotItem::thereIsUnplottedData()
{
    /**
     *  Is there any unplotted data?
     *
     * @param   --
     *
     * @return  true:   If there is unplotted data
     *          false:  If all data were plotted
     *
     * @throws  --
     *
     */
    //qDebug()<<"thereIsUnplottedData started";

    //    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "_proccessing_index:" << _proccessing_index;
    _lock_received_data->lockForRead();
    //    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "_received_data.size():" << _received_data->size();
    // Skip some data
    if(_proccessing_index < _received_data->size()-(_sample_rate/2)){
        //        qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "Skip";
        _proccessing_index = _received_data->size()-(_sample_rate/4);
        _overtaking_flag = false;
    }
    //    qDebug() << "thereIsUnplottedData():" << (_proccessing_index < _received_data.size());
    bool result = _proccessing_index < _received_data->size();
    _lock_received_data->unlock();
    if(!_first_packet && !result){
        //        qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "_overtaking_flag";
        _overtaking_flag = true;
    }

    //qDebug()<<"thereIsUnplottedData finished";

    return result;
}

void CustomPlotItem::plotData() // sample_rate: number of samples per second
{

    //qDebug()<<"plotData started";


    //    QElapsedTimer elpsd_timer;

    //    if(_timestamp <= QDateTime::currentMSecsSinceEpoch()){
    if(thereIsUnplottedData()){
        //        _reverse_plot = 1;

        if(_first_packet){
            //            qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "first packet";
            _lock_received_data->lockForRead();
            _timestamp = QDateTime::currentMSecsSinceEpoch() - _received_data->size();
            _lock_received_data->unlock();

            _first_packet = false;
        } else {
            // calculate _skip_len

            //            qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m"  << "elapsed time:" << _elpsd_timer.elapsed();

            // alpha = zaman sarf shode bein do farakhani in tabe -> second
            qreal alpha = static_cast<qreal>(_elpsd_timer.elapsed())/static_cast<qreal>(1000);
            qreal T = static_cast<qreal>(1)/static_cast<qreal>(_sample_rate);
            //            qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m"  << "alpha:" << alpha;
            //            qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m"  << "T:" << T;
            _skip_len = qMax(1, qCeil(qSqrt(alpha/T)*2));
            //            qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m"  << "_skip_len:" << _skip_len;
        }
        // Start _skip_len timer
        _elpsd_timer.start();

        //        qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "_timestamp:" << _timestamp << "Time:" << QDateTime::currentMSecsSinceEpoch();


        //    qDebug() << "Value:" << value; //<< "\n";

        //    elpsd_timer.start();
        _lock_received_data->lockForRead();
        //    qDebug() << "Index:" << _proccessing_index;
        _last_plotted_data = _received_data->at(_proccessing_index);
        _lock_received_data->unlock();
        _proccessing_index += (_overtaking_flag ? _skip_len/2 : _skip_len);

        _timestamp++;

    } else {
        // Reverse plot

        //        qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "Get prev:" << _reverse_plot;
        //    qDebug() << "val:" << _proccessing_index - _reverse_plot;
        //    qDebug() << "cond1:" << (_proccessing_index - _reverse_plot > 0 ? "true" : "false");
        //    qDebug() << "cond2:" << (_proccessing_index - _reverse_plot < _received_data.size() ? "true" : "false");
        //        _lock_received_data->lockForRead();
        //        if (_proccessing_index - _reverse_plot > 0 && _proccessing_index - _reverse_plot < _received_data->size()){
        //            _last_plotted_data = _received_data->at(_proccessing_index - _reverse_plot++);
        //            //        qDebug() << "Get prev:" << _reverse_plot;
        //        }
        //        _lock_received_data->unlock();
    }

    m_CustomPlot->graph(0)->addData(time, _last_plotted_data);
    //            qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "_last_plotted_data:" << _last_plotted_data;
    //            qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "time:" << time;
    //    qDebug() << "***** Add data:"
    //             << static_cast<double>(elpsd_timer.nsecsElapsed())*qPow(10, -6)
    //             << "ms *****";

    // 0.5 millisecond for 2KHz
    //1 millisecond for 1KHz
    //    qDebug() << "proccessing_index / scale = "
    //             << static_cast<double>(proccessing_index-previous_proccessing_index) /
    //                static_cast<double>(sample_rate)
    //             << "\n";

    //    time += static_cast<double>(proccessing_index-previous_proccessing_index) /
    //            static_cast<double>(sample_rate);
    time += (static_cast<double>(1) /
             static_cast<double>(_sample_rate))*_skip_len;

    // Replot 30 FPS
    // Because replot is a time consuming process
    //                qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "time:" << time;
    //                qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "step:" << step;
    if(fabs(step - time) > 0.03333333)
    {
        if(_auto_move){
            m_CustomPlot->xAxis->setRange(qMax(time+1, static_cast<double>(HORIZONTAL_END_RANGE)), HORIZONTAL_END_RANGE, Qt::AlignRight);
            m_CustomPlot->yAxis->setRange(VERTICAL_BEGIN_RANGE, VERTICAL_END_RANGE);
        }

        //        elpsd_timer.start();
        m_CustomPlot->replot();
        //                    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "***** Replot:"
        //                             << static_cast<double>(elpsd_timer.nsecsElapsed())*qPow(10, -6)
        //                             << "ms *****";
        step = time;
    }
    //    }
    //qDebug()<<"plotData started";
}


//*********************************************************************************
//*********************************************************************************
void CustomPlotItem::plotOfflineData(QQueue<double> values, quint32 sample_rate)
{

    //    QVector<double> vals;
    //    QVector<double> keys;

    //    for(int i=1;i<values.length();i++)
    //    {
    //        qint16 value=values.at(i);
    //        quint32 processing_index=i;

    //        vals.push_back(value);
    //        keys.push_back(time);

    //        QElapsedTimer elpsd_timer;

    //        elpsd_timer.start();

    //        //m_CustomPlot->graph(0)->addData(time, value);

    //        time += static_cast<double>(1) /
    //                static_cast<double>(sample_rate);

    //        previous_proccessing_index = processing_index;
    //    }

    //    m_CustomPlot->graph(0)->addData(keys,vals,false);
    //    m_CustomPlot->replot();

    //qDebug()<<"plotOfflineData started";


    QPen pen;
    pen.setWidth(2);
    pen.setColor(darkmode ? QColor(0, 170, 0) : QColor(0,255,0));
    m_CustomPlot->graph(0)->setPen(pen);

    _offline_data.clear();
    time=0;
    _current_offline_data_index=0;
    _timer = new QTimer(this);
    _offline_data=values;
    _sample_rate=sample_rate;
    connect(_timer, SIGNAL(timeout()), this, SLOT(plotOfflineTimerTick()));
    _timer->start(0);

    //qDebug()<<"plotOfflineData finished";

}




void CustomPlotItem::plotOfflineTimerTick()
{
    //qDebug()<<"plotOfflineTimerTick started";

    int steps=_offline_data.length()/50;
    qint16 value=_offline_data.at(static_cast<int>(_current_offline_data_index));
    time += static_cast<double>(1) /
            static_cast<double>(_sample_rate);
    m_CustomPlot->graph(0)->addData(time, value);
    _current_offline_data_index++;

    //*****************************************
    // caculate Plot Ranges
    if(value>_max_range)
        _max_range=value;
    if(value<_min_range)
        _min_range=value;
    //*****************************************


    //qDebug() << _current_offline_data_index << "=" << _offline_data.length();
    if(static_cast<int>(_current_offline_data_index)>=_offline_data.length())
    {
        //qDebug() << "offline data size" << _current_offline_data_index;
        _timer->stop();
        //*****************************************
        // caculate Plot Ranges
        if(_min_range==0.0)
            _min_range=-(0.1*_max_range);
        //*****************************************
        m_CustomPlot->yAxis->setRange(1.5*_min_range,1.5*_max_range);
        //        m_CustomPlot->xAxis->ticker()->setTickCount(20);
        //        m_CustomPlot->graph(0)->setLineStyle((QCPGraph::LineStyle)0);
        //        m_CustomPlot->graph()->rescaleAxes(true);
        m_CustomPlot->replot();
        emit loadOfflineDataFinish();
    }
    if( static_cast<int>(_current_offline_data_index) % steps==0)
        emit increaseProgress();


}

void CustomPlotItem::plotFilteredData(QQueue<double> values, quint32 sample_rate,quint8 current_filter_index)
{
    //qDebug()<<"plotFilteredData started";

    _current_filter_index=current_filter_index;
    _max_range=0.0;
    _min_range=0.0;
    _offline_data.clear();
    time=0;
    _current_filtered_data_index=0;
    _timer = new QTimer(this);
    _filtered_data=values;
    _sample_rate=sample_rate;
    connect(_timer, SIGNAL(timeout()), this, SLOT(plotFilteredTimerTick()));
    _timer->start(0);

    //    m_CustomPlot->addGraph();

    QPen pen;
    pen.setWidth(2);
    pen.setColor(darkmode ? QColor(170,0,0):QColor(255,0,0));
    m_CustomPlot->graph(0)->setPen(pen);

    qDebug() << "pen color:" << "pen";

    //qDebug()<<"plotFilteredData finished";
}

void CustomPlotItem::plotFilteredTimerTick()
{
    //qDebug()<<"plotFilteredTimerTick started";

    int steps=_filtered_data.length()/50;
    double value=_filtered_data.at(static_cast<int>(_current_filtered_data_index));

    if(_current_filter_index==3||_current_filter_index==4||_current_filter_index==5)
    {
        // if rms & integral & mean absolute value
        time += static_cast<double>(1) /
                static_cast<double>(_sample_rate)*30;
    }
    else
    {
        time += static_cast<double>(1) /
                static_cast<double>(_sample_rate);
    }

    //*****************************************
    // caculate Plot Ranges
    if(value>_max_range)
        _max_range=value;
    if(value<_min_range)
        _min_range=value;
    //*****************************************

    m_CustomPlot->graph(0)->addData(time, value);
    _current_filtered_data_index++;

    if(static_cast<int>(_current_filtered_data_index)>=_filtered_data.length())
    {
        // if spectrum & power spectrum
        if(_current_filter_index==8||_current_filter_index==9)
        {
            m_CustomPlot->xAxis->setLabel("Frequency (Hz)");
            m_CustomPlot->yAxis->setLabel("spectrum");
        }

        //*****************************************
        // caculate Plot Ranges
        if(_min_range==0.0)
            _min_range=-(0.1*_max_range);
        //*****************************************
        _timer->stop();
        m_CustomPlot->yAxis->setRange(1.5*_min_range,1.5*_max_range);
        m_CustomPlot->replot();
        emit loadOfflineDataFinish();
    }
    if( static_cast<int>(_current_filtered_data_index) % steps==0)
        emit increaseProgress();

    //qDebug()<<"plotFilteredTimerTick started";
}



bool CustomPlotItem::slothdark()
{
    return darkmode;
}

void CustomPlotItem::writedark(int d)
{
    darkmode = darkmode ? false : true;
    emit signaldark();
}

//*********************************************************************************
//*********************************************************************************

void CustomPlotItem::plotWaiting()
{
    //qDebug()<<"plotwaiting started";
    static bool is_blink_on = false;


    if(is_blink_on){
        //qDebug("is_blink_on: true");
        plotClear();
        is_blink_on = false;
    }
    else {
        //qDebug("is_blink_on: false");
        for (double i = 1000; i < 9000; i+=0.01) {
            m_CustomPlot->graph(0)->addData(5, i);
        }
        is_blink_on = true;
    }
    m_CustomPlot->replot();
    //qDebug()<<"plotwaiting finished";
}

void CustomPlotItem::plotClear()
{
    //qDebug()<<"plotclear started";

    qDebug() << "\033[35mChannel" << _channel_num << ":\033[0m" << "plotClear()";
    m_CustomPlot->graph(0)->data()->clear();
    time = 0;
    if(_auto_move){
        m_CustomPlot->xAxis->setRange(HORIZONTAL_BEGIN_RANGE, HORIZONTAL_END_RANGE, Qt::AlignLeft);
        m_CustomPlot->yAxis->setRange(VERTICAL_BEGIN_RANGE, VERTICAL_END_RANGE);
    }
    m_CustomPlot->replot();
    //qDebug()<<"plotclear finished";
}

void CustomPlotItem::onCustomReplot()
{
    //qDebug()<<"onCustomPlot started";
    //    qDebug() << Q_FUNC_INFO;
    update();
    //qDebug()<<"onCustomPlot finished";
}


void CustomPlotItem::setupCustomPlot(QCustomPlot *customPlot)
{
    qDebug()<<"in cpp customPlot";
    customPlot->addGraph();
    // Set x & y label
//    customPlot->xAxis->setLabel("Time");
//    customPlot->yAxis->setLabel("Raw Signal");
    // Set x & y range
    customPlot->xAxis->setRange(HORIZONTAL_BEGIN_RANGE, HORIZONTAL_END_RANGE);
    customPlot->yAxis->setRange(VERTICAL_BEGIN_RANGE, VERTICAL_END_RANGE);
    // Set x & y label color
    //    customPlot->xAxis->setLabelColor( Qt::white );
    //    customPlot->yAxis->setLabelColor( Qt::white );
    // Set x & y number precision?!
    customPlot->xAxis->setNumberPrecision(500);
    customPlot->yAxis->setNumberPrecision(500);
    // Set x & y base pen
    //    customPlot->xAxis->setBasePen( QPen(Qt::white) );
    //    customPlot->yAxis->setBasePen( QPen(Qt::white) );
    //    customPlot->yAxis2->setBasePen(QPen(QColor(255,255,255)));
    // Set x & y tick label color
    //    customPlot->xAxis->setTickLabelColor( Qt::white );
    //    customPlot->yAxis->setTickLabelColor( Qt::white );
    // Set x & y sub tick pen
    //    customPlot->xAxis->setSubTickPen( QPen(Qt::white) );
    //    customPlot->yAxis->setSubTickPen( QPen(Qt::white) );
    // Set x & y tick pen
    //    customPlot->xAxis->setTickPen( QPen(Qt::white) );
    //    customPlot->yAxis->setTickPen( QPen(Qt::white) );
    // Set the shape and thickness of scatter
    customPlot->graph(0)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssDot, 500));
    // Set interaction
    customPlot ->setInteractions( QCP::iRangeDrag | QCP::iRangeZoom );
    // Set draw line pen color
    customPlot->graph(0)->setPen(darkmode ? QColor(0, 170, 0) : QColor(0,255,0));


    // Set NotAntialiasedElements: used for higher performance
    //(see QCustomPlot real time example)
    customPlot->setNotAntialiasedElements(QCP::aeAll);
    customPlot->setNoAntialiasingOnDrag(true);

    QColor color , background;
    background = QColor("transparent");
    color = darkmode ? QColor(30,33,38) : QColor(255,255,255);


    // Background for the plot area
    customPlot->setBackground(QBrush(background)); // change background color



    // x axis colors
    customPlot->xAxis->setTickLabelColor(color); // change x axis numbers
    customPlot->xAxis->setLabelColor(color); // change x axis label
    customPlot->xAxis->setBasePen( QPen(color) );
    customPlot->xAxis2->setBasePen(QPen(color));
    customPlot->xAxis->setSubTickPen( QPen(color) );
    customPlot->xAxis2->setSubTickPen( QPen(color) );
    customPlot->xAxis->setTickPen( QPen(color) );
    customPlot->xAxis2->setTickPen( QPen(color) );

    // y axis colors
    customPlot->yAxis->setTickLabelColor(color); // change y axis number
    customPlot->yAxis->setLabelColor(color); // change y axis label
    customPlot->yAxis->setBasePen( QPen(color) );
    customPlot->yAxis2->setBasePen(QPen(color));
    customPlot->yAxis->setSubTickPen( QPen(color) );
    customPlot->yAxis2->setSubTickPen( QPen(color) );
    customPlot->yAxis->setTickPen( QPen(color) );
    customPlot->yAxis2->setTickPen( QPen(color) );



    customPlot->xAxis->grid()->setSubGridVisible(true);

    //    customPlot->yAxis->setAutoTickStep(true);                                // For Manual Changing

    // Time as label for xAxis
    QSharedPointer<QCPAxisTickerTime> timeTicker(new QCPAxisTickerTime);
    timeTicker->setTimeFormat("%h:%m:%s");
    customPlot->xAxis->setTicker(timeTicker);
    customPlot->axisRect()->setupFullAxesBox();

    connect( customPlot, SIGNAL( plottableClick( QCPAbstractPlottable*, int, QMouseEvent* ) ), this, SLOT( graphClicked( QCPAbstractPlottable* ) ) );
}


