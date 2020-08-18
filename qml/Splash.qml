import QtQuick 2.12
import QtQuick.Controls 2.3 as QQC2
import Qt.labs.settings 1.0

import QtQuick.Controls.Material 2.0
import QtQuick.Window 2.12
import Qt.labs.platform 1.1
Window{
    id: splash
    visible: true   // defaul
    width: image.width
    height: image.height
    signal timeout      // for call new_gui
    flags: Qt.FramelessWindowHint   //for correct size
    Image {
            id: image
            x:0
            y:0
            source: "../images/splash_fum.jpg"
            width: 500
            height: 333.33
//            Layout.preferredWidth: 100
//            Layout.preferredHeight: 100
        }
    Timer {     // showing splash period
            interval: 2000; running: true; repeat: false
            onTriggered: {
                visible = false
                splash.timeout()
            }
        }

    Component.onCompleted: visible = true
}
