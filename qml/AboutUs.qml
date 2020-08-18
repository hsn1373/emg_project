import QtQuick 2.14
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

Item {
    id: window
    readonly property int responsiveWidth: Screen.width
    readonly property int responsiveHeight: Screen.height
    height: parent.height
    property int init_y_text: 60
    property int y_text: init_y_text
    property int counter: 0
    property bool flag: false
    width: parent.width
    FontLoader {
        id: myFont
        source: "../fonts/KARNIVOB.ttf"
    }


    Rectangle {     //  gradiant
        id:recback
        anchors.bottomMargin: -214
        //        anchors.rightMargin: -277
        anchors { left: parent.left; top: parent.top; right: parent.right; bottom: parent.bottom }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#5a5b5c" }
            GradientStop { position: 1.0; color: "#111111" }
        }
    }

    Timer { // animation for text
        interval: 60
        running: true
        repeat: true
        onTriggered:{
            counter = (counter + 1) % element.height
            y_text = counter + init_y_text
            if(y_text>element.height-100){
                element.opacity = element.opacity-0.01
            }else
                if(y_text<174 && element.opacity!=1){
                    element.opacity = element.opacity+0.02
                }
        }
    }
    Text {
        id: element
        x: 36
        y: y_text
        width: 875
        height: 500
        lineHeight: 1.4
        font.family: myFont.name
        color: "#ffffff"
        text: qsTr("    Speaking or writing about a source text
 contributes to deeper
comprehension than merely reading

    since both actions require intense scrutiny and examination.
Reading and then engaging in a meaningful
 and fruitful discussion with

    others challenges us to extend our thinking,
arrive at new insights, and consider different perspectives.
Writing about what we read requires critical thinking

    and active engagement in order to compose
a coherent piece for a particular purpose
and audience. Therefore,

    learning experiences that include writing,
 speaking,and listening tasks foster
further introspection and analysis of text.")
        font.italic: true
        wrapMode: Text.WordWrap // ****
        font.pixelSize: 14*window.width/responsiveWidth

    }

    Text {  // title
        id: element1
        x: 36
        y: 26
        width: 294
        height: 47
        color: "#ffffff"
        text: qsTr("About  Manufacturer")
        font.italic: true
        font.underline: false
        font.weight: Font.Bold
        style: Text.Sunken
        font.bold: true
        font.pixelSize: 24*window.width/responsiveWidth
        font.family: myFont.name
    }

    Image { // black & white logo
        id: image
        x: 1036
        y: 531
        width: 301
        height: 155
        fillMode: Image.PreserveAspectFit
        source: "../images/logo(B&W).png"
    }
    Timer {     // animation for top element
        interval: 30
        running: true
        repeat: true
        onTriggered:{
            if(image.opacity==1)flag=true
            if(image.opacity<=0.4)flag=false
            if(flag)
            image.opacity = image.opacity-0.01
            else
            image.opacity = image.opacity+0.01
        }
    }
}





