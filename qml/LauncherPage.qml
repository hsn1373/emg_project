// Akhgar LauncherPage + Mollaei DefaultSettings added
import QtQuick 2.12
import QtQuick.Controls 2.3 as QQC2
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import "Style"
import DefaultSettings 1.0
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.1
import QtQuick.Window 2.12
Item {
    id: lancher_page
    width: parent.width
    height: parent.height
    readonly property int responsiveWidth: Screen.width
    readonly property int responsiveHeight: Screen.height
    FontLoader {
        id: myFont
        source: "../fonts/KARNIVOB.ttf"
    }

    readonly property int size: Math.min(width - 80 , height)
    readonly property int itemSize: size / 4
    property bool dark: false
    property string wholeFnt: ''
    property string fnt: ''
    property int default_x_counter:-1*offlinePage.width/6
    property int default_x_counter2:thirdcolumn.width/6
    property double flag:0.001
    property double opacityconst: 0.5
    property int x_counter1: default_x_counter
    property int x_counter2: default_x_counter
    property int x_counter3: default_x_counter
    property int x_counter4: default_x_counter
    property int x_counter5: default_x_counter2
    property int x_counter6: default_x_counter2
    signal launched(string page)

    DefaultSettings{
        id: ds
        Component.onCompleted: {
            UIStyle.darkTheme = (ds.darkMode == "true") ? true : false
            UIStyle.fontSize = parseInt(ds.fontSize)
            wholeFnt = ds.fonts
            for(var i=0,j=0;i<38;i++){
                if(wholeFnt.charAt(i) == ','){
                    UIStyle.fontArray[j]=fnt
                    fnt=""
                    j++
                }else
                    fnt += wholeFnt.charAt(i)
            }
            UIStyle.fontName = UIStyle.fontArray[0]
        }
    }

    Row{
        width: parent.width
        height: parent.height

        Column{
            id:firstColumn
            width: parent.height * 1/4
            height: parent.height
            spacing: 0
            padding: 0
            GridView {

                id:my_view

                width: parent.width
                height: parent.height
                cellWidth: my_view.width
                cellHeight: my_view.height/4.5
                interactive: false

                model: ListModel {
                    id: myListModel

                    ListElement {
                        title: qsTr("")
                        image: "file.png"
                        page: "Offline/OfflinePage.qml"
                    }
                    ListElement {
                        title: qsTr("")
                        image: "record.png"
                        page: "Online/OnlinePage.qml"
                    }
                    ListElement {
                        title: qsTr("")
                        image: "settings.png"
                        page: "Settings/SettingsPage.qml"
                    }
                    ListElement {
                        title: qsTr("")
                        image: "about_us.png"
                        page: "AboutUs.qml"
                    }
                }

                delegate: Column {
                    QQC2.RoundButton {
                        id:rb
                        width: my_view.height/4.5
                        height: my_view.height/4.5
                        //                        icon.width: 32
                        //                        icon.height: 32
                        //                        icon.name: model.icon

                        // background of each button
                        background: Image {
                            id: backG
                            source: "../images/record_img.png"
                        }
                        Image {
                            id:logo
                            source: "../images/" + model.image
                            anchors.centerIn: parent.Center
                            width:lancher_page.width*sourceSize.width/Screen.width
                            height:lancher_page.height*sourceSize.width/Screen.height
                            x:parent.width/2-logo.width/2
                            y:parent.height/2-logo.height/2
                            opacity: 0.7
                        }


                        onClicked: {
                            lancher_page.launched(Qt.resolvedUrl(model.page))
                        }
                        onHoveredChanged:
                        {
                            if(hovered)
                            {
                                txt_title.color=UIStyle.darkTheme ? '#B0B0B0' : '#323232'
                                switch(Qt.resolvedUrl(model.page)){
                                case 'qrc:/qml/Offline/OfflinePage.qml':
                                    offlinePage_anim.running=true
                                    break
                                case 'qrc:/qml/Online/OnlinePage.qml':
                                    onlinePage_anim.running=true
                                    break
                                case 'qrc:/qml/Settings/SettingsPage.qml':
                                    settingPage_anim.running=true
                                    break
                                case 'qrc:/qml/AboutUs.qml':
                                    aboutUsPage_anim.running=true
                                    break
                                }
                            }
                            else
                            {

                                txt_title.color= UIStyle.textColor
                                switch(Qt.resolvedUrl(model.page)){
                                case 'qrc:/qml/Offline/OfflinePage.qml':
                                    x_counter1= default_x_counter
                                    offlinePage_anim.running=false
                                    offlinePage.opacity=0
                                    break
                                case 'qrc:/qml/Online/OnlinePage.qml':
                                    x_counter2= default_x_counter
                                    onlinePage_anim.running=false
                                    onlinePage.opacity=0
                                    break
                                case 'qrc:/qml/Settings/SettingsPage.qml':
                                    x_counter3=default_x_counter
                                    settingPage_anim.running=false
                                    settingPage.opacity=0
                                    break
                                case 'qrc:/qml/AboutUs.qml':
                                    x_counter4= default_x_counter
                                    aboutUsPage_anim.running=false
                                    aboutUs.opacity=0
                                    break
                                }
                            }
                        }
                    }
                    Text {
                        id: txt_title
                        text: model.title
                        font.family: UIStyle.fontName
                        font.pointSize: UIStyle.fontSize + 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        color:UIStyle.textColor
                    }
                }
            }

        }
        Column{

            id: secondColumn
            width: parent.width * 1/4
            height: parent.height
            anchors.left: firstColumn.right
            Row{
                id: offlinePage
                width: parent.width
                height: parent.height/4.5
                opacity: 0;
                x:x_counter1
                Image{
                    id: offlineRec
                    width: parent.width
                    height: parent.height
                    source: "../images/rec_img.png"
                }
                Label{
                    x:-1*offlinePage.width/2
                    anchors.centerIn: parent
                    text: qsTr('analysis recorded signals')
                    color: "white"
                    font.pointSize: (UIStyle.fontSize + 4)*lancher_page.width/responsiveWidth
                    font.family: UIStyle.fontName
                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                }
            }
            Row{
                id: onlinePage
                width: parent.width
                height: parent.height/4.5
                opacity: 0;
                x:x_counter2
                Image{
                    id: onlinePageRec
                    width: parent.width
                    height: parent.height
                    source: "../images/rec_img.png"
                }
                Label{
                    x:-1*onlinePage.width/2
                    anchors.centerIn: parent
                    color: "white"
                    text: qsTr('record signal')
                    font.pointSize: (UIStyle.fontSize + 4)*lancher_page.width/responsiveWidth
                    font.family: UIStyle.fontName
                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                }
            }
            Row{
                id: settingPage
                width: parent.width
                height: parent.height/4.5
                opacity: 0;
                x:x_counter3
                Image{
                    id: settingRec
                    width: parent.width
                    height: parent.height
                    source: "../images/rec_img.png"
                }
                Label{
                    x:-1*settingPage.width/2
                    anchors.centerIn: parent
                    color: "white"
                    text: qsTr('apply your settings')
                    font.pointSize:(UIStyle.fontSize + 4)*lancher_page.width/responsiveWidth
                    font.family: UIStyle.fontName
                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                }
            }
            Row{
                id: aboutUs
                width: parent.width
                height: parent.height/4.5
                opacity: 0;
                x:x_counter4
                Image{
                    id: aboutUsRec
                    width: parent.width
                    height: parent.height

                    source: "../images/rec_img.png"
                }
                Label{
                    color: "white"
                    x:-1*aboutUs.width/2
                    anchors.centerIn: parent
                    text: qsTr('know more about us')
                    font.pointSize: (UIStyle.fontSize + 4)*lancher_page.width/responsiveWidth
                    font.family: UIStyle.fontName
                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                }
            }
        }
        Column{
            id:endcolumn
            width:1/4*parent.height
            height:parent.height
            anchors.right: parent.right
            topPadding: parent.height*0.44
            GridView {

                id:my_viewright

                width: parent.width
                height: parent.height
                cellWidth: my_viewright.width
                cellHeight: my_viewright.height/4.5
                interactive: false

                model: ListModel {
                    id: myListModelright
                    ListElement {
                        title: qsTr("")
                        image: "speedometer.png"
                        page: "Offline/OfflinePage.qml"
                    }
                    ListElement {
                        title: qsTr("")
                        image: "off_icon.png"
                        page: "Online/OnlinePage.qml"
                    }
                }

                delegate: Column {
                    QQC2.RoundButton {
                        id:rb2
                        width: my_viewright.height/4.5
                        height: my_viewright.height/4.5

                        // background of each button
                        background: Image {
                            id: backG2
                            source: "../images/record_img.png"
                        }
                        Image {
                            id:logo2
                            source: "../images/" + model.image
                            anchors.centerIn: backG2.Center
                            width:lancher_page.width*sourceSize.width/Screen.width
                            height:lancher_page.height*sourceSize.width/Screen.height
                            x:parent.width/2-logo2.width/2
                            y:parent.height/2-logo2.height/2
                            opacity: 0.7
                        }
                        onClicked: {
                            lancher_page.launched(Qt.resolvedUrl(model.page))
                        }
                        onHoveredChanged:
                        {
                            if(hovered)
                            {
                                //                                txt_title.color=UIStyle.darkTheme ? '#B0B0B0' : '#323232'
                                switch(Qt.resolvedUrl(model.page)){
                                case 'qrc:/qml/Offline/OfflinePage.qml':
                                    speedometerpage_anim.running=true
                                    break
                                case 'qrc:/qml/Online/OnlinePage.qml':
                                    exit_anim.running=true
                                    break
                                }
                            }
                            else
                            {
                                //                                txt_title.color= UIStyle.textColor
                                switch(Qt.resolvedUrl(model.page)){
                                case 'qrc:/qml/Offline/OfflinePage.qml':
                                    x_counter5= default_x_counter2
                                    speedometerpage_anim.running=false
                                    speedometerpage.opacity=0
                                    break
                                case 'qrc:/qml/Online/OnlinePage.qml':
                                    x_counter6= default_x_counter2
                                    exit_anim.running=false
                                    exit.opacity=0
                                    break
                                }
                            }
                        }
                    }
                }
            }

        }
        Column{
            id :thirdcolumn
            width: parent.width * 1/4
            height: parent.height
            anchors.right: endcolumn.left
            topPadding: parent.height*0.44
            Row{
                id: speedometerpage
                width: parent.width
                height: parent.height/4.5
                opacity: 0;
                x:x_counter5
                Image{
                    id: speedometerRec
                    width: parent.width
                    height: parent.height
                    source: "../images/rec_img.png"
                }
                Label{
                    x:thirdcolumn.width/2
                    anchors.centerIn: parent
                    text: qsTr('Internal Measurement Unit')
                    color: "white"
                    font.pointSize: (UIStyle.fontSize + 4)*lancher_page.width/responsiveWidth
                    font.family: UIStyle.fontName
                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                }
            }

            Row{
                id: exit
                width: parent.width
                height: parent.height/4.5
                opacity: 0;
                x:x_counter6
                Image{
                    id: exitRec
                    width: parent.width
                    height: parent.height
                    source: "../images/rec_img.png"
                }
                Label{
                    x:thirdcolumn.width/2
                    anchors.centerIn: parent
                    text: qsTr('EXIT')
                    color: "white"
                    font.pointSize:(UIStyle.fontSize + 4)*lancher_page.width/responsiveWidth
                    font.family: UIStyle.fontName
                    Material.theme: UIStyle.darkTheme ? Material.Dark : Material.Light
                }
            }



            //                         FUM ROBOTIC LAB

            //                        topPadding: parent.height*0.96
            //                        leftPadding: 0.4*parent.width
            Text {
                id: fumroboticlab
                opacity: 0.55
                text: qsTr("FUM Robotic Lab")
                font.pointSize:(UIStyle.fontSize + 4)*lancher_page.width/responsiveWidth
                anchors.centerIn: parent.Center
                color: "white"
                font.family: myFont.name
                font.weight: Font.bold
                font.bold: true
                font.letterSpacing: 5
            }

        }
    }
    Timer {
        id:offlinePage_anim
        interval: 3
        running: false
        repeat: true
        onTriggered:{
            // for a tiny bug these 3 line can't be removed
            onlinePage.opacity=0
            settingPage.opacity=0
            aboutUs.opacity=0
            x_counter1+=5;
            if(offlinePage.opacity<75)offlinePage.opacity+=3
            if(x_counter1>=0){
                running=false
            }
        }
    }               //
    Timer {
        id:onlinePage_anim
        interval: 3
        running: false
        repeat: true
        onTriggered:{
            // for a tiny bug these 3 line1 can't be removed
            offlinePage.opacity=0
            settingPage.opacity=0
            aboutUs.opacity=0
            x_counter2+=5;
            if(onlinePage.opacity<75)onlinePage.opacity+=3
            if(x_counter2>=0){
                running=false
            }
        }
    }
    Timer {
        id:settingPage_anim
        interval: 3
        running: false
        repeat: true
        onTriggered:{
            // for a tiny bug these 3 line can't be removed
            onlinePage.opacity=0
            offlinePage.opacity=0
            aboutUs.opacity=0
            x_counter3+=5;
            if(settingPage.opacity<75)settingPage.opacity+=3
            if(x_counter3>=0){
                running=false
            }
        }
    }
    Timer {
        id:aboutUsPage_anim
        interval: 3
        running: false
        repeat: true
        onTriggered:{
            // for a tiny bug these 3 line can't be removed
            onlinePage.opacity=0
            settingPage.opacity=0
            offlinePage.opacity=0
            x_counter4+=5;
            if(aboutUs.opacity<75)aboutUs.opacity+=3
            if(x_counter4>=0){

                running=false
            }
        }
    }
    Timer {
        id:speedometerpage_anim
        interval: 3
        running: false
        repeat: true
        onTriggered:{
            // for a tiny bug this line can't be removed
            exit.opacity=0
            x_counter5-=5;
            if(speedometerpage.opacity<75)speedometerpage.opacity+=3
            if(x_counter5<=0){
                running=false
            }
        }
    }
    Timer {
        id:exit_anim
        interval: 3
        running: false
        repeat: true
        onTriggered:{
            // for a tiny bug this line can't be removed
            exit.opacity=0
            x_counter6-=5;
            if(exit.opacity<75)exit.opacity+=3
            if(x_counter6<=0){
                running=false
            }
        }
    }
    Timer {
        id:fumroboticlab_changer
        interval:6
        running: true
        repeat: true
        onTriggered:{
            fumroboticlab.scale+=flag
            if(fumroboticlab.scale>1.15 || fumroboticlab.scale<0.95)flag*=-1;
        }
    }
}

