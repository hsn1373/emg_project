import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Styles 1.0
import QtQuick.Dialogs 1.0
import QtGraphicalEffects 1.10
import QtQml.Models 2.1
import SerialPort 1.0
import CustomPlot 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1050
    height: 480
    title: qsTr("FUM EMG")
    //    visibility: "Maximized"

    //    Material.primary: "#1E88E5"
    //    Material.accent: "#FF6D00"
    //    Material.background: "#F5F5F5"
    //    Material.foreground: "#424242"


    readonly property string _select_device_str: "Select Device..."
    readonly property string _file_write_done_str: "Write to file done!"

    property bool _port_open: false
    property bool _writing_file: false

    SerialPort {
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
                if(channelCheckboxObjects[i].checked===true)
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
            viewResultPopup.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
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
                    //                    console.log(itemModel.children[i].type, i)
                }
            _port_open = true
        }
        onPortCloseSignal: {
            for (var i=0; i < itemModel.children.length; ++i)
                if(itemModel.children[i].type==="CustomPlotItem"){
                    itemModel.children[i].stopPlot()
                    //                    console.log(itemModel.children[i].type, i)
                }
            _port_open = false
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

    //****************************************************************************
    // header
    //****************************************************************************

    header: TabBar {
        id: tabBar
        currentIndex: swipeView.currentIndex
        TabButton {
            text: qsTr("Online")
        }
        TabButton {
            text: qsTr("Offline")
        }
    }

    //****************************************************************************
    //****************************************************************************

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: tabBar.currentIndex
        interactive: false

        //*****************************************
        // Online Page
        //*****************************************
        Item {
            id: online
            Grid {
                anchors.fill: parent
                rows: 2
                spacing: 5
                padding: 5

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
                            autoMoveCheckBox.checked = true
                            // Set all plot auto_move
                            for (var i=0; i < itemModel.children.length; ++i)
                                if(itemModel.children[i].type==="CustomPlotItem"){
                                    itemModel.children[i].auto_move = true
                                }
                            serialPort.deviceChanged(currentIndex)
                        }
                    }

                    Button {
                        text: 'Refresh'
                        onClicked: serialPort.refreshDevices()
                    }

                    ComboBox {
                        model: serialPort.baud_rate_list
                        onActivated: serialPort.baudRateChanged(currentIndex)
                    }

                    ComboBox {
                        model: serialPort.speed_list
                        onActivated: {
                            serialPort.speedChanged(currentIndex)
                            for (var i=0; i < itemModel.children.length; ++i)
                                if(itemModel.children[i].type==="CustomPlotItem"){
                                    itemModel.children[i].speedChanged(serialPort.currentSpeed())
                                }
                        }
                    }

                    Label {
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: qsTr("Port:")
                    }

                    Button {
                        text: 'close'
                        highlighted: true
                        onClicked: {
                            deviceComboBox.displayText = _select_device_str
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
                        Connections {
                            target: customPlot
                            onStatusChanged: autoMoveCheckBox.checked = customPlot.auto_move
                        }
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
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 0
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot1
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 1
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot2
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 2
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot3
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 3
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot4
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 4
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot5
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 5
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot6
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 6
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot7
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 7
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot8
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 8
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot9
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 9
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot10
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 10
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot11
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 11
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot12
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 12
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot13
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 13
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot14
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 14
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: customPlot15
                            width: root.width - 25
                            height: onlineRow2.height / 2
                            channel_num: 15
                            type: "CustomPlotItem"
                            Component.onCompleted: {
                                setReceivedDataPointer(serialPort)
                                initCustomPlot()
                            }
                        }
                    }

                    ListView {
                        id: onlinePlotListView
                        width: parent.width-8
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
        }
        //*****************************************
        // Offline Page
        //*****************************************
        Item {
            id: offline
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
                                if(channelCheckboxObjects[i].checked===true)
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
                    anchors.bottom: root.bottom


                    ObjectModel {
                        id: offlineItemModel
                        CustomPlotItem {
                            id: offlineCustomPlot1
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
                            height: offlineRow2.height / 2
                            Component.onCompleted: {
                                initCustomPlot()
                            }
                        }
                        CustomPlotItem {
                            id: offlineCustomPlot14
                            width: root.width - 50
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
                            width: root.width - 50
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
                            width: root.width - 50
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
                    //                        width: root.width - 10
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

    }


    //    footer: TabBar {
    //        id: tabBar
    //        currentIndex: swipeView.currentIndex
    //        TabButton {
    //            text: qsTr("Online")
    //        }
    //        TabButton {
    //            text: qsTr("Offline")
    //        }
    //    }

}
