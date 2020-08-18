/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.12
import QtQuick.Controls.Material 2.0

pragma Singleton

QtObject {
    id: uiStyle
    property string backgroundImage : 'images/Launcher_page.jpg'
    property bool connect: false
    property bool darkTheme: true
    property int d: 0
    property int l: 1
    property int fontSize: 10

    // Color Scheme
    // Green
    readonly property color colorQtPrimGreen: "#41cd52"
    readonly property color colorQtAuxGreen1: "#21be2b"
    readonly property color colorQtAuxGreen2: "#17a81a"

    // Red
    readonly property color colorRed: "#e6173d"

    // Yellow
    readonly property color colorYellow: "#FFEB3B"


    // Light/dark versions of the colors.
    readonly property color background: darkTheme? '#1e2126':'#ffffff'
    readonly property color themeColorQtGray1: darkTheme ? "#f3f3f4" : "#09102b"
    readonly property color themeColorQtGray2: darkTheme ? "#cecfd5" : "#222840"
    readonly property color themeColorQtGray3: darkTheme ? "#b5b7bf" : "#3a4055"
    readonly property color themeColorQtGray4: darkTheme ? "#9d9faa" : "#53586b"
    readonly property color themeColorQtGray5: darkTheme ? "#848895" : "#53586b"
    readonly property color themeColorQtGray6: darkTheme ? "#53586b" : "#848895"
    readonly property color themeColorQtGray7: darkTheme ? "#53586b" : "#9d9faa"
    readonly property color themeColorQtGray8: darkTheme ? "#3a4055" : "#b5b7bf"
    readonly property color themeColorQtGray9: darkTheme ? "#222840" : "#cecfd5"
    readonly property color themeColorQtGray10: darkTheme ? "#09102b" : "#f3f3f4"
    readonly property color textColor: darkTheme ? '#5e5970' : '#575759'
    readonly property color shapeColor1: darkTheme ? '#4b79a1' : '#72c5fc'
    readonly property color shapeColor2: darkTheme ? '#283e51' : '#478cba'
    readonly property color themeColorBlue: darkTheme ? '#002c85' : '#668ede'
    readonly property color themeColorWhiteBlack: darkTheme ?   '#ffffff' : '#000000'
    readonly property color themeColorWhiteBlack2: darkTheme ?   '#000000' : '#ffffff'
    readonly property color themeBlue: darkTheme ? '#283593' : '#2196F3'
    readonly property color buttonHovered: darkTheme ? '#1fd100':'#a9fa9b'
    readonly property color activeChannelHovered: darkTheme ? '#': '#'
    readonly property color deActiveChannelHovered: darkTheme ? '#666262':'#b0a6a5'
    readonly property color backgroundColor: darkTheme ? "#4cb2b9" : '#1de0ca'
    readonly property color backgroundHovered: darkTheme ?'#a4bfe4' : '#dcebfd'
    readonly property color columnBackground: darkTheme? "#363943" : '#F8F8F8'
    readonly property color borderGrey: darkTheme ? '#363943' : '#E3E1E1'
    readonly property color borderGrey2: darkTheme ? '#E3E1E1' : '#363943'

    readonly property color comboBackground: Qt.rgba(227,225,225,0.5)
    readonly property color channelRed: Qt.rgba(46,125,50,0.3)
    readonly property color channelGreen: Qt.rgba(0,230,118,0.9)
    readonly property color alphaBackground : darkTheme ? Qt.rgba(30,33,38,0.5) : Qt.rgba(255,255,255,0.5)

    property var fontArray: ['Bahnschrift','Arial','Candara','Kristen ITC']
    property string fontName: 'Bahnschrift'


    function themeImagePath(baseImagePath) {
        return baseImagePath + (darkTheme ? "-dark" : "-light") + ".png"
    }
}
