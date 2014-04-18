#include "contactsfiltermodel.h"

ContactsFilterModel::ContactsFilterModel(QObject *parent) :
    QSortFilterProxyModel(parent),
    _showActive(false),
    _showUnknown(false),
    _filter("")
{
    setFilterRole(Qt::UserRole + 1);
    setSortRole(Qt::UserRole + 1);
    sort(0);
}

QVariantMap ContactsFilterModel::get(int itemIndex)
{
    QModelIndex sourceIndex = index(itemIndex, 0, QModelIndex());
    QVariantMap data = _contactsModel->get(sourceIndex.row());
    return data;
}

bool ContactsFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    QString jid = sourceModel()->data(index, Qt::UserRole + 1).toString();
    if (_showActive && !jid.contains("-")) {
        int lastmessage = sourceModel()->data(index, Qt::UserRole + 14).toInt();
        if (lastmessage == 0)
            return false;
    }
    if (!_showUnknown) {
        int contacttype = sourceModel()->data(index, Qt::UserRole + 6).toInt();
        if (contacttype == 0)
            return false;
    }
    if (_hideGroups) {
        if (jid.contains("-"))
            return false;
    }
    QString nickname = sourceModel()->data(index, Qt::UserRole + 4).toString();
    return nickname.contains(_filter, Qt::CaseInsensitive);
}

bool ContactsFilterModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    if (_showActive) {
        int leftlastmessage = sourceModel()->data(left, Qt::UserRole + 14).toInt();
        int rightlastmessage = sourceModel()->data(right, Qt::UserRole + 14).toInt();
        if (leftlastmessage > rightlastmessage)
            return true;
        else if (rightlastmessage > leftlastmessage)
            return false;
    }

    QString leftString = sourceModel()->data(left, Qt::UserRole + 4).toString();
    QString rightString = sourceModel()->data(right, Qt::UserRole + 4).toString();

    return QString::localeAwareCompare(leftString.toLower(), rightString.toLower()) < 0;
}

QString ContactsFilterModel::filter()
{
    return _filter;
}

void ContactsFilterModel::setFilter(const QString &newFilter)
{
    _filter = newFilter;
    changeFilterRole();
    Q_EMIT filterChanged();
}

bool ContactsFilterModel::showActive()
{
    return _showActive;
}

void ContactsFilterModel::setShowActive(bool value)
{
    _showActive = value;
    changeSortRole();
    changeFilterRole();
}

bool ContactsFilterModel::showUnknown()
{
    return _showUnknown;
}

void ContactsFilterModel::setShowUnknown(bool value)
{
    _showUnknown = value;
    changeFilterRole();
}

bool ContactsFilterModel::hideGroups()
{
    return _hideGroups;
}

void ContactsFilterModel::setHideGroups(bool value)
{
    _hideGroups = value;
    changeFilterRole();
}

int ContactsFilterModel::count()
{
    return rowCount();
}

void ContactsFilterModel::changeSortRole()
{
    int role = Qt::UserRole + 1;
    if (_showActive)
        role += 1;
    setSortRole(role);
    sort(0);
}

void ContactsFilterModel::changeFilterRole()
{
    int role = Qt::UserRole + 1;
    if (_showUnknown)
        role += 1;
    if (_showActive)
        role += 2;
    if (!_filter.isEmpty())
        role += 4;
    if (_hideGroups)
        role += 8;
    setFilterRole(role);
}

ContactsBaseModel *ContactsFilterModel::contactsModel()
{
    return _contactsModel;
}

void ContactsFilterModel::setContactsModel(ContactsBaseModel *newModel)
{
    _contactsModel = newModel;
    setSourceModel(_contactsModel);
    Q_EMIT contactsModelChanged();
}
