#include <QThreadPool>
#include <QDebug>
#include <QStandardPaths>

#include "queryexecutor.h"

QueryExecutor::QueryExecutor(QObject *parent) :
    QObject(parent)
{
    m_worker.setCallObject(this);

    // copying old mitakuuluu database to new place
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::DataLocation);
    QString dataFile = QString("%1/database.db").arg(dataDir);
    QString oldFile = QString("%1/.whatsapp/whatsapp.db").arg(QDir::homePath());

    QFile newDBFile(dataFile);
    QFile oldDBFile(oldFile);

    bool transferBase = false;

    if (!newDBFile.exists() && oldDBFile.exists()) {
        oldDBFile.copy(dataFile);
        transferBase = true;
    }

    db = QSqlDatabase::database();
    if (!db.isOpen()) {
        qDebug() << "QE Opening database";
        db = QSqlDatabase::addDatabase("QSQLITE");
        QDir dir(dataDir);
        if (!dir.exists())
            dir.mkpath(dataDir);
        qDebug() << "DB Dir:" << dataDir;
        db.setDatabaseName(dataFile);
        qDebug() << "DB Name:" << db.databaseName();
        if (db.open())
            qDebug() << "QE opened database";
        else
            qWarning() << "QE failed to open database";
    }
    else {
        qWarning() << "QE used existing DB connection!";
    }

    if (db.isOpen()) {
        if (!db.tables().contains("contacts")) {
            db.exec("CREATE TABLE contacts (jid TEXT, pushname TEXT, name TEXT, message TEXT, contacttype INTEGER, owner TEXT, subowner TEXT, timestamp INTEGER, subtimestamp INTEGER, avatar TEXT, unread INTEGER, lastmessage INTEGER);");
        }
        else if (transferBase) {
            qDebug() << "Begin transfer old database";

            qDebug() << "Tweaking database contacts table";
            db.exec("UPDATE contacts SET contacttype=1;");

            foreach (QString table, db.tables()) {
                if (table.startsWith("u")) {
                    QString tmpTable = table;
                    tmpTable.replace("u", "x");
                    QString jid = table;
                    jid.replace("g", "-").replace("u", "");
                    jid.append(table.contains("g") ? "@g.us" : "@s.whatsapp.net");
                    qDebug() << "Transfer database table" << table << "started";
                    db.exec(QString("ALTER TABLE %1 RENAME TO %2;").arg(table).arg(tmpTable));
                    db.exec(QString("CREATE TABLE %1 (msgid TEXT, jid TEXT, author TEXT, timestamp INTEGER, data TEXT, status INTEGER, watype INTEGER, url TEXT, name TEXT, latitude TEXT, longitude TEXT, size INTEGER, duration INTEGER, width INTEGER, height INTEGER, hash TEXT, mime TEXT, broadcast INTEGER, live INTEGER, local TEXT);").arg(table));
                    QSqlQuery query(db);
                    query.prepare(QString("SELECT msgid, author, timestamp, message, msgstatus FROM %1 WHERE msgtype=(:msgtype);").arg(tmpTable));
                    query.bindValue(":msgtype", 2);
                    query.exec();
                    while (query.next()) {
                        QSqlQuery transfer(db);
                        transfer.prepare(QString("INSERT INTO %1 VALUES (:msgid, :jid, :author, :timestamp, :data, :status, :watype, :url, :name, :latitude, :longitude, :size, :duration, :width, :height, :hash, :mime, :broadcast, :live, :local);").arg(table));
                        transfer.bindValue(":msgid", query.value("msgid"));
                        transfer.bindValue(":jid", jid);
                        transfer.bindValue(":author", query.value("author"));
                        transfer.bindValue(":timestamp", query.value("timestamp"));
                        transfer.bindValue(":data", query.value("message"));
                        transfer.bindValue(":status", query.value("msgstatus"));
                        transfer.bindValue(":watype", 0);
                        transfer.bindValue(":url", "");
                        transfer.bindValue(":name", "");
                        transfer.bindValue(":latitude", "");
                        transfer.bindValue(":longitude", "");
                        transfer.bindValue(":size", 0);
                        transfer.bindValue(":duration", 0);
                        transfer.bindValue(":width", 0);
                        transfer.bindValue(":height", 0);
                        transfer.bindValue(":mime", "");
                        transfer.bindValue(":broadcast", 0);
                        transfer.bindValue(":live", 0);
                        transfer.bindValue(":local", "");
                        transfer.exec();
                    }
                    db.exec(QString("DROP TABLE %1;").arg(tmpTable));
                    qDebug() << "Transfer database table" << table << "complete";
                }
                else if (table == "login") {
                    // drop old login information from table
                    db.exec("DROP TABLE login;");
                }
                else if (table == "muted") {
                    // drop unused table
                    db.exec("DROP TABLE muted;");
                }
            }
        }
    }
}

void QueryExecutor::queueAction(QVariant msg, int priority) {
    m_worker.queueAction(msg, priority);
}

void QueryExecutor::processAction(QVariant message) {
    processQuery(message);
}

void QueryExecutor::processQuery(const QVariant &msg)
{
    QVariantMap query = msg.toMap();
    qDebug() << "QE Processing query:" << query["type"];
    if (!query.isEmpty()) {
        switch (query["type"].toInt()) {
        case QueryType::AccountGetData: {
            getAccountData(query);
            break;
        }
        case QueryType::AccountSetData: {
            setAccountData(query);
            break;
        }
        case QueryType::AccountRemoveData: {
            removeAccountData(query);
            break;
        }
        case QueryType::ContactsGetAll: {
            getContactsAll(query);
            break;
        }
        case QueryType::ContactsSyncContacts:
        case QueryType::ContactsGetJids: {
            getContactsJids(query);
            break;
        }
        case QueryType::ConversationNotifyMessage: {
            messageNotify(query);
            break;
        }
        case QueryType::ContactsSetLastmessage: {
            setContactsLastmessage(query);
            break;
        }
        case QueryType::ConversationSaveMessage: {
            saveConversationMessage(query);
            break;
        }
        case QueryType::ContactsUpdatePushname: {
            setContactPushname(query);
            break;
        }
        case QueryType::ContactsSetUnread: {
            setContactUnread(query);
            break;
        }
        case QueryType::ContactsSyncResults: {
            setContactsResults(query);
            break;
        }
        case QueryType::ContactsSetStatus: {
            setContactStatus(query);
            break;
        }
        case QueryType::ContactsSetSync: {
            setContactSync(query);
            break;
        }
        case QueryType::ContactsSetAvatar: {
            setContactAvatar(query);
            break;
        }
        case QueryType::ContactsMuteGroup: {
            muteGroup(query);
            break;
        }
        case QueryType::ContactsGetMuted: {
            getMuted(query);
            break;
        }
        case QueryType::ConversationGetMessage:
        case QueryType::ConversationGetDownloadMessage: {
            getMessageModel(query);
            break;
        }
        case QueryType::ContactsUpdateGroup: {
            setGroupUpdated(query);
            break;
        }
        case QueryType::ConversationMessageStatus: {
            setMessageStatus(query);
            break;
        }
        case QueryType::ContactsSetLastSeen: {
            setContactLastSeen(query);
            break;
        }
        case QueryType::ContactsSaveModel: {
            setContactModel(query);
            break;
        }
        case QueryType::ContactsGetModel:
        case QueryType::ContactsReloadContact: {
            getContactModel(query);
            break;
        }
        case QueryType::ContactsRemove: {
            removeContact(query);
            break;
        }
        case QueryType::ConversationLoadLast: {
            getLastConversation(query);
            break;
        }
        case QueryType::ConversationLoadNext: {
            getNextConversation(query);
            break;
        }
        case QueryType::ConversationRemoveMessage: {
            removeMessage(query);
            break;
        }
        case QueryType::ConversationRemoveAll: {
            removeAllMessages(query);
            break;
        }
        case QueryType::ConversationSave: {
            saveConversation(query);
            break;
        }
        case QueryType::ConversationDownloadFinished: {
            downloadFinished(query);
            break;
        }
        case QueryType::ConversationMediaUploaded: {
            mediaUploaded(query);
            break;
        }
        case QueryType::ConversationGetMedia: {
            getContactMedia(query);
            break;
        }
        default: {
            break;
        }
        }
    }
}

void QueryExecutor::getAccountData(QVariantMap &query)
{
    QSqlQuery sql("SELECT * FROM login LIMIT 1;", db);
    if (sql.next()) {
        query["username"] = sql.value(0);
        qDebug() << sql.value(0);
        query["password"] = sql.value(1);
        qDebug() << sql.value(1);
    }
    Q_EMIT actionDone(query);
}

void QueryExecutor::setAccountData(QVariantMap &query)
{
    qDebug() << "set account data" << query;
    db.exec("DELETE FROM login;");
    QSqlQuery sql(db);
    sql.prepare("INSERT INTO login VALUES (:username, :password);");
    //sql.prepare("UPDATE login set username=(:username), password=(:password);");
    sql.bindValue(":username", query["username"]);
    sql.bindValue(":password", query["password"]);
    sql.exec();
    Q_EMIT actionDone(query);
}

void QueryExecutor::removeAccountData(QVariantMap &query)
{
    if (db.tables().contains("login")) {
        db.exec("DELETE FROM login;");
    }
    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactsAll(QVariantMap &query)
{
    QSqlQuery sql("SELECT * FROM contacts", db);
    QVariantList contacts;
    while (sql.next()) {
        QVariantMap contact;
        for (int i = 0; i < sql.record().count(); i ++) {
            contact[sql.record().fieldName(i)] = sql.value(i);
        }
        contacts.append(contact);
    }
    query["contacts"] = contacts;

    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactsJids(QVariantMap &query)
{
    QSqlQuery sql("SELECT jid, unread FROM contacts;", db);
    QVariantMap jids;
    while (sql.next()) {
        jids[sql.value(0).toString()] = sql.value(1).toInt();
    }
    query["jids"] = jids;

    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactModel(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("SELECT * FROM contacts WHERE jid=(:jid);");
    sql.bindValue(":jid", query["jid"]);
    sql.exec();
    QVariantMap contact;
    if (sql.next()) {
        for (int i = 0; i < sql.record().count(); i ++) {
            contact[sql.record().fieldName(i)] = sql.value(i);
        }
    }
    query["contact"] = contact;
    Q_EMIT actionDone(query);
}

void QueryExecutor::messageNotify(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QSqlQuery sql(db);
    sql.prepare("SELECT name, message, avatar, unread from contacts where jid=(:jid);");
    sql.bindValue(":jid", jid);
    sql.exec();
    if (sql.next()) {
        QString pushName = query["pushName"].toString();
        QString name = sql.value(0).toString();
        QString message = sql.value(1).toString();
        int unread = sql.value(3).toInt();
        query["unread"] = unread;
        query["avatar"] = sql.value(2);
        QString nickname = pushName;
        if (jid.contains("-"))
            nickname = message;
        else if (name != jid.split("@").first() && !name.isEmpty())
            nickname = name;
        else if (pushName.isEmpty())
            nickname = jid.split("@").first();
        query["name"] = nickname;
    }
    else {
        query["name"] = query["jid"].toString().split("@").first();
        query["avatar"] = QVariant();
        query["unread"] = 0;
    }
    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactsLastmessage(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET lastmessage=(:lastmessage) WHERE jid=(:jid);");
    sql.bindValue(":lastmessage", query["lastmessage"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();
    Q_EMIT actionDone(query);
}

void QueryExecutor::saveConversationMessage(QVariantMap &query)
{
    QString table = "u" + query["jid"].toString().split("@").first().replace("-","g");
    qDebug() << "save message" << query["msgid"].toString() << query["jid"].toString() << "to:" << table;

    if (!db.tables().contains(table)) {
        qDebug() << "create table" << table;
        QSqlQuery q = db.exec(QString("CREATE TABLE %1 (msgid TEXT, jid TEXT, author TEXT, timestamp INTEGER, data TEXT, status INTEGER, watype INTEGER, url TEXT, name TEXT, latitude TEXT, longitude TEXT, size INTEGER, duration INTEGER, width INTEGER, height INTEGER, hash TEXT, mime TEXT, broadcast INTEGER, live INTEGER, local TEXT);").arg(table));
        if (q.lastError().type() != QSqlError::NoError) {
            qDebug() << "Error creating messages table:" << q.lastError().text();
        }
    }

    QSqlQuery i(db);
    i.prepare(QString("INSERT INTO %1 VALUES (:msgid, :jid, :author, :timestamp, :data, :status, :watype, :url, :name, :latitude, :longitude, :size, :duration, :width, :height, :hash, :mime, :broadcast, :live, :local);").arg(table));
    i.bindValue(":msgid", query["msgid"]);
    i.bindValue(":jid", query["jid"]);
    i.bindValue(":author", query["author"]);
    i.bindValue(":timestamp", query["timestamp"]);
    i.bindValue(":data", query["data"]);
    i.bindValue(":status", query["status"]);
    i.bindValue(":watype", query["watype"]);
    i.bindValue(":url", query["url"]);
    i.bindValue(":name", query["name"]);
    i.bindValue(":latitude", query["latitude"]);
    i.bindValue(":longitude", query["longitude"]);
    i.bindValue(":size", query["size"]);
    i.bindValue(":duration", query["duration"]);
    i.bindValue(":width", query["width"]);
    i.bindValue(":height", query["height"]);
    i.bindValue(":mime", query["mime"]);
    i.bindValue(":broadcast", query["broadcast"].toBool() ? 1 : 0);
    i.bindValue(":live", query["live"].toBool() ? 1 : 0);
    i.bindValue(":local", query["local"]);
    i.exec();

    if (i.lastError().type() != QSqlError::NoError) {
        qDebug() << "Error adding message:" << i.lastError().text();
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactPushname(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QString pushName = query["pushName"].toString();
    int timestamp = query["timestamp"].toInt();

    query["exists"] = true;

    QSqlQuery e(db);
    e.prepare("UPDATE contacts SET pushname=(:pushname) WHERE jid=(:jid);");
    e.bindValue(":pushname", jid.contains("-") ? jid : pushName);
    e.bindValue(":jid", jid);
    e.exec();

    if (e.lastError().type() != QSqlError::NoError) {
        qDebug() << "Error update setContactPushname:" << e.lastError().text();
    }

    if (e.numRowsAffected() == 0) {
        QSqlQuery ic(db);
        ic.prepare("INSERT INTO contacts VALUES (:jid, :pushname, :name, :message, :contacttype, :owner, :subowner, :timestamp, :subtimestamp, :avatar, :unread, :lastmessage);");
        ic.bindValue(":jid", jid);
        ic.bindValue(":pushname", pushName.isEmpty() ? jid.split("@").first() : pushName);
        ic.bindValue(":name", pushName.isEmpty() ? jid.split("@").first() : pushName);
        ic.bindValue(":message", "");
        ic.bindValue(":contacttype", 0);
        ic.bindValue(":owner", "");
        ic.bindValue(":subowner", "");
        ic.bindValue(":timestamp", 0);
        ic.bindValue(":subtimestamp", 0);
        ic.bindValue(":avatar", "");
        ic.bindValue(":unread", 0);
        ic.bindValue(":lastmessage", pushName.isEmpty() ? 0 : timestamp);
        ic.exec();

        if (ic.lastError().type() != QSqlError::NoError) {
            qDebug() << "Error insert setContactPushname:" << ic.lastError().text();
        }

        query["exists"] = false;
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactUnread(QVariantMap query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET unread=(:unread) WHERE jid=(:jid);");
    sql.bindValue(":unread", query["unread"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactsResults(QVariantMap &query)
{
    QString lastJid;
    QStringList newJids;
    QVariantList avatars;
    QVariantList results = query["contacts"].toList();
    QVariantList blocked = query["blocked"].toList();
    foreach (QVariant vcontact, results) {
        QVariantMap contact = vcontact.toMap();
        //qDebug() << "Contact:" << contact;
        //qDebug() << contact;
        QString jid = contact["jid"].toString();
        if (!blocked.contains(jid)) {
            newJids.append(jid);
            QString phone = contact["phone"].toString();
            QString avatar = contact["avatar"].toString();
            QString name = contact["alias"].toString();
            qDebug() << "Name:" << name << "Phone:" << phone << "Jid:" << jid;

            QSqlQuery uc;
            //uc.prepare("UPDATE contacts SET name=(:name), message=(:message), timestamp=(:timestamp) WHERE jid=(:jid);");
            uc.prepare("UPDATE contacts SET name=(:name), contacttype=(:contacttype) WHERE jid=(:jid);");
            uc.bindValue(":name", name);
            uc.bindValue(":contacttype", 1);
            //uc.bindValue(":timestamp", timestamp);
            uc.bindValue(":jid", jid);
            uc.exec();

            if (uc.lastError().type() != QSqlError::NoError)
                qDebug() << "[contacts] Update pushname result:" << uc.lastError();

            if (uc.numRowsAffected() == 0) {
                qDebug() << "insert new contact:" << name;
                QSqlQuery ic;
                ic.prepare("INSERT INTO contacts VALUES (:jid, :pushname, :name, :message, :contacttype, :owner, :subowner, :timestamp, :subtimestamp, :avatar, :unread, :lastmessage);");
                ic.bindValue(":jid", jid);
                ic.bindValue(":pushname", name);
                ic.bindValue(":name", name);
                ic.bindValue(":message", QString());
                ic.bindValue(":contacttype", 1);
                ic.bindValue(":owner", "");
                ic.bindValue(":subowner", "");
                ic.bindValue(":timestamp", 0);
                ic.bindValue(":subtimestamp", 0);
                ic.bindValue(":avatar", avatar);
                ic.bindValue(":unread", 0);
                ic.bindValue(":lastmessage", 0);
                ic.exec();

                if (ic.lastError().type() != QSqlError::NoError)
                    qDebug() << "[contacts] Insert error:" << ic.lastError();

                if (results.length() == 1) {
                    QVariantMap contact;
                    contact["jid"] = jid;
                    contact["name"] = name;
                    contact["pushname"] = name;
                    contact["nickname"] = name;
                    contact["message"] = QString();
                    contact["contacttype"] = 1;
                    contact["owner"] = QString();
                    contact["subowner"] = QString();
                    contact["timestamp"] = 0;
                    contact["subtimestamp"] = 0;
                    contact["avatar"] = avatar;
                    contact["available"] = false;
                    contact["unread"] = 0;
                    contact["lastmessage"] = 0;
                    contact["blocked"] = false;

                    query["contact"] = contact;
                }
            }
            else if (results.length() == 1) {
                QVariantMap contact;
                contact["name"] = name;
                contact["jid"] = jid;

                query["sync"] = contact;
            }
            if (avatar.isEmpty())
                avatars.append(jid);
            lastJid = jid;
        }
    }
    query["jids"] = newJids;

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactStatus(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET message=(:message), WHERE jid=(:jid);");
    sql.bindValue(":message", query["message"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactSync(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET message=(:message), timestamp=(:timestamp) WHERE jid=(:jid);");
    sql.bindValue(":message", query["message"]);
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactAvatar(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET avatar=(:avatar) WHERE jid=(:jid);");
    sql.bindValue(":avatar", query["avatar"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::getMessageModel(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QString table = jid.split("@").first().replace("-", "g");
    QSqlQuery sql(db);
    sql.prepare(QString("SELECT * FROM u%1 WHERE msgid=(:msgid);").arg(table));
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();
    QVariantMap message;
    if (sql.next()) {
        for (int i = 0; i < sql.record().count(); i ++) {
            message[sql.record().fieldName(i)] = sql.value(i);
        }
    }
    message["jid"] = query["jid"];
    query["message"] = message;
    Q_EMIT actionDone(query);
}

void QueryExecutor::setGroupUpdated(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET message=(:message), subowner=(:subowner), subtimestamp=(:subtimestamp) WHERE jid=(:jid);");
    sql.bindValue(":message", query["message"]);
    sql.bindValue(":subowner", query["subowner"]);
    sql.bindValue(":subtimestamp", query["subtimestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    query["exists"] = sql.numRowsAffected() != 0;

    Q_EMIT actionDone(query);
}

void QueryExecutor::setMessageStatus(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QSqlQuery sql(db);
    sql.prepare(QString("UPDATE u%1 SET status=(:status) WHERE msgid=(:msgid);").arg(jid.split("@").first().replace("-", "g")));
    sql.bindValue(":status", query["status"]);
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactLastSeen(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET timestamp=(:timestamp) WHERE jid=(:jid);");
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::setContactModel(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET owner=(:owner), message=(:message), name=(:name), subowner=(:subowner), subtimestamp=(:subtimestamp), timestamp=(:timestamp)  WHERE jid=(:jid);");
    sql.bindValue(":owner", query["owner"]);
    sql.bindValue(":message", query["message"]);
    sql.bindValue(":name", query["name"]);
    sql.bindValue(":subowner", query["subowner"]);
    sql.bindValue(":subtimestamp", query["subtimestamp"]);
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();
    query["exists"] = true;

    if (sql.numRowsAffected() == 0) {
        QSqlQuery ic;
        ic.prepare("INSERT INTO contacts VALUES (:jid, :pushname, :name, :message, :contacttype, :owner, :subowner, :timestamp, :subtimestamp, :avatar, :unread, :lastmessage);");
        ic.bindValue(":jid", query["jid"]);
        ic.bindValue(":pushname", query["pushname"]);
        ic.bindValue(":name", query["name"]);
        ic.bindValue(":message", query["message"]);
        ic.bindValue(":contacttype", query["contacttype"]);
        ic.bindValue(":owner", query["owner"]);
        ic.bindValue(":subowner", query["subowner"]);
        ic.bindValue(":timestamp", query["timestamp"]);
        ic.bindValue(":subtimestamp", query["subtimestamp"]);
        ic.bindValue(":avatar", "");
        ic.bindValue(":unread", 0);
        ic.bindValue(":lastmessage", 0);
        ic.exec();
        query["exists"] = false;
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::removeContact(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare("DELETE FROM contacts WHERE jid=(:jid);");
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::getLastConversation(QVariantMap &query)
{
    QString table = query["table"].toString();
    QSqlQuery sql(QString("SELECT * FROM u%1 ORDER BY timestamp DESC LIMIT 20;").arg(table), db);
    QVariantList messages;
    while (sql.next()) {
        QVariantMap message;
        for (int i = 0; i < sql.record().count(); i ++) {
            message[sql.record().fieldName(i)] = sql.value(i);
        }
        messages.append(message);
    }
    query["messages"] = messages;

    Q_EMIT actionDone(query);
}

void QueryExecutor::getNextConversation(QVariantMap &query)
{
    QString table = query["table"].toString();
    QSqlQuery sql(db);
    sql.prepare(QString("SELECT * FROM u%1 WHERE timestamp<(:timestamp) ORDER BY timestamp DESC LIMIT (:count);").arg(table));
    sql.bindValue(":timestamp", query["timestamp"]);
    sql.bindValue(":count", query["count"]);
    sql.exec();
    QVariantList messages;
    while (sql.next()) {
        QVariantMap message;
        for (int i = 0; i < sql.record().count(); i ++) {
            message[sql.record().fieldName(i)] = sql.value(i);
        }
        messages.append(message);
    }
    query["messages"] = messages;

    Q_EMIT actionDone(query);
}

void QueryExecutor::removeMessage(QVariantMap &query)
{
    QString table = query["table"].toString();
    QSqlQuery sql(db);
    sql.prepare(QString("DELETE FROM u%1 WHERE msgid=(:msgid);").arg(table));
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::removeAllMessages(QVariantMap &query)
{
    QString table = query["table"].toString();
    db.exec(QString("DELETE FROM u%1;").arg(table));

    QSqlQuery sql(db);
    sql.prepare("UPDATE contacts SET lastmessage=(:lastmessage) WHERE jid=(:jid);");
    sql.bindValue(":lastmessage", 0);
    sql.bindValue(":jid", query["jid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::saveConversation(QVariantMap &query)
{
    //TODO FIX IT!
    QString table = query["table"].toString();
    QString jid = query["jid"].toString();

    QString docs = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/Mitakuuluu/";

    QDir dira(docs);
    if (!dira.exists())
        dira.mkpath(docs);
    QFile conv(docs + query["name"].toString() + ".txt");
    if (conv.open(QFile::WriteOnly | QFile::Text)) {
        QTextStream out(&conv);
        QVariantMap jidName;
        QSqlQuery sql(QString("SELECT * FROM u%1 ORDER BY timestamp ASC;").arg(table), db);
        while (sql.next()) {
            QVariantMap message;
            QString jid = message["author"].toString();
            for (int i = 0; i < sql.record().count(); i ++) {
                message[sql.record().fieldName(i)] = sql.value(i);
            }
            QString timestamp = QDateTime::fromTime_t(message["timestamp"].toInt()).toString("dd MMM hh:mm:ss");
            QString text;
            switch (message["watype"].toInt()) {
            case 0: text = message["data"].toString(); break;
            //case 1: text = "picture " + message["url"].toString(); break;
            //case 2: text = "audio " + message["url"].toString(); break;
            //case 3: text = "video " + message["url"].toString(); break;
            //case 4: text = "contact " + message["name"].toString(); break;
            //case 5: text = "location " + message["longitude"].toString() + "," + message["latitude"].toString(); break;
            default: text = "media"; break;
            }
            QString nickname;
            if (jidName.contains(jid)) {
                nickname = jidName[jid].toString();
            }
            else {
                QSqlQuery nq(db);
                nq.prepare("SELECT pushname, name, message FROM contacts where jid=(:jid);");
                nq.bindValue(":jid", jid);
                nq.exec();
                if (sql.next()) {
                    QString pushname = sql.value(0).toString();
                    QString name = sql.value(1).toString();
                    QString message = sql.value(2).toString();
                    if (jid.contains("-")) {
                        nickname = message;
                    }
                    else if (name == jid.split("@").first() || name.isEmpty()) {
                        if (!pushname.isEmpty())
                            nickname = pushname;
                        else
                            nickname = jid.split("@").first();
                    }
                    else {
                        nickname = name;
                    }
                    jidName[jid] = nickname;
                }
                else {
                    nickname = jid.split("@").first();
                }
            }
            QString fmt;
            if (jid.contains("-")) {
                fmt = QString("%1 <%2>: %3").arg(timestamp).arg(nickname).arg(text);
            }
            else {
                fmt = QString("[%1] %2: %2").arg(timestamp).arg(nickname).arg(text);
            }
            out << fmt << "\n";
        }
        conv.close();
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::downloadFinished(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare(QString("UPDATE u%1 SET local=(:local) WHERE msgid=(:msgid);").arg(query["jid"].toString().split("@").first().replace("-", "g")));
    sql.bindValue(":local", query["url"]);
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::muteGroup(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    int expire = query["expire"].toInt();
    bool mute = query["mute"].toBool();
    if (mute) {
        QSqlQuery sql(db);
        sql.prepare("UPDATE muted SET jid=(:jid), expire=(:expire) WHERE jid=(:jid);");
        sql.bindValue(":jid", jid);
        sql.bindValue(":expire", expire);
        sql.exec();

        if (sql.numRowsAffected() == 0) {
            QSqlQuery ic;
            ic.prepare("INSERT INTO muted VALUES (:jid, :expire);");
            ic.bindValue(":jid", jid);
            sql.bindValue(":expire", expire);
            ic.exec();
        }
    }
    else {
        QSqlQuery sql(db);
        sql.prepare("DELETE FROM muted WHERE jid=(:jid);");
        sql.bindValue(":jid", jid);
        sql.exec();
    }

    Q_EMIT actionDone(query);
}

void QueryExecutor::getMuted(QVariantMap &query)
{
    QVariantMap jids;
    QSqlQuery sql("SELECT jid, expire FROM muted;", db);
    while (sql.next()) {
        jids[sql.value(0).toString()] = sql.value(1).toInt();
    }
    query["result"] = jids;

    Q_EMIT actionDone(query);
}

void QueryExecutor::mediaUploaded(QVariantMap &query)
{
    QString jid = query["jid"].toString();
    QSqlQuery sql(db);
    sql.prepare(QString("UPDATE u%1 SET local=(:local) WHERE msgid=(:msgid);").arg(jid.split("@").first().replace("-", "g")));
    sql.bindValue(":local", query["url"]);
    sql.bindValue(":msgid", query["msgid"]);
    sql.exec();

    Q_EMIT actionDone(query);
}

void QueryExecutor::getContactMedia(QVariantMap &query)
{
    QSqlQuery sql(db);
    sql.prepare(QString("SELECT local, mime FROM u%1 WHERE (watype=1 OR watype=3) AND author=(:author) ORDER BY timestamp DESC;").arg(query["table"].toString()));
    sql.bindValue(":author", query["jid"].toString());
    sql.exec();
    QVariantList mediaList;
    while (sql.next()) {
        QVariantMap media;
        media["path"] = sql.value(0);
        media["mime"] = sql.value(1);
        mediaList.append(media);
    }
    query["media"] = mediaList;

    Q_EMIT actionDone(query);
}

QueryExecutor* QueryExecutor::GetInstance()
{
    static QueryExecutor* lsSingleton = NULL;
    if (!lsSingleton) {
        lsSingleton = new QueryExecutor(0);
    }
    return lsSingleton;
}
