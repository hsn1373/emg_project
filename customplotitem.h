#ifndef CUSTOMPLOTITEM_H
#define CUSTOMPLOTITEM_H

#pragma once

#include <QtQuick>
#include <QDateTime>
#include <QtMath>
#include <QReadWriteLock>
#include <QElapsedTimer>
#include "qcustomplot.h"
#include "serialport.h"
#include "QObject"

#define HORIZONTAL_BEGIN_RANGE 0
#define HORIZONTAL_END_RANGE 10
#define VERTICAL_BEGIN_RANGE -69999
#define VERTICAL_END_RANGE 69999

class QCustomPlot;

class CustomPlotItem : public QQuickPaintedItem
{
    Q_OBJECT

    Q_PROPERTY(bool auto_move READ getAutoMove WRITE setAutoMove NOTIFY autoMoveChanged)
    Q_PROPERTY(QString type MEMBER _m_type)
    Q_PROPERTY(int channel_num MEMBER _channel_num)
    Q_PROPERTY(int slothdark READ slothdark WRITE writedark NOTIFY signaldark) // dark theme (backgroundColor)

private:
    QCustomPlot*    m_CustomPlot;
    double          time=0;
    double          step=0;
    bool            _auto_move = false;
    // bool            darkmode = false;

    quint8 _channel_num = 0;
    quint16 _skip_len = 1;
    bool _overtaking_flag = false;

    QQueue<qint16> *_received_data;
    QReadWriteLock *_lock_received_data;

    QTimer *_timer = new QTimer(this);
    qint64 _timestamp;
    QElapsedTimer _elpsd_timer;
    bool _first_packet = true;
    // ReceivedData
    quint32 _proccessing_index = 0;
//    quint32 _reverse_plot = 1;
    qint16 _last_plotted_data = 0;

    quint64 _current_offline_data_index;
    quint64 _current_filtered_data_index;
    QQueue<double> _offline_data;
    QQueue<double> _filtered_data;
    double _max_range,_min_range;
    quint8 _current_filter_index;

    quint32 _sample_rate;

    QString _m_type;

protected:
    void routeMouseEvents( QMouseEvent* event );
    void routeWheelEvents( QWheelEvent* event );

    virtual void mousePressEvent( QMouseEvent* event );
    virtual void mouseReleaseEvent( QMouseEvent* event );
    virtual void mouseMoveEvent( QMouseEvent* event );
    virtual void mouseDoubleClickEvent( QMouseEvent* event );
    virtual void wheelEvent( QWheelEvent *event );


    void setupCustomPlot( QCustomPlot* customPlot );

public:
    static bool darkmode;
    CustomPlotItem( QQuickItem* parent = 0 );
    virtual ~CustomPlotItem();

    void paint( QPainter* painter );

    bool getAutoMove();
    void setAutoMove(bool checked);


    Q_INVOKABLE void initCustomPlot();
    Q_INVOKABLE void plotOfflineData(QQueue<double> values,quint32 sample_rate);
    Q_INVOKABLE void plotFilteredData(QQueue<double> values,quint32 sample_rate,quint8 current_filter_index);
    Q_INVOKABLE void setReceivedDataPointer(QObject *);

signals:
    void autoMoveChanged();
    void increaseProgress();
    void loadOfflineDataFinish();
    void signaldark();


public slots:
    void graphClicked( QCPAbstractPlottable* plottable );
    void onCustomReplot();
    void updateCustomPlotSize();
    void plotWaiting();
    void plotClear();
    void plotData();
    void startPlot();
    void stopPlot();
    void speedChanged(quint32 speed);
    bool thereIsUnplottedData();
    void plotOfflineTimerTick();
    void plotFilteredTimerTick();
    bool slothdark();
    void writedark(int d);

};

#endif // CUSTOMPLOTITEM_H
