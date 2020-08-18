#include "defaultsettings.h"
#include <QDomDocument>
#include <QXmlStreamWriter>

DefaultSettings::DefaultSettings(QObject *parent) : QObject(parent)
{
    // initialize values
    initialize();
}
DefaultSettings::~DefaultSettings()
{

}
void DefaultSettings::initialize()
{
    QString settingName,settingValue="",darkMode="";
    QDomDocument xmlBOM;
    QFile f("settings.xml");
    if (!f.open(QIODevice::ReadOnly ))
    {
        // Error while loading file
        qDebug() << "File Dose Not Exist";
        return;
    }
    xmlBOM.setContent(&f);
    f.close();

    QDomElement root=xmlBOM.documentElement();

    QDomElement settingTag=root.firstChild().toElement();
    for(int i=0;i<root.childNodes().length();i++)
    {
        //********************
        // get setting Name
        QDomElement firstlevelchildTag=settingTag.firstChild().toElement();
        settingName=firstlevelchildTag.firstChild().toText().data();
        //********************
        // get setting value
        firstlevelchildTag=firstlevelchildTag.nextSibling().toElement();
        settingValue=firstlevelchildTag.firstChild().toText().data();

        //****************************************************
        //****************************************************
        if(settingName=="speeds")
        {
            _speeds_str=settingValue;
            _speeds_list=_speeds_str.split("-");
        }
        else if(settingName=="current_speed_index")
            _current_speed_index=settingValue;
        else if(settingName=="save_file_path")
            _save_file_path=settingValue;
        else if (settingName=="active_channels")
            _active_channels=settingValue;
        else if(settingName=="darkMode")
            _darkMode=settingValue;
        else if(settingName=="fontSize")
            _fontSize=settingValue;
        else if(settingName=="fonts")
            _fonts=settingValue;

        //****************************************************
        //****************************************************

        qDebug() << settingName << ": " << settingValue;

        settingTag = settingTag.nextSibling().toElement();
    }
}

QString DefaultSettings::getSaveFilePath()
{
    return _save_file_path;
}

void DefaultSettings::setSaveFilePath(QString value)
{
    _save_file_path=value;
}

QString DefaultSettings::getActiveChannels()
{
    return _active_channels;
}

void DefaultSettings::setActiveChannels(QString value)
{
    _active_channels=value;
}

QStringList DefaultSettings::getSpeedList()
{
    return _speeds_list;
}

QString DefaultSettings::getCurrentSpeedIndex()
{
    return _current_speed_index;
}

void DefaultSettings::setCurrentSpeedIndex(QString value)
{
    _current_speed_index=value;
}
QString DefaultSettings::getDarkMode()
{
    return _darkMode;
}
void DefaultSettings::setDarkMode(QString value)
{
    _darkMode=value;
}
QString DefaultSettings::getFontSize()
{
    return _fontSize;
}

void DefaultSettings::setFontSize(QString value)
{
    _fontSize=value;
}
QString DefaultSettings::getFonts()
{
    return _fonts;
}

void DefaultSettings::setFonts(QString value)
{
    _fonts=value;
}

void DefaultSettings::save_changes()
{
    //************
    // write to file

    QFile file("settings.xml");
    QXmlStreamWriter xmlWriter(&file);


    if(file.exists())
    {
        file.remove();
    }

    file.open(QIODevice::WriteOnly);

    xmlWriter.setAutoFormatting(true);

    xmlWriter.writeStartDocument();
    xmlWriter.writeStartElement("settings");

    //******************************************
    // speeds

    xmlWriter.writeStartElement("setting");
    xmlWriter.writeTextElement("name","speeds");
    xmlWriter.writeTextElement("value",_speeds_str);
    xmlWriter.writeEndElement();

    //******************************************
    // _current_speed_index

    xmlWriter.writeStartElement("setting");
    xmlWriter.writeTextElement("name","current_speed_index");
    xmlWriter.writeTextElement("value",_current_speed_index);
    xmlWriter.writeEndElement();

    //******************************************
    // active_channels

    xmlWriter.writeStartElement("setting");
    xmlWriter.writeTextElement("name","active_channels");
    xmlWriter.writeTextElement("value",_active_channels);
    xmlWriter.writeEndElement();

    //******************************************
    // save_file_path

    xmlWriter.writeStartElement("setting");
    xmlWriter.writeTextElement("name","save_file_path");
    xmlWriter.writeTextElement("value",_save_file_path);
    xmlWriter.writeEndElement();

    //******************************************
    // darkmode

    xmlWriter.writeStartElement("setting");
    xmlWriter.writeTextElement("name","darkMode");
    xmlWriter.writeTextElement("value",_darkMode);
    xmlWriter.writeEndElement();

    //******************************************
    // fontSzie

    xmlWriter.writeStartElement("setting");
    xmlWriter.writeTextElement("name","fontSize");
    xmlWriter.writeTextElement("value",_fontSize);
    xmlWriter.writeEndElement();

    //******************************************
    // fontSzie

    xmlWriter.writeStartElement("setting");
    xmlWriter.writeTextElement("name","fonts");
    xmlWriter.writeTextElement("value",_fonts);
    xmlWriter.writeEndElement();

    //******************************************
    //end of settings tag
    xmlWriter.writeEndElement();

    file.close();

    _result_for_popup="<h1>Done</h1><br>Changes Saved!";
    emit viewResultPopup();

}

QString DefaultSettings::resultForPopup()
{
    return _result_for_popup;
}
