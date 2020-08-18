#ifndef DEFAULTSETTINGS_H
#define DEFAULTSETTINGS_H

#include <QObject>
#include <QDebug>
#include <QFile>
#include <QSettings>

class DefaultSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString save_file_path READ getSaveFilePath WRITE setSaveFilePath)
    Q_PROPERTY(QString active_channels READ getActiveChannels WRITE setActiveChannels)
    Q_PROPERTY(QStringList speed_list READ getSpeedList)
    Q_PROPERTY(QString current_speed_index READ getCurrentSpeedIndex WRITE setCurrentSpeedIndex)
    Q_PROPERTY(QString darkMode READ getDarkMode WRITE setDarkMode)
    Q_PROPERTY(QString fontSize READ getFontSize WRITE setFontSize)
    Q_PROPERTY(QString fonts READ getFonts WRITE setFonts)

public:
    explicit DefaultSettings(QObject *parent = nullptr);
    ~DefaultSettings();

    void initialize();
    QString getSaveFilePath();
    void setSaveFilePath(QString value);
    QString getActiveChannels();
    void setActiveChannels(QString value);
    QStringList getSpeedList();
    QString getCurrentSpeedIndex();
    void setCurrentSpeedIndex(QString value);
    QString getDarkMode();
    void setDarkMode(QString value);
    QString getFontSize();
    void setFontSize(QString value);
    QString getFonts();
    void setFonts(QString value);

signals:
    void viewResultPopup();

private:
    QString _save_file_path;
    QString _active_channels;
    QString _speeds_str;
    QStringList _speeds_list;
    QString _current_speed_index;
    QString _result_for_popup;
    QString _darkMode;
    QString _fontSize;
    QString _fonts;

public slots:
    void save_changes();
    QString resultForPopup();


};

#endif // DEFAULTSETTINGS_H
