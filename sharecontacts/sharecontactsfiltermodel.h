#ifndef SHARECONTACTSFILTERMODEL_H
#define SHARECONTACTSFILTERMODEL_H

#include "sharecontactsbasemodel.h"

#include <QSortFilterProxyModel>

class ShareContactsFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count FINAL)
public:
    explicit ShareContactsFilterModel(QObject *parent = 0);

public slots:
    Q_INVOKABLE void startSharing(const QStringList &jids, const QString &name, const QString &data);

private:
    int count();

    ShareContactsBaseModel *_baseModel;
};

#endif // SHARECONTACTSFILTERMODEL_H
