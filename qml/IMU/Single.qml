import QtQuick 2.12
import QtQuick.Controls 2.3 as QQC2
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import DefaultSettings 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Shapes 1.12 as SHAPE

//---- imports added in IMU version ----//
import QtQuick.Window 2.12
import QtQuick.Controls.Styles 1.0
import QtQuick.Dialogs 1.0
import QtGraphicalEffects 1.10
import QtQml.Models 2.1
import SerialPortImu 1.0
import CustomPlot 1.0
import QtCharts 2.3
//------------------------------------//



import "../Style"

//*****************************************
// Online Page
//*****************************************
Item {
    id: online
    readonly property string _select_device_str: "Select Device..."
    readonly property string _file_write_done_str: "Write to file done!"

    property bool _port_open: false
    property bool _writing_file: false

    // background
    SHAPE.Shape {
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        SHAPE.ShapePath {
            fillGradient: SHAPE.LinearGradient {
                x1: 0; y1: 0
                x2: window.width; y2: window.height
                GradientStop { position: 0.3; color: UIStyle.shapeColor1 }
                GradientStop { position: 0.7; color: UIStyle.shapeColor2 }
            }
            PathArc {
                x: 0 ; y: window.height
                radiusX: window.width ; radiusY: window.height
                useLargeArc: true
            }
        }
    }

    SerialPortImu {
        id: serialPort
        onPlotData: {
            //            if(this.thereIsUnplottedData()){
            //                if(this.is1KHz()){
            //                    // 0.001 = 1 millisecond
            //                    customPlot.plotData(this.next_data, this.proccessing_index, this.currentSpeed())
            //                } else if(this.is2KHz()){
            //                    // 0.0005 = 0.5 millisecond
            //                    customPlot.plotData(this.next_data, this.proccessing_index, this.currentSpeed())
            //                    customPlot.plotData(this.next_data, this.proccessing_index, this.currentSpeed())
            //                }
            //            } else {
            //                if(this.is1KHz()){
            //                    // 0.001 = 1 millisecond
            //                    customPlot.plotData(this.prev_data, this.proccessing_index, this.currentSpeed())
            //                } else if(this.is2KHz()){
            //                    // 0.0005 = 0.5 millisecond
            //                    customPlot.plotData(this.prev_data, this.proccessing_index, this.currentSpeed())
            //                    customPlot.plotData(this.prev_data, this.proccessing_index, this.currentSpeed())
            //                }
            //            }
        }
        onPlotOfflineData: {

            var offlineCustomPlotObjects=
                    [offlineCustomPlot1,offlineCustomPlot2,offlineCustomPlot3,offlineCustomPlot4,
                     offlineCustomPlot5,offlineCustomPlot6,offlineCustomPlot7,offlineCustomPlot8,
                     offlineCustomPlot9,offlineCustomPlot10,offlineCustomPlot11,offlineCustomPlot12,
                     offlineCustomPlot13,offlineCustomPlot14,offlineCustomPlot15,offlineCustomPlot16]

            for(var i=0;i<16;i++)
            {
                offlineCustomPlotObjects[i].plotClear()
                current_channel=i
                offlineCustomPlotObjects[i].plotOfflineData(multichannel_offline_data, this.currentSpeed())

            }
        }

        onPlotFilteredData: {
            //            current_channel=0
            //                        if(cmbselectchannel.currentIndex==0)
            //                        {
            //                            //serialPort.current_channel=cmbselectchannel.currentIndex
            //                            offlineCustomPlot1.plotClear()
            //                            offlineCustomPlot1.plotFilteredData(multichannel_filtered_data,this.currentSpeed(),cmbfilter.currentIndex)
            //                        }
            var offlineCustomPlotObjects=
                    [offlineCustomPlot1,offlineCustomPlot2,offlineCustomPlot3,offlineCustomPlot4,
                     offlineCustomPlot5,offlineCustomPlot6,offlineCustomPlot7,offlineCustomPlot8,
                     offlineCustomPlot9,offlineCustomPlot10,offlineCustomPlot11,offlineCustomPlot12,
                     offlineCustomPlot13,offlineCustomPlot14,offlineCustomPlot15,offlineCustomPlot16]
            var offlineCustomPlotObjects2=[]
            var channelCheckboxObjects=
                    [channel1checkbox,channel2checkbox,channel3checkbox,channel4checkbox,
                     channel5checkbox,channel6checkbox,channel7checkbox,channel8checkbox,
                     channel9checkbox,channel10checkbox,channel11checkbox,channel12checkbox,
                     channel13checkbox,channel14checkbox,channel15checkbox,channel16checkbox]
            var choosedChannels=[]
            for(var i=0;i<16;i++)
            {
                if(channelCheckboxObjects[i].checked==true)
                {
                    offlineCustomPlotObjects2.push(offlineCustomPlotObjects[i])
                    choosedChannels.push(i)
                }
            }

            for(i=0;i<offlineCustomPlotObjects2.length;i++)
            {
                current_channel=choosedChannels[i]
                offlineCustomPlotObjects2[i].plotClear()
                offlineCustomPlotObjects2[i].plotFilteredData(multichannel_filtered_data,this.currentSpeed(),cmbfilter.currentIndex)
            }




            //            var offlineCustomPlotObjects=
            //                    [offlineCustomPlot1,offlineCustomPlot2,offlineCustomPlot3,offlineCustomPlot4,
            //                     offlineCustomPlot5,offlineCustomPlot6,offlineCustomPlot7,offlineCustomPlot8,
            //                     offlineCustomPlot9,offlineCustomPlot10,offlineCustomPlot11,offlineCustomPlot12,
            //                     offlineCustomPlot13,offlineCustomPlot14,offlineCustomPlot15,offlineCustomPlot16]

            //            for(var i=0;i<16;i++)
            //            {
            //                if(cmbselectchannel.currentIndex==i)
            //                {
            //                    offlineCustomPlotObjects[i].plotClear()
            //                    offlineCustomPlotObjects[i].plotFilteredData(multichannel_filtered_data,this.currentSpeed(),cmbfilter.currentIndex)
            //                }

            //            }
        }
        onViewResultPopup:
        {
            viewResultPopupText.text="<font color=\"#616161\">" + resultForPopup() + "</font>"
            writeFilePopup.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
            viewResultPopup.open()
        }

        //        onWaiting4Connection: {
        //            customPlot.plotWaiting()
        //        }
        //        onClearPlot: {
        //            customPlot.plotClear()
        //        }
        onWriteFileDone: {
            writeFilePopupText.text = "<font color=\"#616161\">File name: </font>" + lastFilename()
            writeFilePopup.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
            _writing_file = false
        }
        onPortOpenSignal: {
            for (var i=0; i < itemModel.children.length; ++i)
                if(itemModel.children[i].type==="CustomPlotItem"){
                    itemModel.children[i].startPlot()
                    console.log(itemModel.children[i].type, i)
                }
            _port_open = true
            barTimer.start()
        }
        onPortCloseSignal: {
            for (var i=0; i < itemModel.children.length; ++i)
                if(itemModel.children[i].type==="CustomPlotItem"){
                    itemModel.children[i].stopPlot()
                    //                    console.log(itemModel.children[i].type, i)
                }
            _port_open = false
            barTimer.stop()
        }
        onIncreaseProgress:{
            readFileProgress.value += 16
            readFileProgressText.text = readFileProgress.value * 2/16 + "%"
        }
        onSignalProcessingFinish:{
            readFileProgressGrid.visible=false
            readFileProgress.value = 0
        }
    }

    // body
    Grid {
        anchors.fill: parent
        rows: 3
        spacing: 5
        padding: 5

        Row{
            id: emptyBar
            width: parent.width
            height: parent.height * 1/35
        }

        Row {
            id: onlineRow1
            spacing: 5
            width: parent.width
            //height: 50
            height: parent.height*1/10

            ComboBox {
                id: deviceComboBox
                width: 400
                //                currentIndex: -1
                //                displayText: currentIndex === -1 ? "Select Device..." : currentText
                displayText: _select_device_str
                model: serialPort.serial_ports_list
                onActivated: {
                    this.displayText = this.currentText
                    serialPort.deviceChanged(currentIndex)
                    //                            autoMoveCheckBox.checked = true
                    //                            // Set all plot auto_move
                    //                            for (var i=0; i < itemModel.children.length; ++i)
                    //                                if(itemModel.children[i].type==="CustomPlotItem"){
                    //                                    itemModel.children[i].auto_move = true
                    //                                }
                    //                            serialPort.deviceChanged(currentIndex)
                }
            }
            ComboBox {
                id: deviceComboBox1
                width: 400
                //                currentIndex: -1
                //                displayText: currentIndex === -1 ? "Select Device..." : currentText
                displayText: _select_device_str
                model: serialPort.serial_ports_list
                onActivated: {
                    this.displayText = this.currentText
                    serialPort.deviceChanged1(currentIndex)
                    //                            autoMoveCheckBox.checked = true
                    //                            // Set all plot auto_move
                    //                            for (var i=0; i < itemModel.children.length; ++i)
                    //                                if(itemModel.children[i].type==="CustomPlotItem"){
                    //                                    itemModel.children[i].auto_move = true
                    //                                }
                    //                            serialPort.deviceChanged(currentIndex)
                }
            }

            Button {
                text: 'Refresh'
                onClicked: {
                    serialPort.refreshDevices()
                    deviceComboBox.displayText = _select_device_str
                    deviceComboBox1.displayText = _select_device_str
                }
            }

            //                    ComboBox {
            //                        model: serialPort.baud_rate_list
            //                        onActivated: serialPort.baudRateChanged(currentIndex)
            //                    }

            //                    ComboBox {
            //                        model: serialPort.speed_list
            //                        onActivated: {
            //                            serialPort.speedChanged(currentIndex)
            //                            for (var i=0; i < itemModel.children.length; ++i)
            //                                if(itemModel.children[i].type==="CustomPlotItem"){
            //                                    itemModel.children[i].speedChanged(serialPort.currentSpeed())
            //                                }
            //                        }
            //                    }

            //                    Label {
            //                        height: parent.height
            //                        verticalAlignment: Text.AlignVCenter
            //                        text: qsTr("Port:")
            //                    }

            Button {
                text: 'start'
                highlighted: true
                onClicked: {
                    autoMoveCheckBox.checked = true
                    // Set all plot auto_move
                    for (var i=0; i < itemModel.children.length; ++i)
                        if(itemModel.children[i].type==="CustomPlotItem"){
                            itemModel.children[i].auto_move = true
                        }
                    serialPort.openPort()
                    barTimer.start()
                }
            }

            Button {
                text: 'close'
                highlighted: true
                onClicked: {

                    autoMoveCheckBox.checked = false
                    // Set all plot auto_move
                    for (var i=0; i < itemModel.children.length; ++i)
                        if(itemModel.children[i].type==="CustomPlotItem"){
                            itemModel.children[i].auto_move = false
                        }

                    writeFilePopup.closePolicy = Popup.NoAutoClose
                    _writing_file = true
                    if (_port_open)
                        writeFilePopup.open()
                    serialPort.closePort()
                    saveFileDialog.open()
                    barTimer.stop()
                }
            }

            CheckBox {
                id: autoMoveCheckBox
                text: qsTr("Auto move")
                Material.accent: Material.primary
                onClicked: {
                    // Set all plot auto_move
                    for (var i=0; i < itemModel.children.length; ++i)
                        if(itemModel.children[i].type==="CustomPlotItem"){
                            itemModel.children[i].auto_move = checked
                        }
                }
                Component.onCompleted: checked = customPlot.auto_move
//                Connections {
//                    target: customPlot
//                    onStatusChanged: autoMoveCheckBox.checked = customPlot.auto_move
//                }
            }
            Button {
                text: 'Save as'
                highlighted: true
                onClicked: {
                    writeFilePopup.closePolicy = Popup.NoAutoClose
                    _writing_file = true
                    writeFilePopup.open()
                    saveFileDialog.open()
                }
            }
        }

        Row {
            id: onlineRow2
            width: parent.width
            //height: online.height - onlineRow1.height - 10
            height: parent.height*9/10

            ObjectModel {
                id: itemModel
                CustomPlotItem {
                    id: customPlot
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    channel_num: 0
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: customPlot1
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    channel_num: 1
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: customPlot2
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    channel_num: 2
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: customPlot3
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    channel_num: 3
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: customPlot4
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    channel_num: 4
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: customPlot5
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    //                            anchors.left: customPlot.left
                    //                            anchors.top: customPlot4.bottom
                    channel_num: 5
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: customPlot6
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    //                            anchors.left: customPlot.left
                    //                            anchors.top: customPlot5.bottom
                    channel_num: 6
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: customPlot7
                    width: online.width/2 - 12.5
                    height: onlineRow2.height / 4
                    //                            anchors.left: customPlot.left
                    //                            anchors.top: customPlot6.bottom
                    channel_num: 7
                    type: "CustomPlotItem"
                    Component.onCompleted: {
                        setReceivedDataPointer(serialPort)
                        initCustomPlot()
                    }
                }
                //                        CustomPlotItem {
                //                            id: customPlot8
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot.right
                //                            anchors.top: customPlot.top
                //                            channel_num: 8
                //                            type: "CustomPlotItem"
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
                //                        CustomPlotItem {
                //                            id: customPlot9
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot1.right
                //                            anchors.top: customPlot1.top
                //                            channel_num: 9
                //                            type: "CustomPlotItem"
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
                //                        CustomPlotItem {
                //                            id: customPlot10
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot2.right
                //                            anchors.top: customPlot2.top
                //                            channel_num: 10
                //                            type: "CustomPlotItem"
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
                //                        CustomPlotItem {
                //                            id: customPlot11
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot3.right
                //                            anchors.top: customPlot3.top
                //                            channel_num: 11
                //                            type: "CustomPlotItem"
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
                //                        CustomPlotItem {
                //                            id: customPlot12
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot4.right
                //                            anchors.top: customPlot4.top
                //                            channel_num: 12
                //                            type: "CustomPlotItem"
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
                //                        CustomPlotItem {
                //                            id: customPlot13
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot5.right
                //                            anchors.top: customPlot5.top
                //                            channel_num: 13
                //                            type: "CustomPlotItem"
                //                            visible: false
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
                //                        CustomPlotItem {
                //                            id: customPlot14
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot6.right
                //                            anchors.top: customPlot6.top
                //                            channel_num: 14
                //                            type: "CustomPlotItem"
                //                            visible: false
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
                //                        CustomPlotItem {
                //                            id: customPlot15
                //                            width: online.width/2 - 12.5
                //                            height: onlineRow2.height / 4
                //                            anchors.left: customPlot7.right
                //                            anchors.top: customPlot7.top
                //                            channel_num: 15
                //                            type: "CustomPlotItem"
                //                            visible: false
                //                            Component.onCompleted: {
                //                                setReceivedDataPointer(serialPort)
                //                                initCustomPlot()
                //                            }
                //                        }
            }

            ObjectModel {
                id: chartModel
                ChartView {
                    id: chart
                    width: onlineRow2.width / 2 - 16
                    height: onlineRow2.height / 4
                    legend.visible: false
                    antialiasing: true
                    backgroundColor: 'transparent'

                    //                            animationOptions: ChartView.SeriesAnimations

                    BarSeries {
                        id: barSeries

                        axisX: BarCategoryAxis {
                            categories: ["Angle 1", "Angle 2", "Angle 3"]
                            color: UIStyle.darkTheme ?  'black' :'white'
                            labelsColor: UIStyle.darkTheme ?  'black' :'white'
                        }
                        axisY: ValueAxis {    //  <- custom ValueAxis attached to the y-axis
                            id: valueAxis
                            max: 180
                            min: -180
                            color: UIStyle.darkTheme ?  'black' :'white'
                            labelsColor: UIStyle.darkTheme ?  'black' :'white'
                        }
                        labelsVisible: true
                        BarSet { values: [0, 0, 0];color: UIStyle.darkTheme ?  'black' :'white' }
                    }
                }

                ChartView {

                    id: chart1
                    width: onlineRow2.width / 2 - 16
                    height: onlineRow2.height / 4
                    legend.visible: false
                    antialiasing: true
                    backgroundColor: 'transparent'
                    //                            animationOptions: ChartView.SeriesAnimations

                    BarSeries {
                        id: barSeries1
                        axisX: BarCategoryAxis { categories: ["Angle 1", "Angle 2", "Angle 3"] }
                        axisY: ValueAxis {    //  <- custom ValueAxis attached to the y-axis
                            id: valueAxis1
                            max: 180
                            min: -180
                        }
                        labelsVisible: true
                        BarSet { values: [0, 0, 0] }
                    }
                }

                ChartView {

                    id: chart2
                    width: onlineRow2.width / 2 - 16
                    height: onlineRow2.height / 4
                    legend.visible: false
                    antialiasing: true
                    backgroundColor: 'transparent'
                    //                            animationOptions: ChartView.SeriesAnimations

                    BarSeries {
                        id: barSeries2
                        axisX: BarCategoryAxis { categories: ["Angle 1", "Angle 2", "Angle 3"] }
                        axisY: ValueAxis {    //  <- custom ValueAxis attached to the y-axis
                            id: valueAxis2
                            max: 180
                            min: -180
                        }
                        labelsVisible: true
                        BarSet { values: [0, 0, 0] }
                    }
                }

                ChartView {

                    id: chart3
                    width: onlineRow2.width / 2 - 16
                    height: onlineRow2.height / 4
                    legend.visible: false
                    antialiasing: true
                    backgroundColor: 'transparent'
                    //                            animationOptions: ChartView.SeriesAnimations

                    BarSeries {
                        id: barSeries3
                        axisX: BarCategoryAxis { categories: ["Angle 1", "Angle 2", "Angle 3"] }
                        axisY: ValueAxis {    //  <- custom ValueAxis attached to the y-axis
                            id: valueAxis3
                            max: 180
                            min: -180
                        }
                        labelsVisible: true
                        BarSet { values: [0, 0, 0] }
                    }
                }

                ChartView {

                    id: chart4
                    width: onlineRow2.width / 2 - 16
                    height: onlineRow2.height / 4
                    legend.visible: false
                    antialiasing: true
                    backgroundColor: 'transparent'
                    //                            animationOptions: ChartView.SeriesAnimations

                    BarSeries {
                        id: barSeries4
                        axisX: BarCategoryAxis { categories: ["Angle 1", "Angle 2", "Angle 3"] }
                        axisY: ValueAxis {    //  <- custom ValueAxis attached to the y-axis
                            id: valueAxis4
                            max: 180
                            min: -180
                        }
                        labelsVisible: true
                        BarSet { values: [0, 0, 0] }
                    }
                }
            }

            ListView {
                id: onlinePlotListView
                width: parent.width / 2 - 8
                //height: online.height - onlineRow1.height - 10
                height: parent.height
                model: itemModel
                clip: true
                interactive: false
                ScrollBar.vertical: ScrollBar{
                    position: 1.0
                    policy: ScrollBar.AlwaysOn
                    snapMode: ScrollBar.SnapAlways
                }
            }

            Timer {
                id: barTimer
                interval: 33;
                repeat: true
                onTriggered: {
                    var angles = serialPort.imuAngles()
                    barSeries.at(0).values = angles.slice(0, 3)
                    //                            valueAxis.max = Math.max(...barSeries.at(0).values)
                    barSeries1.at(0).values = angles.slice(3, 6)
                    //                            valueAxis1.max = Math.max(...barSeries1.at(0).values)
                    barSeries2.at(0).values = angles.slice(6, 9)
                    //                            valueAxis2.max = Math.max(...barSeries2.at(0).values)
                    barSeries3.at(0).values = angles.slice(9, 12)
                    //                            valueAxis3.max = Math.max(...barSeries3.at(0).values)
                    barSeries4.at(0).values = angles.slice(12, 15)
                    //                            valueAxis4.max = Math.max(...barSeries4.at(0).values)
                }
            }

            ListView {
                width: parent.width / 2 - 8
                height: parent.height
                clip: true
                interactive: false
                ScrollBar.vertical: ScrollBar{
                    position: 1.0
                    policy: ScrollBar.AlwaysOn
                    snapMode: ScrollBar.SnapAlways
                }
                model: chartModel
            }
        }
    }
    Popup {
        id: writeFilePopup
        anchors.centerIn: Overlay.overlay
        //        width: 100
        //        height: 100
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose // change closePolicy when write done

        ColumnLayout {
            anchors.fill: parent

            BusyIndicator {
                id: writeFilePopupBusyIndicator
                running: _writing_file
                visible: _writing_file
            }

            CheckBox {
                id: writeFilePopupCheckbox
                Layout.alignment: Qt.AlignHCenter
                visible: !_writing_file
                text: qsTr(_file_write_done_str)
                checked: true
                Material.accent: Material.Green
                onClicked: checked=true
            }

            Text {
                id: writeFilePopupText
                visible: !_writing_file
                text: qsTr("File name:")
            }

            Button {
                id: writeFilePopupButton
                Layout.alignment: Qt.AlignHCenter
                visible: !_writing_file
                text: 'OK'
                Material.background: Material.Green
                //                Material.foreground: "white"
                highlighted: true
                onClicked: {
                    writeFilePopup.close()
                }
            }
        }
    }


    FileDialog {
        id: saveFileDialog
        title: "save file"
        nameFilters: ["Text files (*.txt)","Csv Files (*.csv)","Xlsx Files (*.xlsx)","Matlab Files (*.mat)"]
        selectExisting: false
        //                folder: shortcuts.documents
        onAccepted: {
            console.log("You chose: " + saveFileDialog.fileUrl)
            console.log("You chose: " + saveFileDialog.selectedNameFilter)
            serialPort.selected_file_for_save=saveFileDialog.fileUrl
            serialPort.selected_file_for_save_extention=saveFileDialog.selectedNameFilter
            serialPort.callDoWriteFile()
        }
        onRejected: {
            writeFilePopup.close()
        }
        Component.onCompleted: visible = false
    }
    Popup {
        id: viewResultPopup
        anchors.centerIn: Overlay.overlay
        //        width: 100
        //        height: 100
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose // change closePolicy when write done

        ColumnLayout {
            anchors.fill: parent

            Text {
                id: viewResultPopupText
                text: qsTr("")
            }

            Button {
                id: viewResultPopupButton
                Layout.alignment: Qt.AlignHCenter
                text: 'OK'
                Material.background: Material.Green
                highlighted: true
                onClicked: {
                    viewResultPopup.close()
                }
            }
        }
    }
}
