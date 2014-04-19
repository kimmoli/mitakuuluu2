#include "sharecontactsfiltermodel.h"

ShareContactsFilterModel::ShareContactsFilterModel(QObject *parent) :
    QSortFilterProxyModel(parent)
{
    setSortRole(Qt::UserRole + 4);
    setSortCaseSensitivity(Qt::CaseInsensitive);
    setSortLocaleAware(true);
    _baseModel = new ShareContactsBaseModel(parent);
    setSourceModel(_baseModel);
    sort(0);
}

void ShareContactsFilterModel::startSharing(const QStringList &jids, const QString &name, const QString &data)
{
    _baseModel->startSharing(jids, name, data);
}

QVariantMap ShareContactsFilterModel::get(int itemIndex)
{
    QModelIndex sourceIndex = mapToSource(index(itemIndex, 0, QModelIndex()));
    QVariantMap data = _baseModel->get(sourceIndex.row());
    return data;
}

int ShareContactsFilterModel::count()
{
    return rowCount();
}
