#include "defaultsettings.h"

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
    QSettings settings;
    QStringList keys = settings.allKeys();
    for(int i=0; i < keys.size(); i++)
    {
        //********************
        // get setting Name
        QString key = keys[i];
        //********************
        // get setting value
        QVariant value = settings.value(key);
        //****************************************************
        //****************************************************
        if(key=="speeds")
        {
            _speeds_str = value.toString();
            _speeds_list = _speeds_str.split("-");
        }
        else if(key=="current_speed_index")
            _current_speed_index  = value.toString();
        else if(key=="save_file_path")
            _save_file_path = value.toString();
        else if (key=="active_channels")
            _active_channels = value.toString();
        else if(key=="darkMode")
            _darkMode = value.toString();
        else if(key=="fontSize")
            _fontSize = value.toString();
        else if(key=="fonts")
            _fonts = value.toString();
        //****************************************************
        //****************************************************

        qDebug() << key << ": " << value;
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
    QSettings settings;
    settings.setValue("speeds", _speeds_str);
    settings.setValue("current_speed_index", _current_speed_index);
    settings.setValue("active_channels", _active_channels);
    settings.setValue("save_file_path", _save_file_path);
    settings.setValue("darkMode", _darkMode);
    settings.setValue("fontSize",_fontSize);
    settings.setValue("fonts",_fonts);
    settings.sync();

    _result_for_popup="<h1>Done</h1><br>Changes Saved!";
    emit viewResultPopup();

}

QString DefaultSettings::resultForPopup()
{
    return _result_for_popup;
}
