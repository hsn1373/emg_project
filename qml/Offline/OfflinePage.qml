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
import QtQuick.Controls 2.3 as QQC2
import ".."
import "../Style"
import QtQuick.Shapes 1.12


Item {

    property int _channels_count: 16

    property var _active_channels: [true,true,true,true,
        true,true,true,true,
        true,true,true,true,
        true,true,true,true]
    property string _chosen_filtered_plots: "0000000000000000"
    property int _font_size: 13
    property int _current_filter_index: 0
    property int _count_of_active_channels:0
    property var _file_path: ""
    property bool _writing_file: false
    property var temporary_offlinePlots_grid: [true,true,true,true,
        true,true,true,true,
        true,true,true,true,
        true,true,true,true]
    property bool applyCheck: false
    property string popuptxt: ''
    property string dropUrl: ''
    property bool selectFile: false //when a file is loading it changes to true
    property bool appliedFilter: false // when filters are applying it changes to true
    property int progressValue: 0
    property int increaseRate: 0
    property bool twoclmn: true




    // this method do proper action when a file is selected
    function fileSelect(selectedUrl,fileFormat){
        for(var i=0;i<16;i++)
            temporary_offlinePlots_grid[i] = offlinePlots_grid.children[i].visible
        serialPort.selected_file_for_save= selectedUrl
        serialPort.selected_file_for_save_extention= fileFormat
        var isValid = serialPort.plot_offline()
        if(isValid){
            selectFile = true
            toolsGrid.visible=false
            emptyRec.visible=false
            select_channels_frame.visible=false
            show_hide_all_channels.visible=false
            grid_checkbox.visible = false
            select_button.visible = false
            select_label.visible = false
            allCheckBox.visible = false
            saveFilteredButton.visible = false
            sfr.visible=false
            readFileProgressGrid.visible=true
            for(var j=0;j<16;j++)
                offlinePlots_grid.children[j].visible = false
            saveFilteredButton.enabled=false
        }
        else{
            popuptxt = qsTr('WRONG FILE IS SELECTED')
            viewResultPopup.open()
        }
    }

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

    SerialPort {
        id: serialPort
        onPlotOfflineData: {

            _count_of_active_channels=0
            //********************
            var ac_ch=serialPort.active_channels.split('');
            console.log(ac_ch)
            for(var i=0;i<offlinePlots_grid.children.length;i++)
            {
                if(offlinePlots_grid.children[i] instanceof Row)
                {
                    if(ac_ch[i]==1)
                    {
                        _active_channels[i]=true
                        _count_of_active_channels++;
                    }
                    else
                        _active_channels[i]=false
                }
            }
            increaseRate = 17 - _count_of_active_channels
            console.log(_active_channels)
            console.log(_count_of_active_channels)
            for(i=0;i<offlinePlots_grid.children.length;i++)
            {
                if(offlinePlots_grid.children[i] instanceof Row)
                {
                    select_channels_grid.children[i].color=_active_channels[i] ? UIStyle.channelGreen : UIStyle.channelRed
                    //                    offlinePlots_grid.children[i].visible=_active_channels[i]
                    //                    console.log(_active_channels[i])
                }
            }
            //********************


            var offlineCustomPlotObjects=[]
            for(i=0;i<offlinePlots_grid.children.length;i++)
            {
                if(offlinePlots_grid.children[i].children[1] !== undefined)
                {
                    if(_active_channels[i])
                    {
                        offlineCustomPlotObjects.push(offlinePlots_grid.children[i].children[1])
                    }
                }
            }

            for(i=0;i<offlineCustomPlotObjects.length;i++)
            {
                current_channel=i
                offlineCustomPlotObjects[i].plotClear()
                offlineCustomPlotObjects[i].plotOfflineData(multichannel_offline_data, this.currentSpeed())
            }
            temporary_offlinePlots_grid=_active_channels
        }

        onPlotFilteredData: {
            var offlineCustomPlotObjects=[]
            var choosedChannels=[]

            for(var i=0;i<offlinePlots_grid.children.length;i++)
            {
                if(offlinePlots_grid.children[i].children[1] !== undefined)
                {
                    if(offlinePlots_grid.children[i].children[2].checked)
                    {
                        offlineCustomPlotObjects.push(offlinePlots_grid.children[i].children[1])
                        choosedChannels.push(i)
                        offlinePlots_grid.children[i].children[0].visible = false
                        offlinePlots_grid.children[i].children[1].visible = false
                        offlinePlots_grid.children[i].children[2].visible = false
                        offlinePlots_grid.children[i].children[3].visible = true
                        offlinePlots_grid.children[i].children[4].visible = true
                    }
                }
            }

            appliedFilter = (choosedChannels.length === 0) ? false : true
            if(choosedChannels.length ==0) {
                popuptxt = qsTr('PLEASE SELECT PLOTS')
                viewResultPopup.open()
            }
            increaseRate = 17 - choosedChannels.length
            console.log(choosedChannels.length)
            for(i=0;i<offlineCustomPlotObjects.length;i++)
            {
                current_channel=choosedChannels[i]
                offlineCustomPlotObjects[i].plotClear()
                offlineCustomPlotObjects[i].plotFilteredData(multichannel_filtered_data,this.currentSpeed(),_current_filter_index)
            }
        }

        onViewResultPopup:
        {
            //viewResultPopupText.text=resultForPopup()
            popuptxt = resultForPopup()
            viewResultPopup.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
            viewResultPopup.open()
        }
        onIncreaseProgress:{
            console.log(readFileProgress.value)
            readFileProgress.value += 16
            readFileProgressText.text = "Loading, Please wait: "+readFileProgress.value * 2/16 + "%"
        }
        onSignalProcessingFinish:{
            emptyRec.visible=true
            select_channels_frame.visible=true
            show_hide_all_channels.visible=true
            readFileProgressGrid.visible=false
            readFileProgress.value = 0
            applyCheck = true
        }
        onWriteFileDone: {
            writeFilePopupText.text = "<font color=\"#616161\">File name: </font>" + lastFilename()
            writeFilePopup.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
            _writing_file = false
        }
        Component.onCompleted:
        {
            console.log("enter")
            //********************
            console.log(serialPort.save_file_path)
            _file_path=serialPort.save_file_path
            //********************
            var ac_ch=serialPort.active_channels.split('');
            console.log(ac_ch)
            for(var i=0;i<offlinePlots_grid.children.length;i++)
            {
                if(offlinePlots_grid.children[i] instanceof Row)
                {
                    if(ac_ch[i]==1)
                        _active_channels[i]=true
                    else
                        _active_channels[i]=false
                }
            }
            for(i=0;i<offlinePlots_grid.children.length;i++)
            {
                if(offlinePlots_grid.children[i] instanceof Row)
                {
                    //                    select_channels_grid.children[i].color=_active_channels[i] ? "greenyellow" : "deeppink"
                    select_channels_grid.children[i].color=_active_channels[i] ? UIStyle.channelGreen : UIStyle.channelRed
                    offlinePlots_grid.children[i].visible=_active_channels[i]
                }
            }
            //********************
            //            console.log(offlinePlots_grid.children.length)
        }
    }



    Grid {
        width: parent.width
        height: parent.height
        columns: 2
        spacing: 5
        padding: 5



        Column
        {
            width: parent.width * 5/6
            height: parent.height

            Rectangle{ // plots backgound
                anchors.fill: parent
                color: 'transparent'
            }


            Grid {
                width: parent.width
                height: parent.height
                y: 35
                rows: 2
                spacing: 5
                padding: 5
                //*******************
                // Top Row
                //*******************
                Row {
                    spacing: 5
                    width: parent.width
                    height: parent.height * 1/10

                    Rectangle // select to view
                    {
                        height: parent.height
                        width: parent.width * 1/12
                        color: 'transparent'

                    }

                    Column{
                        id: toolsGrid
                        height: parent.height
                        width: parent.width * 4/12
                        Row{
                            height: parent.height * 1/2
                            width: parent.width
                            Rectangle{
                                height: parent.height
                                width: parent.width * 2/3
                                color: 'transparent'
                                Label {
                                    id:select_label
                                    anchors.centerIn: parent
                                    text: qsTr("Select File To View :")
                                    font.pointSize: UIStyle.fontSize
                                    font.family: UIStyle.fontName
                                    color: UIStyle.themeColorQtGray1
                                }
                            }

                            Button {
                                id:select_button
                                height: parent.height
                                width: parent.width * 1/3
                                highlighted: UIStyle.darkTheme
                                text: 'select'
                                enabled: !appliedFilter
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                //                                Material.background: Material.Indigo
                                background:  Rectangle {
                                    radius: 9
                                    color: UIStyle.themeBlue
                                    //                                    //border.color: UIStyle.themeBlue
                                    //                                    //border.width: 1
                                }
                                DropArea{
                                    id:fileDropArea_Plot
                                    anchors.fill: parent
                                    onDropped: {
                                        if(drop.proposedAction == Qt.CopyAction){
                                            drop.acceptProposedAction()
                                            dropUrl = drop.urls.toString()
                                            if(dropUrl.includes('.txt'))
                                                fileSelect(dropUrl,"Text files (*.txt)")
                                            else if(dropUrl.includes('.csv'))
                                                fileSelect(dropUrl,"Csv Files (*.csv)")
                                            else if(dropUrl.includes('.xlsx'))
                                                fileSelect(dropUrl,"Xlsx Files (*.xlsx)")
                                            else{
                                                popuptxt = qsTr('WRONG FILE IS SELECTED')
                                                viewResultPopup.open()
                                            }
                                        }
                                    }
                                }
                                onClicked:fileDialogOpen.open()
                                onHoveredChanged: select_button.background.color=hovered?UIStyle.buttonHovered:UIStyle.themeBlue
                            }
                        }
                        Row{
                            height: parent.height * 1/2
                            width: parent.width
                            Rectangle{
                                height: parent.height
                                width: parent.width * 9/50
                                color: 'transparent'
                            }

                            CheckBox {
                                id: grid_checkbox
                                width: parent.width * 1/3
                                height: parent.height
                                text: qsTr("2Column")
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                Material.accent: Material.primary
                                checked: false
                            }

                            CheckBox {
                                id: show_hide_all_channels
                                width: parent.width * 1/3
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
                                            for(var i=0;i<offlinePlots_grid.children.length;i++)
                                            {
                                                if(offlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    //offlinePlots_grid.children[i].state="2"
                                                    offlinePlots_grid.children[i].visible=false
                                                    select_channels_grid.children[i].color= UIStyle.channelRed
                                                }
                                            }
                                        }
                                        else
                                        {
                                            parent.checked=true
                                            for(i=0;i<offlinePlots_grid.children.length;i++)
                                            {
                                                if(offlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    //offlinePlots_grid.children[i].state="1"
                                                    offlinePlots_grid.children[i].visible=true
                                                    select_channels_grid.children[i].color= UIStyle.channelGreen
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            CheckBox {
                                id: allCheckBox
                                width: parent.width * 1/3
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
                                            for(var i=0;i<offlinePlots_grid.children.length;i++)
                                            {
                                                if(offlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    offlinePlots_grid.children[i].children[2].checked=false
                                                }
                                            }
                                        }
                                        else
                                        {
                                            parent.checked=true
                                            for(i=0;i<offlinePlots_grid.children.length;i++)
                                            {
                                                if(offlinePlots_grid.children[i] instanceof Row)
                                                {
                                                    offlinePlots_grid.children[i].children[2].checked=true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                        }
                    }

                    Rectangle{
                        width: parent.width * 1/25
                        height: parent.height
                        color: 'transparent'
                    }


                    Frame
                    {
                        id: select_channels_frame
                        width: parent.width * 4/12
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
                                    color: offlinePlots_grid.children[index].visible ? UIStyle.channelGreen : UIStyle.channelRed
                                    Label {
                                        anchors.centerIn: parent
                                        text: qsTr((index+1).toString())
                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                        font.family: UIStyle.fontName
                                        font.pixelSize: parent.height - 2
                                    }
                                    MouseArea
                                    {
                                        anchors.fill: parent
                                        onClicked:
                                        {
                                            if(offlinePlots_grid.children[index].visible)
                                            {
                                                //offlinePlots_grid.children[index].state="2"
                                                offlinePlots_grid.children[index].visible=false
                                                channel_rec.color= UIStyle.channelRed
                                            }
                                            else
                                            {
                                                //offlinePlots_grid.children[index].state="1"
                                                offlinePlots_grid.children[index].visible=true
                                                channel_rec.color=UIStyle.channelGreen
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }



                    Rectangle{
                        id: sfr
                        width: parent.width * 1/20
                        height: parent.height
                        color: "transparent"
                    }
                    Button {
                        id: saveFilteredButton
                        text: "Save \n\n Filtered \n\n Data"
                        font.family: UIStyle.fontName
                        font.pointSize: UIStyle.fontSize
                        Material.background: UIStyle.themeBlue
                        highlighted: UIStyle.darkTheme
                        enabled: false
                        onClicked: {
                            writeFilePopup.closePolicy = Popup.NoAutoClose
                            _writing_file = true
                            writeFilePopup.open()
                            saveFileDialog.open()
                        }
                        onHoveredChanged: {
                            saveFilteredButton.background.color = hovered ? UIStyle.buttonHovered : UIStyle.themeBlue
                        }
                    }


                    Rectangle
                    {
                        id:emptyRec
                        width: parent.width * 1/12
                        height: parent.height
                        color: 'transparent'
                    }

                    Grid
                    {
                        id:readFileProgressGrid
                        width: parent.width * 1/2
                        height: parent.height
                        columns: 3
                        visible: false
                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light

                        Rectangle
                        {
                            height: parent.height
                            width: parent.width * 3/10
                            color: 'transparent'
                        }
                        ProgressBar{
                            id: readFileProgress
                            height: parent.height
                            width: parent.width * 5/10
                            from:0
                            to:800
                            value: 0
                            Material.accent: UIStyle.darkTheme ?  '#00e676' : '#2e7d32'



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
                                font.family:UIStyle.fontName
                                font.pointSize: UIStyle.fontSize
                                anchors.centerIn: parent
                                text: "Loading, Please wait: 0%"

                            }
                        }
                    }

                    FileDialog {
                        id: fileDialogOpen
                        title: "Open file"
                        nameFilters: ["Text files (*.txt)","Csv Files (*.csv)","Xlsx Files (*.xlsx)"]
                        folder: _file_path
                        onAccepted: {
                            console.log("You chose: " + fileDialogOpen.fileUrl)
                            fileSelect(fileDialogOpen.fileUrl,fileDialogOpen.selectedNameFilter)
                        }
                        onRejected: {
                        }
                        Component.onCompleted: visible = false
                    }
                }
                // Bottom Row
                //*******************
                Row {
                    id: offlineRow2
                    width: parent.width
                    height: parent.height * 9/10
                    clip: true

                    DropArea{
                        id:fileDropArea_Button
                        anchors.fill: parent
                        onDropped: {
                            if(drop.proposedAction == Qt.CopyAction){
                                drop.acceptProposedAction()
                                dropUrl = drop.urls.toString()
                                if(dropUrl.includes('.txt'))
                                    fileSelect(dropUrl,"Text files (*.txt)")
                                else if(dropUrl.includes('.csv'))
                                    fileSelect(dropUrl,"Csv Files (*.csv)")
                                else if(dropUrl.includes('.xlsx'))
                                    fileSelect(dropUrl,"Xlsx Files (*.xlsx)")
                                else{
                                    popuptxt = qsTr('WRONG FILE IS SELECTED')
                                    viewResultPopup.open()
                                }
                            }
                        }
                    }
                    Flickable {
                        anchors.fill: parent
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.DragOverBounds
                        clip: true
                        contentHeight: offlinePlots_grid.height
                        Grid {
                            id: offlinePlots_grid
                            columns: grid_checkbox.checked ? 2 : 1
                            width: parent.width
                            Repeater {
                                id: plotRepeater
                                model: _channels_count
                                Row {
                                    id: offlineCustomPlot_row
                                    property int itemIndex: index
                                    width: grid_checkbox.checked ? (offlineRow2.width - 1/10*offlineRow2.width)/2 : offlineRow2.width - 1/10*offlineRow2.width
                                    height: offlineRow2.height / 3
                                    spacing: 3
                                    states: [
                                        State {
                                            //                                            PropertyChanges { target: offlineCustomPlot_row; width:0  }
                                            when: !offlinePlots_grid.children[index].visible
                                            PropertyChanges { target: offlineCustomPlot_row; opacity: 0.0  }
                                        },
                                        State {
                                            //                                            PropertyChanges { target: offlineCustomPlot_row; width:grid_checkbox.checked ? (offlineRow2.width - 1/10*offlineRow2.width)/2 : offlineRow2.width - 1/10*offlineRow2.width  }
                                            when: offlinePlots_grid.children[index].visible
                                            PropertyChanges { target: offlineCustomPlot_row; opacity: 1.0  }
                                        }
                                    ]

                                    transitions: Transition {
                                        NumberAnimation { property: "opacity"; duration: 500}
                                    }

                                    Rectangle
                                    {
                                        color: "transparent"
                                        width: parent.width * 1/210
                                        height: parent.height
                                        Label {
                                            anchors.centerIn: parent
                                            text: qsTr((offlineCustomPlot_row.itemIndex+1).toString())
                                            color: UIStyle.channelGreen
                                        }
                                    }
                                    CustomPlotItem {
                                        width: parent.width * 198/210
                                        height: parent.height
                                        Component.onCompleted: {
                                            initCustomPlot()
                                        }

                                        onIncreaseProgress:{
                                            if(selectFile){
                                                readFileProgress.value += increaseRate
                                                readFileProgressText.text = "Loading, Please wait: "+readFileProgress.value * 2/16 + "%"
                                            }else if(appliedFilter){
                                                progressValue += increaseRate
                                            }
                                        }
                                        onLoadOfflineDataFinish:{
                                            if(selectFile){
                                                toolsGrid.visible=true
                                                emptyRec.visible=true
                                                select_channels_frame.visible=true
                                                show_hide_all_channels.visible=true
                                                grid_checkbox.visible=true
                                                select_button.visible=true
                                                select_label.visible=true
                                                allCheckBox.visible = true
                                                saveFilteredButton.visible=true
                                                sfr.visible=true
                                                readFileProgressGrid.visible=false
                                                readFileProgress.value = 0
                                                for(var j=0;j<16;j++)
                                                    if(temporary_offlinePlots_grid[j]){
                                                        offlinePlots_grid.children[j].visible = true
                                                        offlinePlots_grid.children[j].children[3].visible = false
                                                    }
                                                applyCheck = true
                                                selectFile = false
                                            }else if(appliedFilter){
                                                for(j=0;j<16;j++){
                                                    if(offlinePlots_grid.children[j].children[3].visible===true){
                                                        offlinePlots_grid.children[j].children[0].visible =true
                                                        offlinePlots_grid.children[j].children[1].visible =true
                                                        offlinePlots_grid.children[j].children[2].visible =true
                                                        offlinePlots_grid.children[j].children[3].visible = false
                                                        offlinePlots_grid.children[j].children[4].visible = false
                                                    }
                                                }
                                                appliedFilter = false
                                                saveFilteredButton.enabled = true
                                                progressValue = 0
                                            }
                                            if(!twoclmn){
                                                grid_checkbox.checked = !grid_checkbox.checked
                                                twoclmn = true
                                            }
                                        }

                                    }
                                    CheckBox {
                                        width: parent.width * 11/210
                                        height: parent.height
                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                        Material.accent: Material.primary
                                        text: qsTr("")
                                    }

                                    Rectangle{
                                        color: "transparent"
                                        height: parent.height
                                        width: parent.width * 3/10
                                        visible: false
                                    }

                                    ProgressBar{
                                        id: plotprogress
                                        visible: false
                                        height: parent.height
                                        width: parent.width * 4/10
                                        from:0
                                        to:800
                                        value: progressValue
                                        Material.accent: UIStyle.darkTheme ?  '#fa0000' : '#b40000'
                                    }

                                }
                            }
                        }
                        ScrollBar.vertical: ScrollBar{
                            position: 1.0
                            policy: ScrollBar.AlwaysOn
                            snapMode: ScrollBar.SnapAlways
                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        }
                    }
                }
            }
        }

        Column
        {
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
                    TabButton {
                        text: qsTr("Time")
                        font.family:UIStyle.fontName
                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        Material.accent: Material.Indigo
                        font.pointSize: UIStyle.fontSize - 2
                    }
                    //                    TabButton {
                    //                        text: qsTr("Time 2")
                    //                        font.family:UIStyle.fontName
                    //                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                    //                        Material.accent: Material.Indigo
                    //                        font.pointSize: UIStyle.fontSize - 2
                    //                    }
                    TabButton {
                        width: parent.width * 3/8
                        text: qsTr("Frequency")
                        font.family:UIStyle.fontName
                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        Material.accent: Material.Indigo
                        font.pointSize: UIStyle.fontSize - 2
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
                                //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
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
                                //Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
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
                                //Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
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

                    SwipeViewPage {
                        id: signalProcessingPage2



                        ButtonGroup { id: radioGroup }


                        Flickable {
                            height: parent.height
                            width: parent.height
                            flickableDirection: Flickable.VerticalFlick
                            boundsBehavior: Flickable.DragOverBounds
                            clip: true
                            contentHeight: signalProcessingPage2.height * 2.5
                            contentWidth: signalProcessingPage2.width
                            Grid{
                                width: parent.width
                                height: parent.height
                                Column{
                                    width: parent.width - 15
                                    height: parent.height
                                    spacing: 10
                                    padding: 5
                                    //*************************************************
                                    // row 1
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 2/15
                                        spacing: 10
                                        padding: 20

                                        // rms
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Column
                                            {
                                                width: parent.width
                                                height: parent.height
                                                Row
                                                {
                                                    width: parent.width
                                                    height: parent.height * 1/3
                                                    RadioButton
                                                    {
                                                        id: rdb_rms
                                                        anchors.centerIn: parent
                                                        text: qsTr("rms")
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                        font.pointSize: UIStyle.fontSize
                                                        ButtonGroup.group: radioGroup
                                                        //                                                onCheckedChanged:
                                                        //                                                {
                                                        //                                                    var rdb_objs=[rdb_integral,rdb_mean_absolute_value,
                                                        //                                                             rdb_moving_averaging,rdb_zero_crossing]
                                                        //                                                    for(var i=0;i<4;i++)
                                                        //                                                    {
                                                        //                                                        rdb_integral.ch
                                                        //                                                        if(rdb_rms.checked)
                                                        //                                                            rdb_objs[i].che
                                                        //                                                    }
                                                        //                                                }
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
                                                        width: parent.width * 2/3
                                                        height: parent.height
                                                        Label {
                                                            anchors.left: parent.leftradiobutton
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: qsTr("windowLength")
                                                            font.family:UIStyle.fontName
                                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                            font.pointSize: UIStyle.fontSize
                                                        }
                                                    }
                                                    TextField
                                                    {
                                                        id: txt_rms_windowlen
                                                        width: parent.width * 1/3 - 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: qsTr("30")
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
                                                        width: parent.width * 2/3
                                                        height: parent.height
                                                        Label {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: qsTr("overlap")
                                                            font.family:UIStyle.fontName
                                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                            font.pointSize: UIStyle.fontSize
                                                        }
                                                    }
                                                    TextField
                                                    {
                                                        id: txt_rms_overlap
                                                        width: parent.width * 1/3 - 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: qsTr("10")
                                                        font.family:UIStyle.fontName
                                                        font.pointSize: UIStyle.fontSize
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                    }
                                                }

                                            }

                                        }
                                    }
                                    //*******************************************
                                    // row 2
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 2/15
                                        spacing: 10
                                        padding: 20

                                        // mean absolute value
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Column
                                            {
                                                width: parent.width
                                                height: parent.height
                                                Row
                                                {
                                                    width: parent.width
                                                    height: parent.height * 1/3
                                                    RadioButton
                                                    {
                                                        id: rdb_mean_absolute_value
                                                        anchors.centerIn: parent
                                                        //                                                checked: true
                                                        text: qsTr("mean absolute value")
                                                        font.family:UIStyle.fontName
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                        ButtonGroup.group: radioGroup
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
                                                        width: parent.width * 2/3
                                                        height: parent.height
                                                        Label {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: qsTr("windowLength")
                                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                            font.family: UIStyle.fontName
                                                            font.pointSize: UIStyle.fontSize
                                                        }
                                                    }
                                                    TextField
                                                    {
                                                        id: txt_mean_absolute_value_windowlen
                                                        width: parent.width * 1/3 - 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: qsTr("30")
                                                        font.family: UIStyle.fontName
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
                                                        width: parent.width * 2/3
                                                        height: parent.height
                                                        Label {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: qsTr("overlap")
                                                            font.family: UIStyle.fontName
                                                            font.pointSize: UIStyle.fontSize
                                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        }
                                                    }
                                                    TextField
                                                    {
                                                        id: txt_mean_absolute_value_overlap
                                                        width: parent.width * 1/3 - 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: qsTr("10")
                                                        font.family: UIStyle.fontName
                                                        font.pointSize: UIStyle.fontSize
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                    }
                                                }

                                            }

                                        }


                                    }
                                    //*******************************************
                                    // row 3
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/10
                                        spacing: 10
                                        padding: 20

                                        // zero crossing
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Row
                                            {
                                                width: parent.width
                                                height: parent.height
                                                RadioButton
                                                {
                                                    id: rdb_zero_crossing
                                                    anchors.centerIn: parent
                                                    //                                                checked: true
                                                    text: qsTr("zero crossing")
                                                    font.family: UIStyle.fontName
                                                    font.pointSize: UIStyle.fontSize
                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                    Material.accent: Material.primary
                                                    ButtonGroup.group: radioGroup
                                                }
                                            }
                                        }
                                    }
                                    // row 4
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 2/15
                                        spacing: 10
                                        padding: 20
                                        // integral
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Column
                                            {
                                                width: parent.width
                                                height: parent.height
                                                Row
                                                {
                                                    width: parent.width
                                                    height: parent.height * 1/3
                                                    RadioButton
                                                    {
                                                        id: rdb_integral
                                                        anchors.centerIn: parent
                                                        //                                                checked: true
                                                        text: qsTr("integral")
                                                        font.family:UIStyle.fontName
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                        font.pointSize: UIStyle.fontSize
                                                        ButtonGroup.group: radioGroup
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
                                                        width: parent.width * 2/3
                                                        height: parent.height
                                                        Label {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: qsTr("windowLength")
                                                            font.family:UIStyle.fontName
                                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                            font.pointSize: UIStyle.fontSize
                                                        }
                                                    }
                                                    TextField
                                                    {
                                                        id: txt_integral_windowlen
                                                        width: parent.width * 1/3 - 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: qsTr("30")
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
                                                        width: parent.width * 2/3
                                                        height: parent.height
                                                        Label {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: qsTr("overlap")
                                                            font.family:UIStyle.fontName
                                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                            font.pointSize: UIStyle.fontSize
                                                        }
                                                    }
                                                    TextField
                                                    {
                                                        id: txt_integral_overlap
                                                        width: parent.width * 1/3 - 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: qsTr("10")
                                                        font.family:UIStyle.fontName
                                                        font.pointSize: UIStyle.fontSize
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                    }
                                                }

                                            }

                                        }
                                    }
                                    //*******************************************
                                    // row 5
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 2/15
                                        spacing: 10
                                        padding: 20
                                        // moving averaging
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Column
                                            {
                                                width: parent.width
                                                height: parent.height
                                                Row
                                                {
                                                    width: parent.width
                                                    height: parent.height * 1/3
                                                    RadioButton
                                                    {
                                                        id: rdb_moving_averaging
                                                        anchors.centerIn: parent
                                                        //                                                checked: true
                                                        text: qsTr("moving averaging")
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                        ButtonGroup.group: radioGroup
                                                        font.family: UIStyle.fontName
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
                                                        width: parent.width * 2/3
                                                        height: parent.height
                                                        Label {
                                                            anchors.left: parent.left
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: qsTr("value")
                                                            font.family: UIStyle.fontName
                                                            font.pointSize: UIStyle.fontSize
                                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        }
                                                    }
                                                    TextField
                                                    {
                                                        id: txt_moving_averaging_value
                                                        width: parent.width * 1/3 - 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: qsTr("150")
                                                        font.family: UIStyle.fontName
                                                        font.pointSize: UIStyle.fontSize
                                                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                        Material.accent: Material.primary
                                                    }
                                                }
                                                Row
                                                {
                                                    width: parent.width
                                                    height: parent.height * 1/3
                                                    Rectangle
                                                    {
                                                        color: "transparent"
                                                        width: parent.width
                                                        height: parent.height
                                                    }
                                                }

                                            }

                                        }
                                    }
                                    //*******************************************
                                    // row 6
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/10
                                        spacing: 10
                                        padding: 20

                                        // rectifiction
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Row
                                            {
                                                width: parent.width
                                                height: parent.height
                                                RadioButton
                                                {
                                                    id: rdb_rectifiction
                                                    anchors.centerIn: parent
                                                    text: qsTr("rectifiction")
                                                    font.family: UIStyle.fontName
                                                    font.pointSize: UIStyle.fontSize
                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                    Material.accent: Material.primary
                                                    ButtonGroup.group: radioGroup
                                                }
                                            }
                                        }
                                    }
                                    // row 7
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height * 1/10
                                        spacing: 10
                                        padding: 20

                                        // spectrum
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Row
                                            {
                                                width: parent.width
                                                height: parent.height
                                                RadioButton
                                                {
                                                    id: rdb_spectrum
                                                    anchors.centerIn: parent
                                                    //                                                checked: true
                                                    text: qsTr("spectrum")
                                                    font.family: UIStyle.fontName
                                                    font.pointSize: UIStyle.fontSize
                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                    Material.accent: Material.primary
                                                    ButtonGroup.group: radioGroup
                                                }
                                            }
                                        }
                                    }

                                    //*******************************************
                                    // row 8
                                    Row{
                                        width: parent.width
                                        height: parent.height * 1/10
                                        spacing: 10
                                        padding: 20
                                        // power spectrum
                                        Pane
                                        {
                                            Material.elevation: 10
                                            //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                            background: Rectangle{
                                                width: parent.width
                                                height: parent.height
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: UIStyle.borderGrey2
                                            }
                                            width: parent.width * 4/5
                                            height: parent.height
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            Row
                                            {
                                                width: parent.width
                                                height: parent.height
                                                RadioButton
                                                {
                                                    id: rdb_power_spectrum
                                                    anchors.centerIn: parent
                                                    text: qsTr("power spectrum")
                                                    font.family: UIStyle.fontName
                                                    font.pointSize: UIStyle.fontSize
                                                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                                    Material.accent: Material.primary
                                                    ButtonGroup.group: radioGroup

                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            //                                ScrollBar {
                            //                                    id: vbar
                            //                                    height: parent.width * 2/5
                            //                                    Material.theme: Material.Purple
                            //                                    hoverEnabled: true
                            //                                    active: hovered || pressed
                            //                                    orientation: Qt.Vertical
                            //                                    size: frame.height / content.height
                            //                                    anchors.top: parent.top
                            //                                    anchors.left: parent.left
                            //                                    anchors.bottom: parent.bottom
                            //                                }

                        }

                    }


                    SwipeViewPage {
                        id: signalProcessingPage3

                        Column {
                            width: parent.width
                            height: parent.height
                            spacing: 10
                            padding: 5

                            //*******************************************
                            // row 1
                            Row{
                                width: parent.width
                                height: parent.height * 1/6
                            }
                            //*******************************************
                            // row 2
                            Row
                            {
                                width: parent.width
                                height: parent.height * 1/4
                                spacing: 10
                                padding: 20

                                // mean frequency
                                Pane
                                {
                                    Material.elevation: 10
                                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                    background: Rectangle{
                                        width: parent.width
                                        height: parent.height
                                        radius: 5
                                        color: "transparent"
                                        border.width: 1
                                        border.color: UIStyle.borderGrey2
                                    }
                                    width: parent.width * 4/5
                                    height: parent.height
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height
                                        RadioButton
                                        {
                                            id: rdb_mean_frequency
                                            anchors.centerIn: parent
                                            text: qsTr("mean frequency")
                                            font.family: UIStyle.fontName
                                            font.pointSize: UIStyle.fontSize
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                            ButtonGroup.group: radioGroup
                                        }
                                    }
                                }
                            }

                            //*******************************************
                            // row 3
                            Row{
                                width: parent.width
                                height: parent.height * 1/6
                            }


                            //*******************************************
                            // row 4
                            Row{
                                height: parent.height * 1/4
                                width: parent.width
                                spacing: 10
                                padding: 20
                                // median frequency
                                Pane
                                {
                                    Material.elevation: 10
                                    //                                    Material.background: UIStyle.darkTheme ? '#2e2e36': '#f0f0f0'
                                    background: Rectangle{
                                        width: parent.width
                                        height: parent.height
                                        radius: 5
                                        color: "transparent"
                                        border.width: 1
                                        border.color: UIStyle.borderGrey2
                                    }
                                    width: parent.width * 4/5
                                    height: parent.height
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Row
                                    {
                                        width: parent.width
                                        height: parent.height
                                        RadioButton
                                        {
                                            id: rdb_median_frequency
                                            anchors.centerIn: parent
                                            text: qsTr("median frequency")
                                            font.family: UIStyle.fontName
                                            font.pointSize: UIStyle.fontSize
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            Material.accent: Material.primary
                                            ButtonGroup.group: radioGroup
                                        }
                                    }
                                } //up to here
                            }
                        }
                    }

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
                    enabled: !appliedFilter
                    text: 'apply'
                    font.family: UIStyle.fontName
                    font.pointSize: UIStyle.fontSize
                    Material.background: UIStyle.themeBlue
                    onClicked:
                    {
                        _chosen_filtered_plots=""
                        if(!(radioGroup.checkState !== 0 || chkbox_notch.checked || chkbox_lowpass.checked || chkbox_highpass.checked)){
                            popuptxt = qsTr('PLEASE SELECT FILTER')
                            viewResultPopup.open()
                        }else if(applyCheck){
                            for(var t=0;t<16;t++)
                                _chosen_filtered_plots+=plotRepeater.itemAt(t).children[2].checked?'1':'0'
                            serialPort.notch_status=chkbox_notch.checked
                            serialPort.lowpass_status=chkbox_lowpass.checked
                            serialPort.highpass_status=chkbox_highpass.checked
                            serialPort.notch_ab=txt_Ab.text
                            serialPort.bandpass_fh=txt_highpass_fh.text
                            serialPort.bandpass_fl=txt_lowpass_fl.text

                            if(chkbox_highpass.checked && !chkbox_lowpass.checked)
                            {
                                serialPort.bandpass_order=txt_highpass_order.text
                            }
                            else if(chkbox_lowpass.checked && !chkbox_highpass.checked)
                            {
                                serialPort.bandpass_order=txt_lowpass_order.text
                            }
                            else if(chkbox_lowpass.checked && chkbox_highpass.checked)
                            {
                                serialPort.bandpass_order=txt_lowpass_order.text
                            }


                            if(rdb_rectifiction.checked)
                            {
                                serialPort.current_filter_index=2
                                _current_filter_index=2
                            }
                            else if(rdb_rms.checked)
                            {
                                serialPort.timeanalysis_windowlength=txt_rms_windowlen.text
                                serialPort.timeanalysis_overlap=txt_rms_overlap.text
                                serialPort.current_filter_index=3
                                _current_filter_index=3
                            }
                            else if(rdb_integral.checked)
                            {
                                serialPort.timeanalysis_windowlength=txt_integral_windowlen.text
                                serialPort.timeanalysis_overlap=txt_integral_overlap.text
                                serialPort.current_filter_index=4
                                _current_filter_index=4
                            }
                            else if(rdb_mean_absolute_value.checked)
                            {
                                serialPort.timeanalysis_windowlength=txt_mean_absolute_value_windowlen.text
                                serialPort.timeanalysis_overlap=txt_mean_absolute_value_overlap.text
                                serialPort.current_filter_index=5
                                _current_filter_index=5
                            }
                            else if(rdb_zero_crossing.checked)
                            {
                                serialPort.current_filter_index=6
                                _current_filter_index=6
                            }
                            else if(rdb_moving_averaging.checked)
                            {
                                serialPort.moving_averaging_val=txt_moving_averaging_value.text
                                serialPort.current_filter_index=7
                                _current_filter_index=7
                            }
                            else if(rdb_spectrum.checked)
                            {
                                serialPort.current_filter_index=8
                                _current_filter_index=8
                            }
                            else if(rdb_power_spectrum.checked)
                            {
                                serialPort.current_filter_index=9
                                _current_filter_index=9
                            }
                            else if(rdb_mean_frequency.checked)
                            {
                                serialPort.current_filter_index=10
                                _current_filter_index=10
                            }
                            else if(rdb_median_frequency.checked)
                            {
                                serialPort.current_filter_index=11
                                _current_filter_index=11
                            }

                            var choosedChannels=[]
                            for(var i=0;i<offlinePlots_grid.children.length;i++)
                            {
                                if(offlinePlots_grid.children[i] instanceof Row)
                                {
                                    if(offlinePlots_grid.children[i].children[2].checked)
                                        choosedChannels.push(i)
                                }
                            }
                            serialPort.applyFilter(choosedChannels)
                        }else if(!applyCheck){
                            popuptxt = qsTr('NOTHING UPLOADED YET')
                            viewResultPopup.open()
                        }
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
            serialPort.writeFilteredInFile(_chosen_filtered_plots)
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
                text: qsTr("Write to file done!")
                font.pointSize: UIStyle.fontSize
                font.family: UIStyle.fontName
                checked: true
                Material.accent: Material.primary
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
                    writeFilePopupText.text = ""
                }
                onHoveredChanged: {
                    if(hovered)
                        writeFilePopupButton.background.color = UIStyle.buttonHovered
                    else
                        writeFilePopupButton.background.color = UIStyle.themeBlue
                }
            }
        }
    }
    Popup {
        id: viewResultPopup
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
                id: viewResultPopupText
                text: popuptxt
                font.family: UIStyle.fontName
                font.pointSize: UIStyle.fontSize
                color: UIStyle.darkTheme ? '#f7faff':'#2f3033'
            }

            Button {
                id: viewResultPopupButton
                Layout.alignment: Qt.AlignHCenter
                text: 'OK'
                font.family: UIStyle.fontName
                font.pointSize: UIStyle.fontSize
                Material.background: UIStyle.themeBlue
                highlighted: UIStyle.darkTheme
                onClicked: {
                    viewResultPopup.close()
                }
                onHoveredChanged: {
                    if(hovered)
                        viewResultPopupButton.background.color = UIStyle.buttonHovered
                    else
                        viewResultPopupButton.background.color = UIStyle.themeBlue
                }
            }
        }
    }
}
