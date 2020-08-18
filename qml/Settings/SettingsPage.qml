import QtQuick 2.12
import QtQuick.Controls 2.3 as QQC2
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import DefaultSettings 1.0
import QtQuick.Controls.Material 2.12
import QtQuick.Shapes 1.12
import "../.."
import ".."
import "../Style"
import CustomPlot 1.0
import SerialPort 1.0


Item {
    CustomPlotItem{
        id: plot
    }
    SerialPort{
        id: serialport
    }

    //property int _fontSize: 10


    property int _channels_count: 16

    property var _active_channels: [true,true,true,true,
        true,true,true,true,
        true,true,true,true,
        true,true,true,true]

    property bool fontChange: false

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

    //**************************
    Grid {
        columns: 8
        anchors.fill: parent
        Repeater {
            model: 40
            Image {
                source: "../../images/groovepaper.png"
            }
        }
    }


    DefaultSettings
    {
        id: default_settings

        onViewResultPopup:
        {
            //viewResultPopupText.text= resultForPopup()
            //"<font color=\"#616161\">" + resultForPopup() + "</font>"
            viewResultPopup.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
            viewResultPopup.open()
        }

        Component.onCompleted:
        {
            console.log("enter")
            cmb_speeds.model=default_settings.speed_list
            cmb_speeds.currentIndex=default_settings.current_speed_index
            //********************
            txt_save_file_path.text=default_settings.save_file_path
            //********************
            var ac_ch=default_settings.active_channels.split('');
            console.log(ac_ch)
            for(var i=0;i<_channels_count;i++)
            {
                if(ac_ch[i]==1)
                    _active_channels[i]=true
                else
                    _active_channels[i]=false
            }
            for(i=0;i<_channels_count;i++)
            {
                select_channels_grid.children[i].color=_active_channels[i] ? UIStyle.channelGreen : UIStyle.channelRed
            }
            //********************
        }
    }

    Grid{
        width: parent.width
        height: parent.height
        id: settingsPage1
        property alias darkThemeSwitch: darkThemeSwitch

        Column {
            height: parent.height
            width: parent.width
            spacing: 50

            // empty row on the top
            Row{
                width: parent.width
                height: parent.height * 1/20
            }

            // select speed row
            Row {
                height: parent.height * 1/10
                width: parent.width
                //spacing: 10
                Rectangle
                {
                    height: parent.height
                    width: parent.width * 1/3
                    color: "transparent"
                }
                Rectangle{
                    width: parent.width * 1/3
                    height: parent.height
                    anchors.centerIn: parent
                    color: "transparent"
                    Row{
                        width: parent.width
                        height: parent.height
                        spacing: 20
                        Rectangle{
                            width: parent.width * 2/10
                            height: parent.height
                            color: "transparent"
                            Label {
                                anchors.centerIn: parent
                                text: qsTr("Speed")
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                            }
                        }

                        ComboBox {
                            id: cmb_speeds
                            width: parent.width * 6/10
                            height: parent.height * 1/2
                            Material.accent: Material.primary
                            font.pointSize:UIStyle.fontSize
                            font.family:UIStyle.fontName
                            background: Rectangle{
                                width: parent.width
                                height: parent.height
                                color: UIStyle.comboBackground
                                border.width: 0.5
                                border.color: UIStyle.borderGrey
                            }
                            //                        model: serialPort.speed_list
                            anchors.verticalCenter: parent.verticalCenter
                            onActivated: {
                                serialport.getSpeed(cmb_speeds.currentText)
                            }
                        }
                    }

                    //
                }


            }

            // file path row
            Row {
                height: parent.height * 1/10
                width: parent.width
                //spacing: 50
                Rectangle
                {
                    width: parent.width
                    height: parent.height
                    color: "transparent"
                }
                Rectangle{
                    width: parent.width * 1/3
                    height: parent.height
                    anchors.centerIn: parent
                    color: "transparent"
                    Row{
                        width: parent.width
                        height: parent.height
                        spacing: 30
                        Rectangle{
                            width: parent.width * 2/10
                            height: parent.height
                            color: "transparent"
                            Label {
                                anchors.centerIn: parent
                                text: qsTr("save file path")
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                            }
                        }
                        TextField
                        {
                            id: txt_save_file_path
                            width: parent.width * 4/10
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("")
                            font.pointSize: UIStyle.fontSize
                            font.family: UIStyle.fontName
                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                            Material.accent: Material.primary
                        }
                        Rectangle{
                            width: parent.width * 1/50
                            height: parent.height
                            color: "transparent"
                        }

                        Button {
                            id: changeButton
                            anchors.verticalCenter: parent.verticalCenter
                            highlighted: UIStyle.darkTheme
                            background:  Rectangle {
                                radius: 5
                                color: UIStyle.themeBlue
                            }
                            text: 'change'
                            font.pointSize: UIStyle.fontSize
                            font.family: UIStyle.fontName
                            onClicked: {

                            }
                            onHoveredChanged: {
                                if(hovered)
                                    changeButton.background.color = UIStyle.buttonHovered
                                else
                                    changeButton.background.color = UIStyle.themeBlue
                            }
                        }
                    }
                }
            }

            // active channels row
            Row {
                height: parent.height * 2/10
                width: parent.width
                //spacing: 50
                Rectangle
                {
                    height: parent.height
                    width: parent.width * 1/3
                    color: "transparent"

                }
                Rectangle{
                    width: parent.width * 1/3
                    height: parent.height
                    anchors.centerIn: parent
                    color: "transparent"
                    Row{
                        width: parent.width
                        height: parent.height
                        spacing: 10
                        Rectangle{
                            width: parent.width * 2/10
                            height: parent.height
                            color: "transparent"
                            Label {
                                anchors.centerIn: parent
                                text: qsTr("active channels")
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                                Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                            }
                        }
                        Frame
                        {
                            id: select_channels_fram
                            width: parent.width * 3/4
                            height: parent.height * 9/10
                            y: 10
                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light // instead of background
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
                                        color: _active_channels[index] ? UIStyle.channelGreen : UIStyle.channelRed
                                        Label {
                                            anchors.centerIn: parent
                                            text: qsTr((index+1).toString())
                                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                                            font.pixelSize: parent.height - 2
                                        }
                                        MouseArea
                                        {
                                            anchors.fill: parent
                                            onClicked:
                                            {
                                                if(_active_channels[index])
                                                {
                                                    _active_channels[index]=false
                                                    channel_rec.color= UIStyle.channelRed
                                                }
                                                else
                                                {
                                                    _active_channels[index]=true
                                                    channel_rec.color= UIStyle.channelGreen
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // theme and text row
            Row{
                height: parent.height * 1/10
                width: parent.width
                spacing: 10
                Rectangle
                {
                    height: parent.height
                    width: parent.width * 1/3
                    color: "transparent"
                }

                Rectangle{
                    height: parent.height
                    width: parent.width * 1/10
                    color: "transparent"
                    QQC2.Switch {
                        id: darkThemeSwitch
                        //                            height: parent.height
                        //                            width: parent.width
                        anchors.centerIn: parent
                        text: 'Dark Mode'
                        font.pointSize: UIStyle.fontSize
                        font.family: UIStyle.fontName
                        Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        //                        Material.accent: UIStyle.darkTheme ? Material.Green : Material.LightGreen
                        Material.accent: Material.DeepPurple
                        checked: UIStyle.darkTheme ? true : false

                        onToggled: {
                            UIStyle.darkTheme = !UIStyle.darkTheme
                            for(var k=0;k<16;k++)
                                select_channels_grid.children[k].color=_active_channels[k] ? UIStyle.channelGreen : UIStyle.channelRed
                            changeButton.background.color = UIStyle.themeBlue
                            save_changesButton.background.color = UIStyle.themeBlue
                            reset.background.color = UIStyle.themeBlue
                            viewResultPopupButton.background.color = UIStyle.themeBlue
                            plot.writedark(1)
                        }
                    }
                }
                Rectangle{
                    height: parent.height
                    width: parent.width * 1/50
                    color: "transparent"
                }
                Rectangle{
                    width: parent.width * 2/10
                    height: parent.height
                    color: "transparent"
                    Row{
                        width: parent.width
                        height: parent.height
                        spacing: 15
                        Rectangle{
                            width: parent.width * 1/10
                            height: parent.height
                            color: "transparent"
                            Label{
                                id:fontLabe
                                anchors.centerIn: parent
                                text: qsTr('font:')
                                font.pointSize: UIStyle.fontSize
                                font.family: UIStyle.fontName
                                color: UIStyle.themeColorQtGray1
                            }
                        }
                        ComboBox{
                            id: fontCombo
                            y: parent.height / 4
                            width: parent.width * 1/3
                            height: parent.height * 3/5
                            model: UIStyle.fontArray
                            Material.accent: Material.primary
                            font.pointSize:UIStyle.fontSize
                            font.family:UIStyle.fontName
                            background: Rectangle{
                                width: parent.width
                                height: parent.height
                                radius: parent.height * 1/2
                                color: UIStyle.comboBackground
                                border.width: 0.5
                                border.color: UIStyle.borderGrey
                            }
                            onCurrentTextChanged: {
                                UIStyle.fontName = currentText
                                UIStyle.fontArray[UIStyle.fontArray.indexOf(currentText)] = UIStyle.fontArray[0]
                                UIStyle.fontArray[0] = UIStyle.fontName
                                if(fontChange){
                                    switch(currentText){
                                    case 'Kristen ITC' :
                                        UIStyle.fontSize = 8
                                        break
                                    case 'Arial':
                                        UIStyle.fontSize = 9
                                        break
                                    default:
                                        UIStyle.fontSize = 10
                                        break
                                    }
                                }
                                fontChange = true
                            }
                        }
                        Slider{
                            id: fontSlider
                            y: parent.height / 3
                            width: parent.width * 1/3
                            from: 5
                            to: 15
                            stepSize: 1
                            value: UIStyle.fontSize
                            //                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                            //                            Material.accent: Material.DeepPurple
                            onMoved: UIStyle.fontSize = value
                        }

                        //                        QQC2.Slider {
                        //                            id: fontSlider
                        //                            y: parent.height / 4
                        //                            width: parent.width * 1/3
                        //                            from: 5
                        //                            to: 15
                        //                            stepSize: 1
                        //                            value: UIStyle.fontSize
                        ////                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        ////                            Material.accent: Material.DeepPurple
                        //                            onMoved: UIStyle.fontSize = value
                        //                        }

                        Label{
                            id: fontSizeLabel
                            y: parent.height / 3
                            text: fontSlider.value
                            font.family: UIStyle.fontName
                            Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                        }
                    }
                }
            }

            // save changes row
            Row {
                height: parent.height * 1/10
                width: parent.width
                spacing: 50
                Rectangle
                {
                    height: parent.height
                    width: parent.width * 4/10
                    color: "transparent"
                }

                Button {
                    id: save_changesButton
                    highlighted: UIStyle.darkTheme
                    background:  Rectangle {
                        radius: 5
                        color: UIStyle.themeBlue
                    }
                    text: 'save changes'
                    font.pointSize: UIStyle.fontSize
                    font.family: UIStyle.fontName
                    onClicked: {
                        default_settings.current_speed_index=cmb_speeds.currentIndex
                        default_settings.save_file_path=txt_save_file_path.text
                        var ac_ch='';
                        for(var i=0;i<_channels_count;i++)
                        {
                            if(_active_channels[i])
                                ac_ch=ac_ch + '1'
                            else
                                ac_ch=ac_ch + '0'
                        }
                        default_settings.active_channels=ac_ch
                        default_settings.darkMode=UIStyle.darkTheme
                        default_settings.fontSize=UIStyle.fontSize.toString()
                        default_settings.fonts=UIStyle.fontArray[0]+','+
                                UIStyle.fontArray[1]+','+UIStyle.fontArray[2]+','+UIStyle.fontArray[3]+','
                        viewResultPopupText.text="<h1>Done</h1><br>Changes Saved!"
                        default_settings.save_changes()
                    }
                    onHoveredChanged: {
                        if(hovered)
                            save_changesButton.background.color = UIStyle.buttonHovered
                        else
                            save_changesButton.background.color = UIStyle.themeBlue
                    }
                }
                Button{
                    id: reset
                    text: "reset to default"
                    highlighted: UIStyle.darkTheme
                    font.family: UIStyle.fontName
                    font.pointSize: UIStyle.fontSize
                    background:  Rectangle {
                        radius: 5
                        color: UIStyle.themeBlue
                    }
                    onClicked: {
                        default_settings.current_speed_index="3"
                        default_settings.active_channels="1111111111111111"
                        default_settings.darkMode="true"
                        default_settings.fontSize="10"
                        default_settings.fonts="Bahnschrift,Arial,Candara,Kristen ITC,"
                        UIStyle.fontArray[0]="Bahnschrift"
                        UIStyle.fontArray[1]="Arial"
                        UIStyle.fontArray[2]="Candara"
                        UIStyle.fontArray[3]="Kristen ITC"
                        UIStyle.fontName = "Bahnschrift"
                        UIStyle.fontSize=10
                        UIStyle.darkTheme = true
                        darkThemeSwitch.checked = true
                        viewResultPopupText.text="Reseted To Default!"
                        default_settings.save_changes()
                    }

                    onHoveredChanged: reset.background.color = hovered ? (UIStyle.darkTheme ? '#ff0000' : '#aa0000'):UIStyle.themeBlue

                }

            }
        }
    }


    Popup {
        id: viewResultPopup
        anchors.centerIn: Overlay.overlay
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
                text: qsTr("")
                font.pointSize: UIStyle.fontSize
                font.family: UIStyle.fontName
                color: UIStyle.darkTheme ? '#f7faff':'#2f3033'
            }

            Button {
                id: viewResultPopupButton
                Layout.alignment: Qt.AlignHCenter
                text: 'OK'
                font.pointSize: UIStyle.fontSize
                font.family: UIStyle.fontName
                background:  Rectangle {
                    radius: 5
                    color: UIStyle.themeBlue
                }
                highlighted: UIStyle.darkTheme
                onClicked:viewResultPopup.close()
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
