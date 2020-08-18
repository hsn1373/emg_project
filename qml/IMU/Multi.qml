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
// Offline Page
//*****************************************
Item {
    id: offline
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

    //main Grid
    Grid {
        anchors.fill: parent
        rows: 3
        spacing: 5
        padding: 5

        //*******************
        // Top Row
        //*******************
        Row {
            spacing: 5
            width: parent.width
            height: parent.height * 1/10

            Rectangle
            {
                height: parent.height
                width: parent.width * 2/12
                color: "transparent"
                Label {
                    anchors.centerIn: parent
                    text: qsTr("Select File To View")
                }
            }

            Button {
                height: parent.height
                width: parent.width * 1/12
                highlighted: true
                text: 'select'
                onClicked: fileDialogOpen.open()
            }
            ComboBox {
                id: cmbfilter
                height: parent.height
                width: parent.width * 2/12
                model: serialPort.filter_list
                onActivated: serialPort.current_filter_index=currentIndex
            }
            //                    ComboBox {
            //                        id: cmbselectchannel
            //                        height: parent.height
            //                        width: parent.width * 1/12
            //                        model: serialPort.channel_list
            //                        onActivated: serialPort.current_channel=currentIndex
            //                    }
            Button {
                height: parent.height
                width: parent.width * 1/12
                highlighted: true
                text: 'apply'
                onClicked:
                {
                    var channelCheckboxObjects=
                            [channel1checkbox,channel2checkbox,channel3checkbox,channel4checkbox,
                             channel5checkbox,channel6checkbox,channel7checkbox,channel8checkbox,
                             channel9checkbox,channel10checkbox,channel11checkbox,channel12checkbox,
                             channel13checkbox,channel14checkbox,channel15checkbox,channel16checkbox]
                    var choosedChannels=[]
                    for(var i=0;i<16;i++)
                    {
                        if(channelCheckboxObjects[i].checked==true)
                            choosedChannels.push(i)
                    }
                    console.log(choosedChannels)

                    //                            serialPort.current_channel=cmbselectchannel.currentIndex
                    serialPort.applyFilter(choosedChannels)
                }
            }
            Grid
            {
                id:readFileProgressGrid
                width: parent.width * 5/12
                height: parent.height
                columns: 3
                visible: false

                Rectangle
                {
                    height: parent.height
                    width: parent.width * 2/10
                    color: "transparent"
                }
                ProgressBar{
                    id: readFileProgress
                    height: parent.height
                    width: parent.width * 5/10
                    from:0
                    to:800
                    value: 0



                    //*******************************************************************
                    //*******************************************************************
                    // Test Animation
                    //                            background: Rectangle
                    //                            {
                    //                                implicitWidth: 200
                    //                                implicitHeight: 6
                    //                                border.color: "#999999"
                    //                                radius: 5
                    //                            }
                    //                            contentItem: Item {
                    //                                implicitWidth: 200
                    //                                implicitHeight: 4

                    //                                Rectangle {
                    //                                    id: bar
                    //                                    width: readFileProgress.visualPosition * parent.width
                    //                                    height: parent.height
                    //                                    radius: 5
                    //                                    color: "#de1b65"
                    //                                }

                    //                                LinearGradient {
                    //                                    anchors.fill: bar
                    //                                    start: Qt.point(0, 0)
                    //                                    end: Qt.point(bar.width, 0)
                    //                                    source: bar
                    //                                    gradient: Gradient {
                    //                                        GradientStop { position: 0.0; color: "#de1b65" }
                    //                                        GradientStop { id: grad; position: 0.5; color: Qt.lighter("#de1b65", 2) }
                    //                                        GradientStop { position: 1.0; color: "#de1b65" }
                    //                                    }
                    //                                    PropertyAnimation {
                    //                                        target: grad
                    //                                        property: "position"
                    //                                        from: 0.1
                    //                                        to: 0.9
                    //                                        duration: 1000
                    //                                        running: true
                    //                                        loops: Animation.Infinite
                    //                                    }
                    //                                }
                    //                                LinearGradient {
                    //                                    anchors.fill: bar
                    //                                    start: Qt.point(0, 0)
                    //                                    end: Qt.point(0, bar.height)
                    //                                    source: bar
                    //                                    gradient: Gradient {
                    //                                        GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0) }
                    //                                        GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.3) }
                    //                                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.05) }
                    //                                    }
                    //                                }
                    //                            }

                    //*******************************************************************
                    //*******************************************************************
                }
                Rectangle
                {
                    height: parent.height
                    width: parent.width * 3/10
                    color: "transparent"
                    Label
                    {
                        id:readFileProgressText
                        anchors.centerIn: parent
                        text: "0%"
                    }
                }
            }


            FileDialog {
                id: fileDialogOpen
                title: "Open file"
                nameFilters: ["Text files (*.txt)","Csv Files (*.csv)","Xlsx Files (*.xlsx)"]
                //                        folder: shortcuts.documents
                onAccepted: {
                    console.log("You chose: " + fileDialogOpen.fileUrl)
                    serialPort.selected_file_for_save=fileDialogOpen.fileUrl
                    serialPort.selected_file_for_save_extention=fileDialogOpen.selectedNameFilter
                    serialPort.plot_offline()
                    readFileProgressGrid.visible=true
                }
                onRejected: {
                }
                Component.onCompleted: visible = false
            }

        }
        //*******************
        //CheckBoxs Row
        Row
        {
            spacing: 5
            width: parent.width
            height: parent.height * 1/10

            RowLayout {
                width: parent.width
                height: parent.height
                CheckBox {
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("all")
                    MouseArea{
                        anchors.fill: parent
                        onClicked:{
                            var channelCheckboxObjects=
                                    [channel1checkbox,channel2checkbox,channel3checkbox,channel4checkbox,
                                     channel5checkbox,channel6checkbox,channel7checkbox,channel8checkbox,
                                     channel9checkbox,channel10checkbox,channel11checkbox,channel12checkbox,
                                     channel13checkbox,channel14checkbox,channel15checkbox,channel16checkbox]
                            if(parent.checked==true)
                            {
                                parent.checked=false
                                for(var i=0;i<16;i++)
                                {
                                    channelCheckboxObjects[i].checked=false
                                }
                            }
                            else
                            {
                                parent.checked=true
                                for(i=0;i<16;i++)
                                {
                                    channelCheckboxObjects[i].checked=true
                                }
                            }
                        }
                    }
                }
                CheckBox {
                    id: channel1checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("1")
                }
                CheckBox {
                    id: channel2checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("2")
                }
                CheckBox {
                    id: channel3checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("3")
                }
                CheckBox {
                    id: channel4checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("4")
                }
                CheckBox {
                    id: channel5checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("5")
                }
                CheckBox {
                    id: channel6checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("6")
                }
                CheckBox {
                    id: channel7checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("7")
                }
                CheckBox {
                    id: channel8checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("8")
                }
                CheckBox {
                    id: channel9checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("9")
                }
                CheckBox {
                    id: channel10checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("10")
                }
                CheckBox {
                    id: channel11checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("11")
                }
                CheckBox {
                    id: channel12checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("12")
                }
                CheckBox {
                    id: channel13checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("13")
                }
                CheckBox {
                    id: channel14checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("14")
                }
                CheckBox {
                    id: channel15checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("15")
                }
                CheckBox {
                    id: channel16checkbox
                    width: parent.width * 1/17
                    height: parent.height
                    text: qsTr("16")
                }
            }
        }

        // Bottom Row
        //*******************
        Row {
            id: offlineRow2
            width: parent.width
            height: parent.height * 8/10
            anchors.bottom: offline.bottom


            ObjectModel {
                id: offlineItemModel
                CustomPlotItem {
                    id: offlineCustomPlot1
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }

                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }

                }
                CustomPlotItem {
                    id: offlineCustomPlot2
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot3
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot4
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot5
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot6
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot7
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot8
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot9
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot10
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot11
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot12
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot13
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot14
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot15
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
                CustomPlotItem {
                    id: offlineCustomPlot16
                    width: offline.width - 50
                    height: offlineRow2.height / 2
                    Component.onCompleted: {
                        initCustomPlot()
                    }
                    onIncreaseProgress:{
                        readFileProgress.value += 1
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                    onLoadOfflineDataFinish:{
                        readFileProgressGrid.visible=false
                        readFileProgress.value = 0
                        readFileProgressText.text = readFileProgress.value * 2/16 + "%"
                    }
                }
            }

            ListView {
                id: offlinePlotListView
                width: parent.width
                height: parent.height
                model: offlineItemModel
                clip: true
                ScrollBar.vertical: ScrollBar{
                    position: 1.0
                    policy: ScrollBar.AlwaysOn
                    snapMode: ScrollBar.SnapAlways
                }
                Component.onCompleted: positionViewAtBeginning()
            }

            //                    CustomPlotItem {
            //                        id: offline_customPlot
            //                        width: offline.width - 10
            //                        height: parent.height - 5
            //                        Component.onCompleted: initCustomPlot()
            //                    }
        }

        //                Popup {
        //                    id: readFilePopup
        //                    anchors.centerIn: Overlay.overlay
        //                    modal: true
        //                    focus: true
        //                    closePolicy: Popup.NoAutoClose // change closePolicy when write done

        //                    ColumnLayout {
        //                        anchors.fill: parent

        //                        ProgressBar{
        //                            id: readFileProgress
        //                            anchors.fill: parent
        //                            from:0
        //                            to:25
        //                            value: 0
        //                        }
        //                    }
        //                }
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

