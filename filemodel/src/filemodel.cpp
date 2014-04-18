#include "filemodel.h"

#include <QDateTime>
#include <QDebug>

#include <QMimeDatabase>
#include <QMimeType>
#include <QImageReader>

#include <QStandardPaths>

Filemodel::Filemodel(QObject *parent) :
    QAbstractListModel(parent)
{
    _roles[NameRole] = "name";
    _roles[BaseRole] = "base";
    _roles[PathRole] = "path";
    _roles[SizeRole] = "size";
    _roles[TimestampRole] = "time";
    _roles[ExtensionRole] = "ext";
    _roles[MimeRole] = "mime";
    _roles[DirRole] = "dir";
    _roles[ImageWidthRole] = "width";
    _roles[ImageHeightRole] = "height";
    _sorting = true;
    _path = QDir::homePath();
    _filter = QStringList() << "*.*";

    fs = 0;

    _haveImages = false;
    _haveVideos = false;
}

Filemodel::~Filemodel()
{
    _modelData.clear();
}

int Filemodel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return _modelData.count();
}

QVariant Filemodel::data(const QModelIndex &index, int role) const
{
    //qDebug() << "get" << QString::number(index.row()) << _roles[role];
    int row = index.row();
    if (row < 0 || row >= _modelData.size())
        return QVariant();
    //return _modelData.at(index.row()).value(_roles.value(role));
    return _modelData[index.row()][_roles[role]];
}

QStringList &Filemodel::getFilter()
{
    return _filter;
}

void Filemodel::setFilter(const QStringList &filter)
{
    //qDebug() << "set filter:" << filter;
    _filter = filter;
}

QString &Filemodel::getPath()
{
    return _path;
}

QString &Filemodel::getRpath()
{
    return _rpath;
}

void Filemodel::processRpath(const QString &rpath)
{
    if (!fs) {
        fs = new QFileSystemWatcher(this);
        connect(fs, SIGNAL(directoryChanged(QString)), this, SLOT(onDirectoryChanged(QString)));
        connect(fs, SIGNAL(fileChanged(QString)), this, SLOT(onFileChanged(QString)));
    }

    clear();

    if (rpath == "home")
        _rpath = QDir::homePath() + "/Mitakuuluu";
    else
        _rpath = rpath;
    recursiveSearch(_rpath);
}

bool Filemodel::getSorting()
{
    return _sorting;
}

void Filemodel::setSorting(bool newSorting)
{
    _sorting = newSorting;
}

bool Filemodel::haveImages()
{
    return _haveImages;
}

bool Filemodel::haveVideos()
{
    return _haveVideos;
}

void Filemodel::showRecursive(const QStringList &dirs)
{
    clear();

    _haveImages = false;
    Q_EMIT haveImagesChanged();
    _haveVideos = false;
    Q_EMIT haveVideosChanged();

    foreach (const QString &path, dirs) {
        //qDebug() << "Processing folder:" << path;
        recursiveSearch(path);
    }
}

void Filemodel::processPath(const QString &path)
{
    if (fs) {
        delete fs;
        fs = 0;
    }

    _path = path;
    if (_path == "home")
        _path = QDir::homePath();
    clear();

    _haveImages = false;
    Q_EMIT haveImagesChanged();
    _haveVideos = false;
    Q_EMIT haveVideosChanged();

    //qDebug() << "Processing" << path << _filter;
    QDir dir(path);
    const QFileInfoList &list = dir.entryInfoList(_filter, QDir::AllDirs | QDir::NoDot | QDir::NoSymLinks | QDir::Files, (_sorting ? QDir::Time : QDir::Name) | QDir::DirsFirst);
    foreach (const QFileInfo &info, list) {
        //qDebug() << "adding" << info.absoluteFilePath();
        if (dir.isRoot() && info.fileName() == "..")
            continue;
        QVariantMap fileInfo;

        beginInsertRows(QModelIndex(), _modelData.size(), _modelData.size() + list.size());
        fileInfo["name"] = info.fileName();
        fileInfo["base"] = info.baseName();
        fileInfo["path"] = info.absoluteFilePath();
        fileInfo["size"] = info.size();
        fileInfo["time"] = info.created().toTime_t();
        fileInfo["ext"] = info.suffix();
        fileInfo["dir"] = info.isDir();

        QMimeDatabase db;
        QMimeType type = db.mimeTypeForFile(info.absoluteFilePath());
        fileInfo["mime"] = type.name();

        if (type.name().startsWith("image")) {
            _haveImages = true;
            Q_EMIT haveImagesChanged();
        }
        else if (type.name().startsWith("video")) {
            _haveVideos = true;
            Q_EMIT haveVideosChanged();
        }

        QImageReader reader(info.absoluteFilePath());
        if (reader.canRead()) {
            fileInfo["width"] = reader.size().width();
            fileInfo["height"] = reader.size().height();
        }
        else {
            fileInfo["width"] = 0;
            fileInfo["height"] = 0;
        }

        _modelData.append(fileInfo);
        endInsertRows();
        Q_EMIT countChanged();
    }
}

void Filemodel::recursiveSearch(const QString &path)
{
    QString mpath = path;
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

    if (fs)
        fs->addPath(mpath);
    //qDebug() << "Processing" << path << _filter;
    QDir dir(mpath);
    const QFileInfoList &list = dir.entryInfoList(_filter, QDir::Files | QDir::AllDirs | QDir::NoSymLinks | QDir::NoDot | QDir::NoDotDot, _sorting ? QDir::Time : QDir::Name);
    foreach (const QFileInfo &info, list) {
        if (info.isDir()) {
            //qDebug() << "Recursive search in:" << dir.absolutePath();

            recursiveSearch(info.filePath());
        }
        else if (info.isFile()) {
            //qDebug() << "adding" << info.filePath();
            QVariantMap fileInfo;

            beginInsertRows(QModelIndex(), _modelData.size(), _modelData.size());
            fileInfo["name"] = info.fileName();
            fileInfo["base"] = info.baseName();
            fileInfo["path"] = info.filePath();
            fileInfo["size"] = info.size();
            fileInfo["time"] = info.created().toTime_t();
            fileInfo["ext"] = info.suffix();
            fileInfo["dir"] = false;

            QMimeDatabase db;
            QMimeType type = db.mimeTypeForFile(info.absoluteFilePath());
            fileInfo["mime"] = type.name();

            if (type.name().startsWith("image")) {
                _haveImages = true;
                Q_EMIT haveImagesChanged();
            }
            else if (type.name().startsWith("video")) {
                _haveVideos = true;
                Q_EMIT haveVideosChanged();
            }

            QImageReader reader(info.absoluteFilePath());
            if (reader.canRead()) {
                fileInfo["width"] = reader.size().width();
                fileInfo["height"] = reader.size().height();
            }
            else {
                fileInfo["width"] = 0;
                fileInfo["height"] = 0;
            }

            _modelData.append(fileInfo);
            endInsertRows();
            Q_EMIT countChanged();
        }
    }
}

void Filemodel::clear()
{
    if (fs) {
        fs->removePaths(fs->directories());
        fs->removePaths(fs->files());
    }
    beginResetModel();
    _modelData.clear();
    endResetModel();
}

int Filemodel::count()
{
    return _modelData.size();
}

bool Filemodel::remove(int index)
{
    if (index > -1 && index < _modelData.size()) {
        QFile file(_modelData[index]["path"].toString());
        if (file.exists()) {
            beginRemoveRows(QModelIndex(), index, index);
            _modelData.remove(index);
            endRemoveRows();
            Q_EMIT countChanged();
            return file.remove();
        }
        else
            return false;
    }
    else
        return false;
}

QVariantMap Filemodel::get(int index)
{
    if (index > -1 && index < _modelData.size())
        return _modelData[index];
    return QVariantMap();
}

void Filemodel::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);

    clear();
    recursiveSearch(_rpath);
}

void Filemodel::onFileChanged(const QString &path)
{
    Q_UNUSED(path);

    clear();
    recursiveSearch(_rpath);
}
