#include "recursivesearch.h"

RecursiveSearch::RecursiveSearch(const QStringList &locations, const QStringList &filters, bool sortName, QObject *parent) :
    QObject(parent)
{
    _locations = locations;
    _filters = filters;
    _sortName = sortName;
}

void RecursiveSearch::recursiveSearch(const QString &folder)
{
    QString mpath = folder;
    if (mpath == "home")
        mpath = QDir::homePath();
    else if (mpath == "image") {
        mpath = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    }
    else if (mpath == "music") {
        mpath = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    }
    else if (mpath == "video") {
        mpath = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    }
    else if (mpath == "sdcard") {
        mpath = "/media/" + mpath;
    }

    QVariantList folderData;

    QDir dir(mpath);
    const QFileInfoList &list = dir.entryInfoList(_filters, QDir::Files | QDir::AllDirs | QDir::NoSymLinks | QDir::NoDot | QDir::NoDotDot, _sortName ? QDir::Name : QDir::Time);
    foreach (const QFileInfo &info, list) {
        if (info.isDir()) {
            //qDebug() << "Recursive search in:" << dir.absolutePath();

            recursiveSearch(info.filePath());
        }
        else if (info.isFile()) {
            //qDebug() << "adding" << info.filePath();
            QVariantMap fileData;

            fileData["name"] = info.fileName();
            fileData["base"] = info.baseName();
            fileData["path"] = info.filePath();
            fileData["size"] = info.size();
            fileData["time"] = info.created().toTime_t();
            fileData["ext"] = info.suffix();
            fileData["dir"] = false;

            QMimeDatabase db;
            QMimeType type = db.mimeTypeForFile(info.absoluteFilePath());
            fileData["mime"] = type.name();

            QImageReader reader(info.absoluteFilePath());
            if (reader.canRead()) {
                fileData["width"] = reader.size().width();
                fileData["height"] = reader.size().height();
            }
            else {
                fileData["width"] = 0;
                fileData["height"] = 0;
            }

            Q_EMIT haveFileData(fileData);

            folderData.append(fileData);
        }
    }

    if (!folderData.isEmpty())
        Q_EMIT haveFolderData(folderData);
}

void RecursiveSearch::startSearch()
{
    foreach (const QString &folder, _locations) {
        recursiveSearch(folder);
    }

    this->deleteLater();
}

