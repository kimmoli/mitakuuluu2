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

#ifndef CONTACTSYNCER_H
#define CONTACTSYNCER_H

#include <QByteArray>
#include <QMap>
#include <QStringList>
#include <QContactManager>
#include <QContactFetchRequest>
#include <QContactDetailFilter>
#include <QContactName>
#include <QContactPhoneNumber>
#include <QContactAvatar>

#include "src/Whatsapp/httprequestv2.h"

using namespace QtContacts;

class ContactSyncer : public HttpRequestv2
{
    Q_OBJECT

public:
    ContactSyncer(QObject *parent = 0);

    bool isSynchronizing();

public slots:
    void sync();
    void syncContacts(const QStringList &jids);
    void syncContacts(const QStringList &numbers, const QStringList &names, const QStringList &avatars);
    void addContact(const QString &name, const QString &phone);
    void onResponse();
    void fillBuffer();
    void parseResponse();
    void authResponse();
    void errorHandler(QAbstractSocket::SocketError error);
    void increaseUploadCounter(qint64 bytes);
    void increaseDownloadCounter(qint64 bytes);

private:
    QVariantList phoneList;
    QStringList syncList;
    int totalPhones, nextSignal;
    bool isSyncing;
    bool syncDataReceived;

    QVariantMap _contacts;
    QVariantMap _avatars;

    QByteArray readBuffer;
    QByteArray writeBuffer;
    qint64 totalLength;

    QContactManager *contactManager;
    QContactFetchRequest *contactRequest;

    void syncAddressBook();

    QByteArray encode(QByteArray bytes);
    int encodeByte(int c);
    QString getAuthResponse(QString nonce);

    void freeAddressBook();
    void addParam(QString name, QString value);

signals:
    void statusChanged(QString jid, QString status);
    void photoRefresh(QString jid, QString expectedPhotoId, bool largeFormat);
    void syncFinished();
    void progress(int);
    void httpError(int);
    void sslError();
    void resultsAvailable(QVariantList results);
};

#endif // CONTACTSYNCER_H
