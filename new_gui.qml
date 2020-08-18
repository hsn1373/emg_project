// ------------------------------------------------- Akhgar new_gui -----------------------------------------------//
// ------------------------------------------------- Akhgar new_gui -----------------------------------------------//
import QtQuick 2.12
import QtQuick.Controls 2.3 as QQC2
import Qt.labs.settings 1.0
import "qml"
import "qml/Style"
import "qml/Online"
import QtQuick.Controls.Material 2.0
import QtQuick.Window 2.1
import Qt.labs.platform 1.1
import Client 1.0

QQC2.ApplicationWindow {
    Client{
        id: client
    }
    id: window
    visible: false  // first of all splash will showing
    width: splash.width
    height: splash.height
    visibility: "Minimized"  // for windowed splash
    title: qsTr("emg_fum")
    property int navibuttonheight:40
    property int splashwidth: 500
    property int splashheight: 333
    OnlinePage{
        id: online
        visible: false
    }

    Settings {
        id: settings
        property bool wireless
        property bool bluetooth
        property int brightness
        property bool darkTheme
        property bool demoMode
    }

    Binding {
        target: UIStyle
        property: "darkTheme"
        value: settings.darkTheme
    }

    // We need the settings object both here and in SettingsPage,
    // so for convenience, we declare it as a property of the root object so that
    // it will be available to all of the QML files that we load.
    property alias settings: settings

    background: Image{
        anchors.fill: parent
        width: parent.width
        source: "images/Launcher_page.jpg"
    }

    QQC2.StackView {
        id: stackView
        visible: false
        focus: true
        anchors.fill: parent

        initialItem: LauncherPage {
            onLaunched: stackView.push(page)

        }
    }
    // naviutton must place under the stackview
    NaviButton {
        id: homeButton
        visible: false
        edge: Qt.TopEdge
        enabled: stackView.depth > 1
        imageSource: "images/home.png"
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            if(!UIStyle.connect)
                stackView.pop(null)
            else
                online.connectPopup()
        }
    }
    // first of all elements ,splah is called
    Splash{
        id:splash
        onTimeout: {
            window.visibility= "Maximized"  // for maximize size of screen
            window.visible=true
            homeButton.visible=true
            stackView.visible=true
            window.minimumWidth=Screen.width*0.6
            window.minimumHeight=Screen.height*0.6
//            console.log("window sizzeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee:"+Screen.width+" "+Screen.height)
        }

    }

}
