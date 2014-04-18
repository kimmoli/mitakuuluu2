#ifndef FILESMODEL_H
#define FILESMODEL_H

#include <QObject>
#include <QAbstractListModel>

#include <QVector>
#include <QVariantMap>
#include <QVariantList>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>

class FilesModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QStringList filter READ getFilter WRITE setFilter FINAL)
    Q_PROPERTY(QString path READ getPath WRITE processPath FINAL)
    Q_PROPERTY(bool sorting READ getSorting WRITE setSorting)

public:
    enum FileRoles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        SizeRole,
        TimestampRole,
        ExtensionRole,
        DirRole
    };
    explicit FilesModel(QObject *parent = 0);
    virtual ~FilesModel();

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    virtual QHash<int, QByteArray> roleNames() const { return _roles; }
    
private:
    void recursiveSearch(const QString &path);

    QHash<int, QByteArray> _roles;
    QVector<QVariantMap> _modelData;

    QStringList _filter;
    QStringList& getFilter();
    void setFilter(const QStringList &filter);

    QString _path;
    QString& getPath();
    void setPath(const QString &path);

    bool _sorting;
    bool getSorting();
    void setSorting(bool newSorting);
    
public slots:
    void showRecursive(const QStringList &dirs);
    void processPath(const QString &path);
    void clear();
    int count();
    
};

#endif // FILESMODEL_H
