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

#include <QUuid>

#include "phonereg.h"
#include "util/utilities.h"
#include "util/qtmd5digest.h"

#include <QTimer>
#include "../client.h"

PhoneReg::PhoneReg(const QString& cc, const QString& number, const QString& method,
                   const QString& smscode, const QString& password, QObject *parent) :
    QObject(parent)
{
    this->cc = cc;
    this->number = number;
    this->method = method;
    this->smscode = smscode;
    this->smscode = this->smscode.replace("-", "");

    // Generate a new id

    QtMD5Digest digest;
    digest.reset();

    if (password.isEmpty()) {
        digest.update(QUuid::createUuid().toByteArray());
    }
    else {
        digest.update(QString(number + "mitakuuluu" + password).toUtf8());
    }

    QByteArray bytes = digest.digest();

    this->id = QString::fromLatin1(bytes.toHex().constData()).left(20);
}

void PhoneReg::start()
{
    startCodeRequest();
}

void PhoneReg::startCodeRequest()
{
    qDebug() << QString("reg/req/%1/start").arg(method);
    request = new WARequest(this, "code");
    request->addParam("cc", cc);
    request->addParam("in", number);
    //request->addParam("reason","next-method");
    request->addParam("reason", "self-send-jailbroken");
    request->addParam("method", method);
    request->addParam("mcc", "000");
    request->addParam("mnc", "000");
    request->addParam("lg", "en");
    request->addParam("lc", "US");
    request->addParam("token", Utilities::getTokenAndroid(number));
    request->addParam("id",id);

    connect(request,SIGNAL(finished(QVariantMap)),
            this,SLOT(onCodeRequestDone(QVariantMap)));
    connect(request,SIGNAL(sslError()),
            this,SLOT(sslError()));
    connect(request,SIGNAL(httpError(int)),
            this,SLOT(errorHandler(int)));
    request->getRequest();
}

void PhoneReg::onCodeRequestDone(const QVariantMap &result)
{
    if (!result.contains("status"))
    {
        emit codeFailed(result);
    }
    else {
        if (result["status"].toString() == "sent") {
            emit codeRequested(result);
            listener = new SMSListener(this);
            QObject::connect(listener,SIGNAL(codeReceived(QString)),
                    this,SLOT(onSMSReceived(QString)));
        }
        else {
            if (result["status"].toString() == "ok") {
                emit finished(result);
            }
            else {
                emit codeFailed(result);
            }
        }
    }
}

void PhoneReg::onSMSReceived(const QString &code)
{
    smscode = code;
    startRegRequest();
}

void PhoneReg::startRegRequest()
{
    qDebug() << "reg/req/register/start";
    request = new WARequest(this, "register");
    request->addParam("cc", cc);
    request->addParam("in", number);
    request->addParam("id", id);
    request->addParam("code", smscode);

    connect(request,SIGNAL(finished(QVariantMap)),
            this,SLOT(onRegRequestDone(QVariantMap)));
    connect(request,SIGNAL(sslError()),
            this,SLOT(sslError()));
    connect(request,SIGNAL(httpError(int)),
            this,SLOT(errorHandler(int)));
    request->getRequest();
}

void PhoneReg::onRegRequestDone(const QVariantMap &result)
{
    qDebug() << "register reply:" << result;

    emit finished(result);
}

void PhoneReg::errorHandler(int code)
{
    QVariantMap result;

    result.insert("reason","http_error_" + QString::number(code));
    emit finished(result);
}

void PhoneReg::sslError()
{
    QVariantMap result;

    result.insert("reason","ssl_error");
    emit finished(result);
}
