/* Copyright 2013 Naikel Aparicio. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL EELI REILIN OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation
 * are those of the author and should not be interpreted as representing
 * official policies, either expressed or implied, of the copyright holder.
 */

#include <QSslConfiguration>
#include <QRegExp>
#include <QImage>
#include <QUrl>

#include "src/Whatsapp/util/utilities.h"
#include "src/Whatsapp/util/qtmd5digest.h"

#include "src/qt-json/json.h"

#include "src/client.h"
#include "src/globalconstants.h"
#include "contactsyncer.h"

#include <QtContacts/QContact>
#include <QtContacts/QContactManager>
#include <QtContacts/QContactFetchRequest>
#include <QtContacts/QtContacts>
#include <QtContacts/QContactDisplayLabel>

ContactSyncer::ContactSyncer(QObject *parent)
    : HttpRequestv2(parent)
{
    isSyncing = false;

    connect(this,SIGNAL(headersReceived(qint64)),
            this,SLOT(increaseDownloadCounter(qint64)));

    connect(this,SIGNAL(requestSent(qint64)),
            this,SLOT(increaseUploadCounter(qint64)));

}

QString ContactSyncer::getAuthResponse(QString nonce)
{
    // New contact synchronization method

    QtMD5Digest digest;

    qint64 clock = QDateTime::currentMSecsSinceEpoch();

    QString cnonce = QString::number(clock,36);
    QString nc = "00000001";
    QString digestUri = "WAWA/" JID_DOMAIN;

    // Login information
    QByteArray password = QByteArray::fromBase64(Client::password.toUtf8());

    QString loginStr = Client::phoneNumber + ":" + JID_DOMAIN + ":";
    QByteArray bArray = loginStr.toUtf8();
    bArray.append(password);
    digest.update(bArray);
    QByteArray loginArray = digest.digest();
    digest.reset();

    // Nonce and Cnonce information
    QString nonceStr = ":" + nonce + ":" + cnonce;
    loginArray.append(nonceStr.toUtf8());
    digest.update(loginArray);
    QByteArray authentication = encode(digest.digest());
    digest.reset();

    QString nonceauthStr = ":" + nonce + ":" + nc + ":" + cnonce + ":auth:";
    authentication.append(nonceauthStr.toUtf8());

    // Authentication information
    QString authStr = "AUTHENTICATE:" + digestUri;
    digest.update(authStr.toUtf8());
    authentication.append(encode(digest.digest()));
    digest.reset();

    digest.update(authentication);

    QString response = "X-WAWA: username=\"";

    response.append(Client::phoneNumber);
    response.append("\",realm=\"");
    response.append(JID_DOMAIN);
    response.append("\",nonce=\"");
    response.append(nonce);
    response.append("\",cnonce=\"");
    response.append(cnonce);
    response.append("\",nc=\"");
    response.append(nc);
    response.append("\",qop=\"auth\",digest-uri=\"");
    response.append(digestUri);
    response.append("\",response=\"");
    response.append(QUrl::toPercentEncoding(QString::fromUtf8(encode(digest.digest()))));
    //response.append(QString::fromUtf8(encode(digest.digest())));
    response.append("\",charset=\"utf-8\"");

    return response;
}

QByteArray ContactSyncer::encode(QByteArray bytes)
{
    QByteArray result;

    for (int j = 0; j < bytes.length(); j++)
    {
        int k = bytes.at(j);
        if (k < 0)
            k += 256;

        result.append(encodeByte(k >> 4));
        result.append(encodeByte(k % 16));
    }

    return result;
}

int ContactSyncer::encodeByte(int c)
{
    return (c < 10) ? c + 48 : c + 87;
}

void ContactSyncer::freeAddressBook()
{

}

void ContactSyncer::sync()
{
    if (!isSyncing && Client::connectionStatus == Client::LoggedIn)
    {
        qDebug() << "syncer: Synchronizing contacts...";

        isSyncing = true;
        syncDataReceived = false;
        emit progress(0);

        contactManager = new QContactManager(this);
        QList<QContact> results = contactManager->contacts();
        qDebug() << "Phone numbers retreived. Processing" << QString::number(results.size()) << "contacts.";
        syncList.clear();
        for (int i = 0; i < results.size(); ++i) {
            QString avatar;
            QList<QContactAvatar> avatars = results.at(i).details<QContactAvatar>();
            QList<QContactDisplayLabel> labels = results.at(i).details<QContactDisplayLabel>();
            QString label;
            if (labels.size() > 0 && !labels.first().isEmpty())
                label = labels.first().label();
            if (avatars.length() > 0 && !avatars.first().isEmpty())
                avatar = avatars.first().imageUrl().toString();
            foreach (QContactPhoneNumber number, results.at(i).details<QContactPhoneNumber>()) {
                if (!number.isEmpty()) {
                    QString phone = QContactPhoneNumber(number).number();
                    phone = phone.replace(QRegExp("/[^0-9+]/g"),"");
                    qDebug() << "phone:" << phone;
                    _contacts[phone] = label;
                    _avatars[phone] = avatar;
                    syncList.append(phone);
                    if (!phone.startsWith("+")) {
                        _contacts["+" + phone] = label;
                        _avatars["+" + phone] = avatar;
                        syncList.append("+" + phone);
                    }
                }
            }
        }
        contactManager->deleteLater();
        if (syncList.length() > 0) {
            syncAddressBook();
        }
    }
}

void ContactSyncer::syncContacts(const QStringList &jids)
{
    if (!isSyncing && Client::connectionStatus == Client::LoggedIn)
    {
        qDebug() << "syncer: Synchronizing contacts:" << jids.join(", ");
        isSyncing = true;
        syncDataReceived = false;

        syncList.clear();
        foreach (QString jid, jids) {
            QString phone = jid.split("@").first();
            syncList.append(phone);
            if (!phone.startsWith("+"))
                syncList.append("+" + phone);
        }

        syncAddressBook();
    }
}

void ContactSyncer::syncContacts(const QStringList &numbers, const QStringList &names, const QStringList &avatars)
{
    if (!isSyncing && Client::connectionStatus == Client::LoggedIn)
    {
        qDebug() << "syncer: Synchronizing contacts:" << numbers.join(", ");
        isSyncing = true;
        syncDataReceived = false;

        syncList.clear();
        for (int i = 0; i < numbers.size(); i++) {
            QString phone = numbers.at(i);
            phone = phone.replace(QRegExp("/[^0-9+]/g"),"");
            QString label = names.at(i);
            QString avatar = avatars.at(i);
            syncList.append(phone);
            _contacts[phone] = label;
            _avatars[phone] = avatar;
            if (!phone.startsWith("+")) {
                syncList.append("+" + phone);
                _contacts["+" + phone] = label;
                _avatars["+" + phone] = avatar;
            }
        }

        syncAddressBook();
    }
}

void ContactSyncer::addContact(const QString &name, const QString &phone)
{
    if (!isSyncing && Client::connectionStatus == Client::LoggedIn)
    {
        qDebug() << "syncer: Synchronizing contacts:" << name;
        isSyncing = true;
        syncDataReceived = false;

        syncList.append(phone);
        _contacts[phone] = name;
        if (!phone.startsWith("+")) {
            syncList.append("+" + phone);
            _contacts["+" + phone] = name;
        }

        syncAddressBook();
    }
}

void ContactSyncer::syncAddressBook()
{
    QString response = getAuthResponse("0");

    connect(this,SIGNAL(finished()),this,SLOT(authResponse()));
    connect(this,SIGNAL(socketError(QAbstractSocket::SocketError)),
            this,SLOT(errorHandler(QAbstractSocket::SocketError)));

    setHeader("Authorization", response);

    qDebug() << "syncer: Authenticating...";
    post(QUrl(URL_CONTACTS_AUTH), writeBuffer.constData(), writeBuffer.length());
}

void ContactSyncer::authResponse()
{
    qDebug() << "syncer: authResponse()";
    QString result = QString::fromUtf8(socket->readAll().constData());
    disconnect(this, SIGNAL(finished()), this, SLOT(authResponse()));

    // qDebug() << "Reply: " << result;

    QString authData = getHeader("WWW-Authenticate");
    // qDebug() << "authData:" << authData;
    QString nonce;

    clearHeaders();

    bool ok;
    QVariantMap mapResult = QtJson::parse(result, ok).toMap();

    QString message = mapResult.value("message").toString();

    if (message == "next token")
    {
        // Get nonce
        QRegExp noncereg("nonce=\"([^\"]+)\"");

        int pos = noncereg.indexIn(authData,0);

        if (pos != -1)
        {
            nonce = noncereg.cap(1);
        }

        qDebug() << "syncer: Authentication successful";
        qDebug() << "nonce:" << nonce;

        QString response = getAuthResponse(nonce);

        connect(this,SIGNAL(finished()),this,SLOT(onResponse()));

        setHeader("Authorization", response);

        qDebug() << "syncer: Sending contacts info...";

        // Synchronize all contacts

        if (syncList.size() > 0)
        {
            writeBuffer.clear();
            addParam("ut","wa");
            addParam("t", "c");

            foreach (QString phone, syncList)
            {
                addParam("u[]",phone);
            }

            post(QUrl(URL_CONTACTS_SYNC),writeBuffer.constData(), writeBuffer.length());
        }
    }
    else
    {
        qDebug() << "syncer: Authentication failed.";

        // Free everything
        freeAddressBook();
        isSyncing = false;
        emit syncFinished();
    }
}

void ContactSyncer::onResponse()
{
    if (errorCode != 200)
    {
        emit httpError(errorCode);
        return;
    }

    totalLength = getHeader("Content-Length").toLongLong();

    qDebug() << "syncer: Content-Length:" << QString::number(totalLength);

    if (socket->bytesAvailable())
        fillBuffer();

    connect(socket,SIGNAL(readyRead()),this,SLOT(fillBuffer()));
}

void ContactSyncer::fillBuffer()
{
    qint64 bytesToRead = socket->bytesAvailable();

    readBuffer.append(socket->read(bytesToRead));

    if (readBuffer.size() == totalLength)
    {
        increaseDownloadCounter(totalLength);

        disconnect(this,SIGNAL(socketError(QAbstractSocket::SocketError)),
                   this,SLOT(errorHandler(QAbstractSocket::SocketError)));

        syncDataReceived = true;
        socket->close();

        parseResponse();
    }
}


void ContactSyncer::parseResponse()
{
    QString jsonStr = QString::fromUtf8(readBuffer.constData());

    qDebug() << "Reply:" << jsonStr;

    bool ok;
    QVariantMap mapResult = QtJson::parse(jsonStr, ok).toMap();
    if (!ok)
        qDebug() << "Error parsing json reply!";

    if (mapResult.keys().contains("c"))
    {
        qDebug() << "Have contacts!";
        phoneList = mapResult.value("c").toList();
        qDebug() << "Response length:" << phoneList.size();

        for (int i = 0; i < phoneList.size(); i++) {
            QVariantMap item = phoneList[i].toMap();
            QString phone = item["p"].toString();
            QString number = item["n"].toString();
            QString message = item["s"].toString();
            Utilities::softbankReplace(message);
            item["s"] = message;
            QString avatar;
            if (_avatars.keys().contains(phone))
                avatar = _avatars[phone].toString();
            if (_avatars.keys().contains("+" + phone))
                avatar = _avatars["+" + phone].toString();
            if (_avatars.keys().contains(number))
                avatar = _avatars[number].toString();
            if (_avatars.keys().contains("+" + number))
                avatar = _avatars["+" + number].toString();
            QString name;
            if (_contacts.keys().contains(number)) {
                name = _contacts[number].toString();
            }
            if (_contacts.keys().contains("+" + number)) {
                name = _contacts["+" + number].toString();
            }
            if (_contacts.keys().contains(phone)) {
                name = _contacts[phone].toString();
            }
            if (_contacts.keys().contains("+" + phone)) {
                name = _contacts["+" + phone].toString();
            }
            item["a"] = avatar;
            item["l"] = name;

            phoneList[i] = item;
            //qDebug() << "SYNC REPLY:" << phoneList[i];
            if (item["w"].toInt() == 1) {
                Q_EMIT photoRefresh(number + "@s.whatsapp.net", "", true);
            }
        }

        Q_EMIT resultsAvailable(phoneList);

        qDebug() << "syncer: Synchronization finished";
        isSyncing = false;
        emit syncFinished();
    }
    else
    {
        qDebug() << "syncer: Synchronization failed";

        // Free everything
        freeAddressBook();
        isSyncing = false;
        emit syncFinished();
    }
}

void ContactSyncer::addParam(QString name, QString value)
{
    writeBuffer.append(QUrl::toPercentEncoding(name));
    writeBuffer.append('=');
    writeBuffer.append(QUrl::toPercentEncoding(value));
    writeBuffer.append('&');
}

bool ContactSyncer::isSynchronizing()
{
    return isSyncing;
}

void ContactSyncer::errorHandler(QAbstractSocket::SocketError error)
{
    // If all the synchronization data has been received ignore
    // the socket errors.  It looks like QSslSocket will still send
    // socket errors even if the socket has been closed.
    // Not sure if a bug or a feature but this way we avoid false positives
    if (!syncDataReceived)
    {
        if (error == QAbstractSocket::SslHandshakeFailedError)
        {
            // SSL error is a fatal error
            emit sslError();
        }
        else
        {
            // ToDo: Retry here
            qDebug() << "syncer: Socket error while trying to get synchronization data.  Error:" << QString::number(error);
            emit httpError((int)error);
        }
    }
}

void ContactSyncer::increaseUploadCounter(qint64 bytes)
{
    Client::dataCounters.increaseCounter(DataCounters::SyncBytes, 0, bytes);
}

void ContactSyncer::increaseDownloadCounter(qint64 bytes)
{
    Client::dataCounters.increaseCounter(DataCounters::SyncBytes, bytes, 0);
}
