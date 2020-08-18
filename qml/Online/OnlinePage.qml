import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.0
import QtGraphicalEffects 1.10
import QtQml.Models 2.1
import SerialPort 1.0
import CustomPlot 1.0
import QtQuick.Controls 2.3 as QQC2
import Client 1.0
import Connection 1.0
import ".."
import "../Style"
import QtQuick.Shapes 1.12


Item {

    Timer{
        id: startPlotTimer
        interval: 200
        onTriggered: {
            if(client.returnStatus()){
                UIStyle.connect = true
            }
        }
    }
    id: onlineID
    property int _channels_count: 16

    property var _active_channels: [true,true,true,true,
        true,true,true,true,
        true,true,true,true,
        true,true,true,true]
    property var active_channels: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    readonly property string _select_device_str: "Select Device..."
    readonly property string _file_write_done_str: "Write to file done!"

    property bool _port_open: false
    property bool _writing_file: false
    property var _file_path: ""
    property bool wifiActived: false
    property string popupString: ''
    Shape {
        width: parent.width
        height: parent.height
        anchors.centerIn: parent
        ShapePath {
            fillGradient: LinearGradient {
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

    Client{
        id: client
    }
    Connection{
        id: connection
    }



    function connectPopup(){
        popupString = 'You have to close the connection first.Do you want to close it?'
        acceptOk.text = 'ACCEPT'
        decline.visible = true
        connectionWarnning.open()
    }


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
            for (var i=0; i < onlinePlots_grid.children.length; ++i){
                if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                    onlinePlots_grid.children[i].children[1].startPlot()
                    //                    console.log(itemModel.children[i].type, i)
                }
            }
            _port_open = true
        }
        onPortCloseSignal: {
            for (var i=0; i < onlinePlots_grid.children.length; ++i){
                if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                    onlinePlots_grid.children[i].children[1].stopPlot()
                    //                    console.log(itemModel.children[i].type, i)
                }
            }
            _port_open = false
        }

        Component.onCompleted:
        {
            //********************
            console.log(serialPort.save_file_path)
            _file_path=serialPort.save_file_path
            //********************
            var ac_ch=serialPort.active_channels.split('');
            //console.log(ac_ch)
            for(var i=0;i<_channels_count;i++)
            {
                if(ac_ch[i]==1)
                    _active_channels[i]=true
                else
                    _active_channels[i]=false
            }

            for(i=0;i<onlinePlots_grid.children.length;i++)
            {
                if(onlinePlots_grid.children[i] instanceof Row)
                {
                    select_channels_grid.children[i].color=_active_channels[i] ? UIStyle.channelGreen : UIStyle.channelRed
                    onlinePlots_grid.children[i].visible=_active_channels[i]
                }
            }
            //********************
        }
    }






    Grid{
        width: parent.width
        height: parent.height
        spacing: 5
        padding: 5
        columns: 2

        Column{

            width: parent.width * 5/6
            height: parent.height

            Rectangle{ // plots backgound
                anchors.fill: parent
                color: 'transparent'
            }


            Grid{
                id: usb_grid
                width: parent.width
                height: parent.height
                rows: 2
                spacing: 15
                padding: 15
                y: 12

                Row {
                    id: onlineRow1
                    spacing: 10
                    padding: 10
                    width: parent.width
                    height: parent.height*1/10
                    Rectangle{
                        id: emptyRect1
                        width: parent.width * 1/60
                        height: parent.height
                        color: 'transparent'
                    }
                    Column{
                        id: tf
                        //visible: wifiActived
                        height: parent.height
                        width: parent.width * 3/10
                        Row{
                            height: parent.height * 1/2
                            width: parent.width
                            spacing: parent.width * 1/100
                            Rectangle{
                                width: parent.width * 1/10
                                height: parent.height
                                color: 'transparent'
                            }
                            TextField{
                                id: ip
                                visible: wifiActived
                                height: parent.height
                                width: parent.width * 5/10
                                enabled: !UIStyle.connect
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                Material.accent: Material.primary
                                validator: RegExpValidator{
                                    regExp:  /^((?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){0,3}(?:[0-1]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/}
                                text: qsTr('127.0.0.1')
                                placeholderText: qsTr('IP ADDRESS')
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                            }
                            TextField{
                                id: port
                                visible: wifiActived
                                height: parent.height
                                width: parent.width * 2/10
                                enabled: !UIStyle.connect
                                validator: IntValidator{}
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                Material.accent: Material.primary
                                text: qsTr('1235')
                                placeholderText: qsTr('PORT')
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                            }
                            ComboBox {
                                id: deviceComboBox
                                visible: !wifiActived
                                width: parent.width * 7/10
                                height: parent.height
                                Material.accent: Material.primary
                                font.pointSize:UIStyle.fontSize
                                font.family:UIStyle.fontName
                                background: Rectangle{
                                    width: parent.width
                                    height: parent.height
                                    //radius: parent.height * 1/2
                                    color: UIStyle.comboBackground
                                    border.width: 0.5
                                    border.color: UIStyle.borderGrey
                                }

                                //                currentIndex: -1
                                //                displayText: currentIndex === -1 ? "Select Device..." : currentText
                                displayText: _select_device_str
                                model: serialPort.serial_ports_list
                                onActivated: {
                                    this.displayText = this.currentText
                                    UIStyle.connect = true
                                }
                            }
                        }
                        Row{
                            height: parent.height * 1/2
                            width: parent.width
                            spacing: parent.width * 1/30
                            Button{
                                id: connectButton
                                visible: wifiActived
                                text: 'connect'
                                highlighted: UIStyle.darkTheme
                                width: parent.width * 3/14
                                height: parent.height
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                enabled: ! UIStyle.connect
                                background:  Rectangle {
                                    radius: 5
                                    color: UIStyle.themeBlue
                                }
                                onClicked: {
                                    client.start(ip.text, port.text)
                                    startPlotTimer.start()
                                    UIStyle.connect = client.returnStatus()
                                }
                                onHoveredChanged: {
                                    if(hovered)
                                        connectButton.background.color = UIStyle.buttonHovered
                                    else
                                        connectButton.background.color = UIStyle.themeBlue
                                }
                            }
                            Button{
                                id: disconnectButton
                                visible: wifiActived
                                text: 'disconnect'
                                width: parent.width * 3/14
                                height: parent.height
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                highlighted: UIStyle.darkTheme
                                enabled: UIStyle.connect
                                background:  Rectangle {
                                    radius: 5
                                    color: UIStyle.themeBlue
                                }
                                onClicked: {
                                    autoMoveCheckBox.checked = false
                                    // Set all plot auto_move
                                    for (var i=0; i < onlinePlots_grid.children.length; ++i){
                                        if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                                            onlinePlots_grid.children[i].children[1].auto_move = false
                                        }
                                    }
                                    //                                    writeFilePopup.closePolicy = Popup.NoAutoClose
                                    //                                    _writing_file = true
                                    //                                    if (_port_open)
                                    //                                        writeFilePopup.open()
                                    serialPort.closePort()
                                    connection.closeSocket()
                                    UIStyle.connect = false
                                    start_stop.text = 'Start'
                                    start_stop.Material.background = Material.Green
                                    //                                    saveFileDialog.open()
                                }
                                onHoveredChanged: {
                                    if(hovered)
                                        disconnectButton.background.color = UIStyle.buttonHovered
                                    else
                                        disconnectButton.background.color = UIStyle.themeBlue
                                }
                            }
                            Button {
                                id: refreshButton
                                visible: !wifiActived
                                width: parent.width * 3/14
                                height: parent.height
                                background:  Rectangle {
                                    width: parent.width
                                    height: parent.height
                                    radius: 5
                                    color: UIStyle.themeBlue
                                }
                                highlighted: UIStyle.darkTheme
                                text: 'Refresh'
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                onClicked: serialPort.refreshDevices()
                                onHoveredChanged: {
                                    if(hovered)
                                        refreshButton.background.color = UIStyle.buttonHovered
                                    else
                                        refreshButton.background.color = UIStyle.themeBlue
                                }
                            }
                            Button {
                                id: closeButton
                                visible: !wifiActived
                                width: parent.width * 3/14
                                height: parent.height
                                text: 'close'
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                background:  Rectangle {
                                    radius: 5
                                    color: UIStyle.themeBlue
                                }
                                highlighted: UIStyle.darkTheme
                                onClicked: {
                                    deviceComboBox.displayText = _select_device_str
                                    autoMoveCheckBox.checked = false
                                    // Set all plot auto_move
                                    for (var i=0; i < onlinePlots_grid.children.length; ++i){
                                        if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                                            onlinePlots_grid.children[i].children[1].auto_move = false
                                        }
                                    }

                                    //                                    writeFilePopup.closePolicy = Popup.NoAutoClose
                                    //                                    _writing_file = true
                                    //                                    if (_port_open)
                                    //                                        writeFilePopup.open()
                                    serialPort.closePort()
                                    //                                    saveFileDialog.open()
                                    start_stop.text = 'Start'
                                    start_stop.Material.background = Material.Green
                                }
                                onHoveredChanged: {
                                    if(hovered)
                                        closeButton.background.color = UIStyle.buttonHovered
                                    else
                                        closeButton.background.color = UIStyle.themeBlue
                                }
                            }
                            Button {
                                id: saveAsButton
                                width: parent.width * 3/14
                                height: parent.height
                                text: 'Save'
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                background:  Rectangle {
                                    radius: 5
                                    color: UIStyle.themeBlue
                                }
                                highlighted: UIStyle.darkTheme
                                onClicked: {
                                    writeFilePopup.closePolicy = Popup.NoAutoClose
                                    _writing_file = true
                                    writeFilePopup.open()
                                    saveFileDialog.open()

                                }
                                onHoveredChanged: {
                                    if(hovered)
                                        saveAsButton.background.color = UIStyle.buttonHovered
                                    else
                                        saveAsButton.background.color = UIStyle.themeBlue
                                }
                            }
                            Button {
                                id: start_stop
                                width: parent.width * 3/14
                                height: parent.height
                                text: 'Start'
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                Material.background: Material.Green
                                highlighted: UIStyle.darkTheme
                                onClicked: {
                                    if(UIStyle.connect){
                                        //                                    switch(start_stop.text){
                                        //                                    case 'Start' :
                                        //                                        start_stop.text = 'Stop'
                                        //                                        break
                                        //                                    default:
                                        //                                        start_stop.text = 'Start'
                                        //                                        break
                                        //                                    }



                                        if(start_stop.text === 'Start'){
                                            if(usb_wifi.currentIndex === 0){
                                                autoMoveCheckBox.checked = true
                                                // Set all plot auto_move
                                                for (var i=0; i < onlinePlots_grid.children.length; ++i){
                                                    if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                                                        onlinePlots_grid.children[i].children[1].auto_move = true
                                                    }
                                                }
                                                serialPort.deviceChanged(deviceComboBox.currentIndex)
                                            }
                                            else{
                                                if(client.returnStatus()){
                                                    for (var i=0; i < onlinePlots_grid.children.length; ++i){
                                                        if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                                                            onlinePlots_grid.children[i].children[1].auto_move = true
                                                            autoMoveCheckBox.checked = true
                                                            serialPort.openWifiPort() // Starts plot from serialport class
                                                        }
                                                    }
                                                }
                                            }
                                            start_stop.text = 'Stop'
                                            Material.background = Material.Red
                                        }
                                        else{
                                            autoMoveCheckBox.checked = false
                                            // Set all plot auto_move
                                            for (var i=0; i < onlinePlots_grid.children.length; ++i){
                                                if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                                                    onlinePlots_grid.children[i].children[1].auto_move = false
                                                }
                                            }
                                            //                                    writeFilePopup.closePolicy = Popup.NoAutoClose
                                            //                                    _writing_file = true
                                            //                                    if (_port_open)
                                            //                                        writeFilePopup.open()
                                            serialPort.closePort()
                                            //                                        client.closeSocket()
                                            //                                        UIStyle.connect = false
                                            start_stop.text = 'Start'
                                            Material.background = Material.Green
                                        }
                                    }
                                }
                            }
                            //                            Rectangle{
                            //                                id: emptyRect2
                            //                                width: parent.width * 1/20
                            //                                height: parent.height
                            //                                color: 'transparent'
                            //                            }
                        }
                    }

                    Frame
                    {
                        width: parent.width * 27/100
                        height: parent.height
                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        Grid {
                            id: select_channels_grid
                            columns: 4
                            anchors.fill: parent
                            spacing: 2
                            Repeater {
                                model: _channels_count
                                Rectangle
                                {
                                    id: channel_rec
                                    width: parent.width * 1/4 - 1
                                    height: parent.height * 1/4 - 1
                                    radius: parent.height
                                    color: onlinePlots_grid.children[index].visible ? UIStyle.channelGreen : UIStyle.channelRed
                                    Label {
                                        anchors.centerIn: parent
                                        text: qsTr((index+1).toString())
                                        font.pixelSize: parent.height - 2
                                        font.family: UIStyle.fontName
                                    }
                                    MouseArea
                                    {
                                        anchors.fill: parent
                                        onClicked:
                                        {
                                            if(onlinePlots_grid.children[index].visible)
                                            {
                                                onlinePlots_grid.children[index].state="2"
                                                onlinePlots_grid.children[index].visible=false
                                                channel_rec.color= UIStyle.channelRed
                                            }
                                            else
                                            {
                                                onlinePlots_grid.children[index].state="1"
                                                onlinePlots_grid.children[index].visible=true
                                                channel_rec.color= UIStyle.channelGreen
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Column{
                        // check boxes
                        width: parent.width * 17/100
                        height: parent.height
                        Row{
                            width: parent.width
                            height: parent.height * 1/2
                            CheckBox {
                                id: autoMoveCheckBox
                                width: parent.width * 1/2
                                height: parent.height
                                text: qsTr("Auto move")
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                Material.accent: Material.primary
                                onClicked: {
                                    // Set all plot auto_move
                                    for (var i=0; i < onlinePlots_grid.children.length; ++i)
                                        if(onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                                            onlinePlots_grid.children[i].children[1].auto_move = checked
                                        }
                                }
                                Component.onCompleted: checked = onlinePlots_grid.children[0].children[1].auto_move
                                Connections {
                                    target: onlinePlots_grid.children[0].children[1]
                                    onStatusChanged: autoMoveCheckBox.checked = customPlot.auto_move
                                }
                            }
                            CheckBox {
                                id: show_hide_all_channels
                                width: parent.width * 1/2
                                height: parent.height
                                text: qsTr("show all")
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                checked: false
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                Material.accent: Material.primary
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked:{
                                        if(parent.checked)
                                        {
                                            parent.checked=false
                                            for(var i=0;i<onlinePlots_grid.children.length;i++)
                                            {
                                                if(onlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    onlinePlots_grid.children[i].state="2"
                                                    onlinePlots_grid.children[i].visible=false
                                                    select_channels_grid.children[i].color= UIStyle.channelRed
                                                }
                                            }
                                        }
                                        else
                                        {
                                            parent.checked=true
                                            for(i=0;i<onlinePlots_grid.children.length;i++)
                                            {
                                                if(onlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    onlinePlots_grid.children[i].state="1"
                                                    onlinePlots_grid.children[i].visible=true
                                                    select_channels_grid.children[i].color= UIStyle.channelGreen
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                        }

                        Row{
                            width: parent.width
                            height: parent.height * 1/2
                            CheckBox {
                                id: grid_checkbox
                                width: parent.width * 1/2
                                height: parent.height
                                text: qsTr("2Column")
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                Material.accent: Material.primary
                                checked: false
                            }
                            CheckBox {
                                id: allCheckBox
                                width: parent.width * 1/2
                                height: parent.height
                                text: qsTr('select all')
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                Material.accent: Material.primary
                                MouseArea{
                                    anchors.fill: parent
                                    onClicked:{
                                        if(parent.checked==true)
                                        {
                                            parent.checked=false
                                            for(var i=0;i<onlinePlots_grid.children.length;i++)
                                            {
                                                if(onlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    onlinePlots_grid.children[i].children[2].checked=false
                                                }
                                            }
                                        }
                                        else
                                        {
                                            parent.checked=true
                                            for(i=0;i<onlinePlots_grid.children.length;i++)
                                            {
                                                if(onlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    onlinePlots_grid.children[i].children[2].checked=true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Column{
                        width: parent.width * 1/10
                        height: parent.height
                        Row{
                            width: parent.width
                            height: parent.height * 1/2
                            ComboBox{
                                id: usb_wifi
                                width: parent.width
                                height: parent.height
                                y: 5
                                Material.accent: Material.primary
                                font.pointSize:UIStyle.fontSize
                                font.family:UIStyle.fontName
                                background: Rectangle{
                                    width: parent.width
                                    height: parent.height
                                    radius: parent.height
                                    color: UIStyle.comboBackground
                                    border.width: 0.5
                                    border.color: UIStyle.borderGrey
                                }
                                model: ['wired', 'wireless']
                                onActivated: {
                                    start_stop.text = 'Start'
                                    start_stop.Material.background = Material.Green
                                    autoMoveCheckBox.checked = false
                                    // Set all plot auto_move
                                    for (var i=0; i < onlinePlots_grid.children.length; ++i){
                                        if(onlinePlots_grid.children[i].children[1] !== undefined && onlinePlots_grid.children[i].children[1].type==="CustomPlotItem"){
                                            onlinePlots_grid.children[i].children[1].auto_move = false
                                        }
                                    }
                                    //                                    writeFilePopup.closePolicy = Popup.NoAutoClose
                                    //                                    _writing_file = true
                                    //                                    if (_port_open)
                                    //                                        writeFilePopup.open()
                                    serialPort.closePort()
                                    client.closeSocket()
                                    UIStyle.connect = false
                                }

                                onCurrentTextChanged: {
                                    serialPort.closePort()
                                    UIStyle.connect = false
                                    if (usb_wifi.currentIndex === 0){
                                        wifiActived = false
                                        serialPort.usingWifiSloth(false)
                                        client.closeSocket()
                                        //                        if(UIStyle.connect){
                                        //                        popupString = 'connection closed'
                                        //                        acceptOk.text = 'OK'
                                        //                        decline.visible=false
                                        //                        connectionWarnning.open()
                                        //                        }
                                    }
                                    else{
                                        wifiActived = true
                                        serialPort.usingWifiSloth(true)
                                    }
                                }
                            }
                        }
                        Row{
                            width: parent.width
                            height: parent.height * 1/2
                            Rectangle{
                                width: parent.width * 1/2
                                height: parent.height
                                color: "transparent"
                                Label {
                                    anchors.centerIn: parent
                                    text: "connected?"
                                    color: UIStyle.darkTheme ? "#ffffff" : '#000000'
                                    font.pointSize: UIStyle.fontSize
                                    font.family: UIStyle.fontName
                                }
                            }
                            Rectangle{
                                width: parent.width * 1/2
                                height: parent.height
                                color: "transparent"
                                Image{
                                    anchors.centerIn: parent
                                    width: parent.width * 1/2
                                    height: parent.height * 1/2
                                    source: UIStyle.connect ? "../../images/check.png" : "../../images/unchecked.png"
                                }
                            }
                        }
                    }
                }

                Row {
                    id: onlineRow2
                    width: parent.width
                    height: parent.height*9/10

                    Flickable {
                        anchors.fill: parent
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.DragOverBounds
                        clip: true
                        contentHeight: onlinePlots_grid.height
                        Grid {
                            id: onlinePlots_grid
                            columns: grid_checkbox.checked ? 2 : 1
                            width: parent.width
                            Repeater {
                                model: _channels_count
                                Row {
                                    id: onlineCustomPlot_row
                                    property int itemIndex: index
                                    width: grid_checkbox.checked ? (onlineRow2.width - 1/15*onlineRow2.width)/2 : onlineRow2.width - 1/15*onlineRow2.width
                                    height: onlineRow2.height / 3
                                    spacing: 3
                                    state: "2"
                                    opacity: 0.0

                                    Rectangle
                                    {
                                        color: "transparent"
                                        width: parent.width * 3/210
                                        height: parent.height
                                        Label {
                                            anchors.centerIn: parent
                                            text: qsTr((onlineCustomPlot_row.itemIndex+1).toString())
                                            font.pointSize: UIStyle.fontSize
                                            font.family: UIStyle.fontName
                                            color: UIStyle.channelGreen
                                        }
                                    }
                                    CustomPlotItem {
                                        width: parent.width * 206/210
                                        height: parent.height
                                        channel_num: onlineCustomPlot_row.itemIndex
                                        type: "CustomPlotItem"
                                        Component.onCompleted: {
                                            setReceivedDataPointer(serialPort)
                                            initCustomPlot()
                                        }
                                    }
                                    CheckBox {
                                        width: parent.width * 1/210
                                        height: parent.height
                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                        Material.accent: Material.primary
                                        text: qsTr("")
                                        onCheckStateChanged: {
                                            serialPort.getActiveChannels(index, checked)
                                        }
                                    }
                                    states: [
                                        State {
                                            name: "2"
                                            //                                            PropertyChanges { target: offlineCustomPlot_row; width:0  }
                                            PropertyChanges { target: onlineCustomPlot_row; opacity: 0.0  }
                                        },
                                        State {
                                            name: "1"
                                            //                                            PropertyChanges { target: offlineCustomPlot_row; width:grid_checkbox.checked ? (offlineRow2.width - 1/10*offlineRow2.width)/2 : offlineRow2.width - 1/10*offlineRow2.width  }
                                            PropertyChanges { target: onlineCustomPlot_row; opacity: 1.0  }
                                        }
                                    ]

                                    transitions: [
                                        Transition {
                                            reversible: true
                                            //                                            PropertyAnimation { easing.type: Easing.InOutQuad; properties: "width"; duration: 1000 }
                                            PropertyAnimation { easing.type: Easing.InOutQuad; properties: "opacity"; duration: 1000 }
                                        }
                                    ]
                                }
                            }
                        }
                        ScrollBar.vertical: ScrollBar{
                            position: 1.0
                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                            policy: ScrollBar.AlwaysOn
                            snapMode: ScrollBar.SnapAlways
                        }
                    }
                }
            }
        }


        Column{
            width: parent.width * 1/6
            height: parent.height

            Row
            {
                width: parent.width
                height: parent.height * 11/12
                clip: true
                TabBar {
                    id: tabBar
                    width: parent.width
                    currentIndex: svSettingsContainer.currentIndex
                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    Material.accent: Material.Indigo
                    background: Rectangle
                    {
                        color: "transparent"
                    }
                    TabButton {
                        text: qsTr("Filter")
                        font.family:UIStyle.fontName
                        font.pointSize: UIStyle.fontSize - 2
                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        Material.accent: Material.Indigo

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked:
                            {
                                tabBar.currentIndex=0
                                var rdb_objects=[rdb_integral,rdb_mean_absolute_value,rdb_moving_averaging,
                                                 rdb_rms,rdb_zero_crossing,rdb_rectifiction,rdb_spectrum,
                                                 rdb_power_spectrum,rdb_mean_frequency,rdb_median_frequency]
                                for(var i=0;i<rdb_objects.length;i++)
                                    rdb_objects[i].checked=false
                                serialPort.current_filter_index=0
                            }
                        }
                    }
                }

                SwipeView {
                    id: svSettingsContainer
                    currentIndex: tabBar.currentIndex
                    //                    anchors.fill: parent
                    anchors.top: tabBar.bottom
                    width: parent.width
                    height: parent.height * 9/10

                    SwipeViewPage {
                        id: signalProcessingPage1

                        Column {
                            width: parent.width
                            height: parent.height
                            spacing: 10
                            padding: 10

                            // notch filter
                            Pane
                            {
                                Material.elevation: 10
                                background: Rectangle{
                                    width: parent.width
                                    height: parent.height
                                    radius: 5
                                    color: "transparent"
                                    border.width: 1
                                    border.color: UIStyle.borderGrey2
                                }

                                width: parent.width * 4/5
                                height: parent.height * 1/3 - 30
                                //                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                Column
                                {
                                    width: parent.width
                                    height: parent.height
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/2
                                        CheckBox {
                                            id: chkbox_notch
                                            anchors.centerIn: parent
                                            text: qsTr("notch")
                                            font.family:UIStyle.fontName
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                            font.pointSize: UIStyle.fontSize
                                        }
                                    }
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/2
                                        x: 10
                                        Rectangle
                                        {
                                            color: "transparent"
                                            width: parent.width * 1/2
                                            height: parent.height
                                            Label {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: qsTr("Ab(db)")
                                                font.family:UIStyle.fontName
                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                font.pointSize: UIStyle.fontSize
                                            }
                                        }
                                        TextField
                                        {
                                            id: txt_Ab
                                            width: parent.width * 1/2 - 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: qsTr("50")
                                            font.family:UIStyle.fontName
                                            font.pointSize: UIStyle.fontSize
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                        }
                                    }
                                }

                            }
                            // low pass
                            Pane
                            {
                                Material.elevation: 10
                                background: Rectangle{
                                    width: parent.width
                                    height: parent.height
                                    radius: 5
                                    color: "transparent"
                                    border.width: 1
                                    border.color: UIStyle.borderGrey2
                                }
                                width: parent.width * 4/5
                                height: parent.height * 1/3 - 30
                                anchors.horizontalCenter: parent.horizontalCenter
                                Column
                                {
                                    width: parent.width
                                    height: parent.height
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/3
                                        CheckBox {
                                            id: chkbox_lowpass
                                            anchors.centerIn: parent
                                            text: qsTr("low pass")
                                            font.family:UIStyle.fontName
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                            font.pointSize: UIStyle.fontSize
                                        }
                                    }
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/3
                                        x: 10
                                        Rectangle
                                        {
                                            color: "transparent"
                                            width: parent.width * 1/2
                                            height: parent.height
                                            Label {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: qsTr("fl")
                                                font.family:UIStyle.fontName
                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                //font.pixelSize: _font_size
                                                font.pointSize: UIStyle.fontSize
                                            }
                                        }
                                        TextField
                                        {
                                            id: txt_lowpass_fl
                                            width: parent.width * 1/2 - 10
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: qsTr("500")
                                            font.family:UIStyle.fontName
                                            font.pointSize: UIStyle.fontSize
                                        }
                                    }
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/3
                                        x: 10
                                        Rectangle
                                        {
                                            color: "transparent"
                                            width: parent.width * 1/2
                                            height: parent.height
                                            Label {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: qsTr("order")
                                                font.family:UIStyle.fontName
                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                font.pointSize: UIStyle.fontSize
                                            }
                                        }
                                        TextField
                                        {
                                            id: txt_lowpass_order
                                            width: parent.width * 1/2 - 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: qsTr("4")
                                            font.family:UIStyle.fontName
                                            font.pointSize: UIStyle.fontSize
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                        }
                                    }

                                }

                            }

                            // high pass
                            Pane
                            {
                                Material.elevation: 10
                                background: Rectangle{
                                    width: parent.width
                                    height: parent.height
                                    radius: 5
                                    color: "transparent"
                                    border.width: 1
                                    border.color: UIStyle.borderGrey2
                                }
                                width: parent.width * 4/5
                                height: parent.height * 1/3 - 30
                                anchors.horizontalCenter: parent.horizontalCenter
                                Column
                                {
                                    width: parent.width
                                    height: parent.height
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/3
                                        CheckBox {
                                            id: chkbox_highpass
                                            anchors.centerIn: parent
                                            text: qsTr("high pass")
                                            font.family:UIStyle.fontName
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                            font.pointSize: UIStyle.fontSize
                                        }
                                    }
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/3
                                        x: 10
                                        Rectangle
                                        {
                                            color: "transparent"
                                            width: parent.width * 1/2
                                            height: parent.height
                                            Label {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: qsTr("fh")
                                                font.family:UIStyle.fontName
                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                font.pointSize: UIStyle.fontSize
                                            }
                                        }
                                        TextField
                                        {
                                            id: txt_highpass_fh
                                            width: parent.width * 1/2 - 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: qsTr("20")
                                            font.family:UIStyle.fontName
                                            font.pointSize: UIStyle.fontSize
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                        }
                                    }
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/3
                                        x: 10
                                        Rectangle
                                        {
                                            color: "transparent"
                                            width: parent.width * 1/2
                                            height: parent.height
                                            Label {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: qsTr("order")
                                                font.family:UIStyle.fontName
                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                font.pointSize: UIStyle.fontSize
                                            }
                                        }
                                        TextField
                                        {
                                            id: txt_highpass_order
                                            width: parent.width * 1/2 - 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: qsTr("4")
                                            font.family:UIStyle.fontName
                                            font.pointSize: UIStyle.fontSize
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                        }
                                    }

                                }

                            }

                        }
                    }

                    //                    SwipeViewPage {
                    //                        id: signalProcessingPage2

                    //                        ButtonGroup { id: radioGroup }
                    //                        Column {
                    //                            width: parent.width
                    //                            height: parent.height
                    //                            spacing: 10
                    //                            padding: 5

                    //                            //*************************************************
                    //                            // row 1
                    //                            Row
                    //                            {
                    //                                width: parent.width
                    //                                height: parent.height * 1/3
                    //                                spacing: 5
                    //                                padding: 5

                    //                                // rms
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Column
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            RadioButton
                    //                                            {
                    //                                                id: rdb_rms
                    //                                                anchors.centerIn: parent
                    //                                                text: qsTr("rms")
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                ButtonGroup.group: radioGroup
                    //                                                //                                                onCheckedChanged:
                    //                                                //                                                {
                    //                                                //                                                    var rdb_objs=[rdb_integral,rdb_mean_absolute_value,
                    //                                                //                                                             rdb_moving_averaging,rdb_zero_crossing]
                    //                                                //                                                    for(var i=0;i<4;i++)
                    //                                                //                                                    {
                    //                                                //                                                        rdb_integral.ch
                    //                                                //                                                        if(rdb_rms.checked)
                    //                                                //                                                            rdb_objs[i].che
                    //                                                //                                                    }
                    //                                                //                                                }
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width * 2/3
                    //                                                height: parent.height
                    //                                                Label {
                    //                                                    anchors.left: parent.leftradiobutton
                    //                                                    anchors.verticalCenter: parent.verticalCenter
                    //                                                    text: qsTr("windowLength")
                    //                                                    font.family:UIStyle.fontName
                    //                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                    //font.pixelSize: _font_size
                    //                                                    font.pointSize: UIStyle.fontSize
                    //                                                }
                    //                                            }
                    //                                            TextField
                    //                                            {
                    //                                                id: txt_rms_windowlen
                    //                                                width: parent.width * 1/3
                    //                                                anchors.verticalCenter: parent.verticalCenter
                    //                                                text: qsTr("30")
                    //                                                font.family:UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width * 2/3
                    //                                                height: parent.height
                    //                                                Label {
                    //                                                    anchors.left: parent.left
                    //                                                    anchors.verticalCenter: parent.verticalCenter
                    //                                                    text: qsTr("overlap")
                    //                                                    font.family:UIStyle.fontName
                    //                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                    //font.pixelSize: _font_size
                    //                                                    font.pointSize: UIStyle.fontSize
                    //                                                }
                    //                                            }
                    //                                            TextField
                    //                                            {
                    //                                                id: txt_rms_overlap
                    //                                                width: parent.width * 1/3
                    //                                                anchors.verticalCenter: parent.verticalCenter
                    //                                                text: qsTr("10")
                    //                                                font.family:UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                            }
                    //                                        }

                    //                                    }

                    //                                }


                    //                                // integral
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Column
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            RadioButton
                    //                                            {
                    //                                                id: rdb_integral
                    //                                                anchors.centerIn: parent
                    //                                                //                                                checked: true
                    //                                                text: qsTr("integral")
                    //                                                font.family:UIStyle.fontName
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                ButtonGroup.group: radioGroup
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width * 2/3
                    //                                                height: parent.height
                    //                                                Label {
                    //                                                    anchors.left: parent.left
                    //                                                    anchors.verticalCenter: parent.verticalCenter
                    //                                                    text: qsTr("windowLength")
                    //                                                    font.family:UIStyle.fontName
                    //                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                    //font.pixelSize: _font_size
                    //                                                    font.pointSize: UIStyle.fontSize
                    //                                                }
                    //                                            }
                    //                                            TextField
                    //                                            {
                    //                                                id: txt_integral_windowlen
                    //                                                width: parent.width * 1/3
                    //                                                anchors.verticalCenter: parent.verticalCenter
                    //                                                text: qsTr("30")
                    //                                                font.family:UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width * 2/3
                    //                                                height: parent.height
                    //                                                Label {
                    //                                                    anchors.left: parent.left
                    //                                                    anchors.verticalCenter: parent.verticalCenter
                    //                                                    text: qsTr("overlap")
                    //                                                    font.family:UIStyle.fontName
                    //                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                    //font.pixelSize: _font_size
                    //                                                    font.pointSize: UIStyle.fontSize
                    //                                                }
                    //                                            }
                    //                                            TextField
                    //                                            {
                    //                                                id: txt_integral_overlap
                    //                                                width: parent.width * 1/3
                    //                                                anchors.verticalCenter: parent.verticalCenter
                    //                                                text: qsTr("10")
                    //                                                font.family:UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                            }
                    //                                        }

                    //                                    }

                    //                                }
                    //                            }
                    //                            //*******************************************
                    //                            // row 2
                    //                            Row
                    //                            {
                    //                                width: parent.width
                    //                                height: parent.height * 1/3
                    //                                spacing: 5
                    //                                padding: 5

                    //                                // mean absolute value
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Column
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            RadioButton
                    //                                            {
                    //                                                id: rdb_mean_absolute_value
                    //                                                anchors.centerIn: parent
                    //                                                //                                                checked: true
                    //                                                text: qsTr("mean absolute value")
                    //                                                font.family:UIStyle.fontName
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                                ButtonGroup.group: radioGroup
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width * 2/3
                    //                                                height: parent.height
                    //                                                Label {
                    //                                                    anchors.left: parent.left
                    //                                                    anchors.verticalCenter: parent.verticalCenter
                    //                                                    text: qsTr("windowLength")
                    //                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                    font.family: UIStyle.fontName
                    //                                                    //font.pixelSize: _font_size
                    //                                                    font.pointSize: UIStyle.fontSize
                    //                                                }
                    //                                            }
                    //                                            TextField
                    //                                            {
                    //                                                id: txt_mean_absolute_value_windowlen
                    //                                                width: parent.width * 1/3
                    //                                                anchors.verticalCenter: parent.verticalCenter
                    //                                                text: qsTr("30")
                    //                                                font.family: UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width * 2/3
                    //                                                height: parent.height
                    //                                                Label {
                    //                                                    anchors.left: parent.left
                    //                                                    anchors.verticalCenter: parent.verticalCenter
                    //                                                    text: qsTr("overlap")
                    //                                                    font.family: UIStyle.fontName
                    //                                                    //font.pixelSize: _font_size
                    //                                                    font.pointSize: UIStyle.fontSize
                    //                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                }
                    //                                            }
                    //                                            TextField
                    //                                            {
                    //                                                id: txt_mean_absolute_value_overlap
                    //                                                width: parent.width * 1/3
                    //                                                anchors.verticalCenter: parent.verticalCenter
                    //                                                text: qsTr("10")
                    //                                                font.family: UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                            }
                    //                                        }

                    //                                    }

                    //                                }


                    //                                // moving averaging
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Column
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            RadioButton
                    //                                            {
                    //                                                id: rdb_moving_averaging
                    //                                                anchors.centerIn: parent
                    //                                                //                                                checked: true
                    //                                                text: qsTr("moving averaging")
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                                ButtonGroup.group: radioGroup
                    //                                                font.family: UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width * 2/3
                    //                                                height: parent.height
                    //                                                Label {
                    //                                                    anchors.left: parent.left
                    //                                                    anchors.verticalCenter: parent.verticalCenter
                    //                                                    text: qsTr("value")
                    //                                                    font.family: UIStyle.fontName
                    //                                                    //font.pixelSize: _font_size
                    //                                                    font.pointSize: UIStyle.fontSize
                    //                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                }
                    //                                            }
                    //                                            TextField
                    //                                            {
                    //                                                id: txt_moving_averaging_value
                    //                                                width: parent.width * 1/3
                    //                                                anchors.verticalCenter: parent.verticalCenter
                    //                                                text: qsTr("150")
                    //                                                font.family: UIStyle.fontName
                    //                                                //font.pixelSize: _font_size
                    //                                                font.pointSize: UIStyle.fontSize
                    //                                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                                Material.accent: Material.primary
                    //                                            }
                    //                                        }
                    //                                        Row
                    //                                        {
                    //                                            width: parent.width
                    //                                            height: parent.height * 1/3
                    //                                            Rectangle
                    //                                            {
                    //                                                color: "transparent"
                    //                                                width: parent.width
                    //                                                height: parent.height
                    //                                            }
                    //                                        }

                    //                                    }

                    //                                }
                    //                            }
                    //                            //*******************************************
                    //                            // row 3
                    //                            Row
                    //                            {
                    //                                width: parent.width
                    //                                height: parent.height * 1/3 - 20
                    //                                spacing: 5
                    //                                padding: 5

                    //                                // zero crossing
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Row
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        RadioButton
                    //                                        {
                    //                                            id: rdb_zero_crossing
                    //                                            anchors.centerIn: parent
                    //                                            //                                                checked: true
                    //                                            text: qsTr("zero crossing")
                    //                                            font.family: UIStyle.fontName
                    //                                            //font.pixelSize: _font_size
                    //                                            font.pointSize: UIStyle.fontSize
                    //                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                            Material.accent: Material.primary
                    //                                            ButtonGroup.group: radioGroup
                    //                                        }
                    //                                    }
                    //                                }

                    //                                // rectifiction
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Row
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        RadioButton
                    //                                        {
                    //                                            id: rdb_rectifiction
                    //                                            anchors.centerIn: parent
                    //                                            text: qsTr("rectifiction")
                    //                                            font.family: UIStyle.fontName
                    //                                            //font.pixelSize: _font_size
                    //                                            font.pointSize: UIStyle.fontSize
                    //                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                            Material.accent: Material.primary
                    //                                            ButtonGroup.group: radioGroup
                    //                                        }
                    //                                    }
                    //                                }
                    //                            }
                    //                        }
                    //                    }
                    //                    SwipeViewPage {
                    //                        id: signalProcessingPage3

                    //                        Column {
                    //                            width: parent.width
                    //                            height: parent.height
                    //                            spacing: 10
                    //                            padding: 5

                    //                            //*************************************************
                    //                            // row 1
                    //                            Row
                    //                            {
                    //                                width: parent.width
                    //                                height: parent.height * 1/2
                    //                                spacing: 5
                    //                                padding: 5

                    //                                // spectrum
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height * 1/2
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Row
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        RadioButton
                    //                                        {
                    //                                            id: rdb_spectrum
                    //                                            anchors.centerIn: parent
                    //                                            //                                                checked: true
                    //                                            text: qsTr("spectrum")
                    //                                            font.family: UIStyle.fontName
                    //                                            //font.pixelSize: _font_size
                    //                                            font.pointSize: UIStyle.fontSize
                    //                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                            Material.accent: Material.primary
                    //                                            ButtonGroup.group: radioGroup
                    //                                        }
                    //                                    }
                    //                                }

                    //                                // power spectrum
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height * 1/2
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Row
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        RadioButton
                    //                                        {
                    //                                            id: rdb_power_spectrum
                    //                                            anchors.centerIn: parent
                    //                                            text: qsTr("power spectrum")
                    //                                            font.family: UIStyle.fontName
                    //                                            //font.pixelSize: _font_size
                    //                                            font.pointSize: UIStyle.fontSize
                    //                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                            Material.accent: Material.primary
                    //                                            ButtonGroup.group: radioGroup

                    //                                        }
                    //                                    }
                    //                                }
                    //                            }
                    //                            //*******************************************
                    //                            // row 2
                    //                            Row
                    //                            {
                    //                                width: parent.width
                    //                                height: parent.height * 1/2
                    //                                spacing: 5
                    //                                padding: 5

                    //                                // mean frequency
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height * 1/2
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Row
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        RadioButton
                    //                                        {
                    //                                            id: rdb_mean_frequency
                    //                                            anchors.centerIn: parent
                    //                                            text: qsTr("mean frequency")
                    //                                            font.family: UIStyle.fontName
                    //                                            //font.pixelSize: _font_size
                    //                                            font.pointSize: UIStyle.fontSize
                    //                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                            Material.accent: Material.primary
                    //                                            ButtonGroup.group: radioGroup
                    //                                        }
                    //                                    }
                    //                                }

                    //                                // median frequency
                    //                                Pane
                    //                                {
                    //                                    Material.elevation: 10
                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                    //                                    width: parent.width * 1/2 - 15
                    //                                    height: parent.height * 1/2
                    //                                    anchors.verticalCenter: parent.verticalCenter
                    //                                    Row
                    //                                    {
                    //                                        width: parent.width
                    //                                        height: parent.height
                    //                                        RadioButton
                    //                                        {
                    //                                            id: rdb_median_frequency
                    //                                            anchors.centerIn: parent
                    //                                            text: qsTr("median frequency")
                    //                                            font.family: UIStyle.fontName
                    //                                            //font.pixelSize: _font_size
                    //                                            font.pointSize: UIStyle.fontSize
                    //                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                                            Material.accent: Material.primary
                    //                                            ButtonGroup.group: radioGroup
                    //                                        }
                    //                                    }
                    //                                }
                    //                            }
                    //                        }
                    //                    }
                }

                PageIndicator {
                    count: svSettingsContainer.count
                    currentIndex: svSettingsContainer.currentIndex
                    //                    visible: false
                    anchors.bottom: svSettingsContainer.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Row
            {
                width: parent.width
                height: parent.height * 1/12
                Button
                {
                    id: applyButton
                    anchors.centerIn: parent
                    highlighted: UIStyle.darkTheme
                    text: 'apply'
                    font.family: UIStyle.fontName
                    font.pointSize: UIStyle.fontSize
                    Material.background: UIStyle.themeBlue

                    onClicked:
                    {
                        serialPort.notchActive(chkbox_notch.checked)
                        serialPort.getNotchAb(txt_Ab.text)
                        serialPort.initNotch()
                        serialPort.highActive(chkbox_highpass.checked)
                        serialPort.getHighFl(txt_highpass_fh.text)
                        serialPort.getHighOrder(txt_highpass_order.text)
                        serialPort.initHigh()
                        serialPort.lowActive(chkbox_lowpass.checked)
                        serialPort.getLowFl(txt_lowpass_fl.text)
                        serialPort.getLowOrder(txt_lowpass_order.text)
                        serialPort.initLow()
                    }
                    onHoveredChanged: {
                        if(hovered)
                            applyButton.background.color = UIStyle.buttonHovered
                        else
                            applyButton.background.color = UIStyle.themeBlue
                    }
                }
            }
        }




    }

    //    FileDialog {
    //        id: saveFileDialog
    //        title: "save file"
    //        nameFilters: ["Text files (*.txt)","Csv Files (*.csv)","Xlsx Files (*.xlsx)","Matlab Files (*.mat)"]
    //        selectExisting: false
    //        folder: _file_path
    //        onAccepted: {
    //            console.log("You chose: " + saveFileDialog.fileUrl)
    //            console.log("You chose: " + saveFileDialog.selectedNameFilter)
    //            serialPort.selected_file_for_save=saveFileDialog.fileUrl
    //            serialPort.selected_file_for_save_extention=saveFileDialog.selectedNameFilter
    //            serialPort.callDoWriteFile()
    //        }
    //        onRejected: {
    //            writeFilePopup.close()
    //        }
    //        Component.onCompleted: visible = false
    //    }
    FileDialog {
        id: saveFileDialog
        title: "save file"
        nameFilters: ["Text files (*.txt)","Csv Files (*.csv)","Xlsx Files (*.xlsx)","Matlab Files (*.mat)"]
        selectExisting: false
        folder: _file_path
        onAccepted: {
            console.log("You chose: " + saveFileDialog.fileUrl)
            console.log("You chose: " + saveFileDialog.selectedNameFilter)
            serialPort.selected_file_for_save=saveFileDialog.fileUrl
            serialPort.selected_file_for_save_extention=saveFileDialog.selectedNameFilter
            for(var b=0;b<16;b++)
                active_channels[b]=onlinePlots_grid.children[b].visible?1:0
            serialPort.callDoWriteFile(active_channels)
        }
        onRejected: {
            writeFilePopup.close()
        }
        Component.onCompleted: visible = false
    }
    Popup {
        id: writeFilePopup
        anchors.centerIn: Overlay.overlay
        //        width: 100
        //        height: 100
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose // change closePolicy when write done
        background:  Rectangle {
            radius: 5
            color: UIStyle.darkTheme ? '#1a1f30' : '#edf4ff'
            border.color: UIStyle.darkTheme ? '#373564' : '#0a9696'
            border.width: 1
        }
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
                font.pointSize: UIStyle.fontSize
                font.family: UIStyle.fontName
                checked: true
                Material.accent: Material.Green
                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                onClicked: checked=true
            }

            Text {
                id: writeFilePopupText
                //visible: !_writing_file
                text: qsTr('File name:')
                font.pointSize: UIStyle.fontSize
                font.family: UIStyle.fontName
                color: UIStyle.darkTheme ? '#f7faff':'#2f3033'
            }

            Button {
                id: writeFilePopupButton
                Layout.alignment: Qt.AlignHCenter
                visible: !_writing_file
                text: 'OK'
                font.family:UIStyle.fontName
                font.pointSize: UIStyle.fontSize
                background:  Rectangle {
                    radius: 5
                    color: UIStyle.themeBlue
                }
                highlighted: UIStyle.darkTheme
                onClicked: {
                    writeFilePopup.close()
                }
            }
        }
    }

    Popup {
        id: connectionWarnning
        anchors.centerIn: Overlay.overlay
        //        width: 100
        //        height: 100
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose // change closePolicy when write done
        background:  Rectangle {
            radius: 5
            color: UIStyle.darkTheme ? '#1a1f30' : '#edf4ff'
            border.color: UIStyle.darkTheme ? '#373564' : '#0a9696'
            border.width: 1
        }
        ColumnLayout {
            anchors.fill: parent

            Text {
                id: connectionLost
                text: popupString
                font.family: UIStyle.fontName
                //font.pixelSize: _font_size
                font.pointSize: UIStyle.fontSize
                color: UIStyle.darkTheme ? '#f7faff':'#2f3033'
            }

            Button {
                id: acceptOk
                Layout.alignment: Qt.AlignHCenter
                text: 'ACCEPT'
                font.family: UIStyle.fontName
                //font.pixelSize: _font_size
                font.pointSize: UIStyle.fontSize
                Material.background: UIStyle.themeBlue
                highlighted: UIStyle.darkTheme
                onClicked: {
                    serialPort.disableFilters()
                    UIStyle.connect = false
                    connectionWarnning.close()
                    client.closeSocket()
                    if(acceptOk.text === "ACCEPT"){
                        console.log('accccpted')
                        stackView.pop(null)
                        UIStyle.backgroundImage = 'images/Launcher_page.jpg'
                    }
                }
                onHoveredChanged: {
                    if(hovered)
                        acceptOk.background.color = UIStyle.buttonHovered
                    else
                        acceptOk.background.color = UIStyle.themeBlue
                }
            }
            Button {
                id: decline
                visible: true
                Layout.alignment: Qt.AlignHCenter
                text: 'DECLINE'
                font.family: UIStyle.fontName
                font.pointSize: UIStyle.fontSize
                Material.background: UIStyle.themeBlue
                highlighted: UIStyle.darkTheme
                onClicked: {
                    connectionWarnning.close()
                }
                onHoveredChanged: {
                    if(hovered)
                        decline.background.color = UIStyle.buttonHovered
                    else
                        decline.background.color = UIStyle.themeBlue
                }
            }
        }
    }
}
