#include "filesmodel.h"

#include <QDateTime>
#include <QDebug>

FilesModel::FilesModel(QObject *parent) :
    QAbstractListModel(parent)
{
    _roles[NameRole] = "name";
    _roles[PathRole] = "path";
    _roles[SizeRole] = "size";
    _roles[TimestampRole] = "time";
    _roles[ExtensionRole] = "ext";
    _roles[DirRole] = "dir";
    //setRoleNames(_roles);
    _sorting = true;
    _path = "/home/nemo";
    _filter = QStringList() << "*.*";
}

FilesModel::~FilesModel()
{
    _modelData.clear();
}

int FilesModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return _modelData.size();
}

QVariant FilesModel::data(const QModelIndex &index, int role) const
{
    //qDebug() << "get" << QString::number(index.row()) << _roles[role];
    int row = index.row();
    if (row < 0 || row >= _modelData.size())
        return QVariant();
    //return _modelData.at(index.row()).value(_roles.value(role));
    return _modelData[index.row()][_roles[role]];
}

QStringList &FilesModel::getFilter()
{
    return _filter;
}

void FilesModel::setFilter(const QStringList &filter)
{
    //qDebug() << "set filter:" << filter;
    _filter = filter;
}

QString &FilesModel::getPath()
{
    return _path;
}

bool FilesModel::getSorting()
{
    return _sorting;
}

void FilesModel::setSorting(bool newSorting)
{
    _sorting = newSorting;
}

void FilesModel::showRecursive(const QStringList &dirs)
{
    clear();

    foreach (const QString &path, dirs) {
        //qDebug() << "Processing folder:" << path;
        recursiveSearch(path);
    }
}

void FilesModel::processPath(const QString &path)
{
    _path = path;
    clear();

    //qDebug() << "Processing" << path << _filter;
    QDir dir(path);
    const QFileInfoList &list = dir.entryInfoList(_filter, QDir::AllDirs | QDir::NoDot | QDir::NoSymLinks | QDir::Files, (_sorting ? QDir::Time : QDir::Name) | QDir::DirsFirst);
    foreach (const QFileInfo &info, list) {
        //qDebug() << "adding" << info.absoluteFilePath();
        if (dir.isRoot() && info.fileName() == "..")
            continue;
        QVariantMap fileInfo;

        beginInsertRows(QModelIndex(), _modelData.size(), _modelData.size());
        fileInfo["name"] = info.fileName();
        fileInfo["path"] = info.absoluteFilePath();
        fileInfo["size"] = info.size();
        fileInfo["time"] = info.created().toTime_t();
        fileInfo["ext"] = info.suffix();
        fileInfo["dir"] = info.isDir();

        _modelData.append(fileInfo);
        endInsertRows();
    }
}

void FilesModel::recursiveSearch(const QString &path)
{
    //qDebug() << "Processing" << path << _filter;
    QDir dir(path);
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
            fileInfo["path"] = info.filePath();
            fileInfo["size"] = info.size();
            fileInfo["time"] = info.created().toTime_t();
            fileInfo["ext"] = info.suffix();
            fileInfo["dir"] = false;

            _modelData.append(fileInfo);
            endInsertRows();
        }
    }
}

void FilesModel::clear()
{
    beginResetModel();
    _modelData.clear();
    endResetModel();
}

int FilesModel::count()
{
    return rowCount();
}
