#ifndef MITAKUULUU_H
#define MITAKUULUU_H

#include <QObject>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QStringList>
#include <QtDBus/QtDBus>
#include <QTimer>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>

#include <libexif/exif-loader.h>
#include <libexif/exif-entry.h>
#include <libexif/exif-data.h>

class Mitakuuluu: public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "harbour.mitakuuluu2.client")
    Q_ENUMS(ConnectionStatus)
    Q_ENUMS(MessageType)
    Q_ENUMS(MessageStatus)
    Q_ENUMS(ContactType)
    Q_PROPERTY(int connectionStatus READ connectionStatus NOTIFY connectionStatusChanged)
    Q_PROPERTY(QString connectionString READ connectionString NOTIFY connectionStringChanged)
    Q_PROPERTY(QString mcc READ mcc NOTIFY mccChanged)
    Q_PROPERTY(QString mnc READ mnc NOTIFY mncChanged)
    Q_PROPERTY(int totalUnread READ totalUnread NOTIFY totalUnreadChanged)
    Q_PROPERTY(QString myJid READ myJid NOTIFY myJidChanged)

public:
    enum ConnectionStatus {
        Unknown,
        WaitingForConnection,
        Connecting,
        Connected,
        LoggedIn,
        LoginFailure,
        Disconnected,
        Registering,
        RegistrationFailed,
        AccountExpired
    };

    enum MessageType {
        Text,
        Image,
        Audio,
        Video,
        Contact,
        Location,
        Divider,
        System,
        Voice
    };

    enum MessageStatus {
        Unsent = 0,
        Uploading,
        Uploaded,
        SentByClient,
        ReceivedByServer,
        ReceivedByTarget,
        NeverSent,
        ServerBounce,
        Played,
        Notification
    };

    enum ContactType {
        UnknownContact = 0,
        KnownContact
    };

    Mitakuuluu(QObject *parent = 0);
    ~Mitakuuluu();

private:
    int connStatus;
    int connectionStatus();

    int _totalUnread;
    int totalUnread();

    QString _myJid;
    QString myJid();

    QHash<QString, int> _unreadCount;

    QString connString;
    QString connectionString();

    QString mcc();
    QString _mcc;
    QString mnc();
    QString _mnc;

    QNetworkAccessManager *nam;
    QString _pendingJid;

    QDBusInterface *iface;

    QTranslator *translator;

    QTimer *pingServer;

    QString _pendingGroup;
    QString _pendingAvatar;
    QStringList _pendingParticipants;

    QStringList _locales;
    QStringList _localesNames;
    QString _currentLocale;

signals:
    void connectionStatusChanged();
    void connectionStringChanged();
    void mccChanged();
    void mncChanged();
    void myJidChanged();

    void activeChanged();
    void messageReceived(const QVariantMap &data);
    void disconnected(const QString &reason);
    void authFail(const QString &username, const QString &reason);
    void authSuccess(const QString &username);
    void networkChanged(bool value);
    void noAccountData();
    void registered();
    void smsTimeout(int timeout);
    void registrationFailed(const QVariantMap &reason);
    void registrationComplete();
    void accountExpired(const QVariantMap &reason);
    void gotAccountData(const QString &username, const QString &password);
    void codeRequested(const QVariantMap &method);
    void existsRequestFailed(const QVariantMap &serverReply);
    void codeRequestFailed(const QVariantMap &serverReply);
    void messageStatusUpdated(const QString &mjid, const QString &msgId, int msgstatus);
    void pictureUpdated(const QString &pjid, const QString &path);
    void contactsChanged();
    void contactChanged(const QVariantMap &data);
    void contactSynced(const QVariantMap &data);
    void newGroupSubject(const QVariantMap &data);
    void notificationOpenJid(const QString &njid);
    void setUnread(const QString &jid, int count);
    void pushnameUpdated(const QString &mjid, const QString &pushName);
    void presenceAvailable(const QString &mjid);
    void presenceUnavailable(const QString &mjid);
    void presenceLastSeen(const QString &mjid, int seconds);
    void mediaDownloadProgress(const QString &mjid, const QString &msgId, int progress);
    void mediaDownloadFinished(const QString &mjid, const QString &msgId, const QString &path);
    void mediaDownloadFailed(const QString &mjid, const QString &msgId);
    void groupParticipant(const QString &gjid, const QString &pjid);
    void groupInfo(const QVariantMap &group);
    void participantAdded(const QString &gjid, const QString &pjid);
    void participantRemoved(const QString &gjid, const QString &pjid);
    void contactsBlocked(const QStringList &list);
    void activeJidChanged(const QString &ajid);
    void contactTyping(const QString &cjid);
    void contactPaused(const QString &cjid);
    void synchronizationFinished();
    void synchronizationFailed();
    void phonebookReceived(const QVariantList &contactsmodel);
    void uploadMediaFailed(const QString &mjid, const QString &msgId);
    void groupsMuted(const QStringList &jids);
    void codeReceived();
    void dissectError();

    void replyCrashed(bool isCrashed);
    void myAccount(const QString &account);

    void logfileReady(const QByteArray &data, bool isReady);

    void totalUnreadChanged();

private slots:
    void onConnectionStatusChanged(int status);
    void onSimParameters(const QString &mcccode, const QString &mnccode);
    void onSetUnread(const QString &jid, int count);
    void onMyAccount(const QString &jid);

    void onReplyCrashed(QDBusPendingCallWatcher *call);

    void doPingServer();
    void onServerPong();

    void groupCreated(const QString &gjid);
    void onContactChanged(const QVariantMap &data);

public slots:
    Q_SCRIPTABLE void exit();
    Q_SCRIPTABLE void notificationCallback(const QString &jid);

    void authenticate();
    void init();
    void disconnect();
    void sendMessage(const QString &jid, const QString &message, const QString &media, const QString &mediaData);
    void sendBroadcast(const QStringList &jids, const QString &message);
    void sendText(const QString &jid, const QString &message);
    void syncContactList();
    void setActiveJid(const QString &jid);
    QString shouldOpenJid();
    void startTyping(const QString &jid);
    void endTyping(const QString &jid);
    void downloadMedia(const QString &msgId, const QString &jid);
    void cancelDownload(const QString &msgId, const QString &jid);
    void abortMediaDownload(const QString &msgId, const QString &jid);
    QString openVCardData(const QString &name, const QString &data);
    void getParticipants(const QString &jid);
    void getGroupInfo(const QString &jid);
    void regRequest(const QString &cc, const QString &phone, const QString &method, const QString &password);
    void enterCode(const QString &cc, const QString &phone, const QString &code);
    void setGroupSubject(const QString &gjid, const QString &subject);
    void createGroup(const QString &subject, const QString &picture, const QStringList &participants);
    void groupLeave(const QString &gjid);
    void setPicture(const QString &jid, const QString &path);
    void removeParticipant(const QString &gjid, const QString &jid);
    void addParticipant(const QString &gjid, const QString &jid);
    void addParticipants(const QString &gjid, const QStringList &jids);
    void refreshContact(const QString &jid);
    QString transformPicture(const QString &filename, const QString &jid, int posX, int posY, int sizeW, int sizeH, int maxSize, int rotation);
    void copyToClipboard(const QString &text);
    void blockOrUnblockContact(const QString &jid);
    void sendBlockedJids(const QStringList &jids);
    void muteOrUnmuteGroup(const QString &jid);
    void muteGroups(const QStringList &jids);
    void getPrivacyList();
    void getMutedGroups();
    void forwardMessage(const QStringList &jids, const QString &jid, const QString &msgid);
    void setMyPushname(const QString &pushname);
    void setMyPresence(const QString &presence);
    void sendRecentLogs();
    void shutdown();
    void isCrashed();
    void requestLastOnline(const QString &jid);
    void addPhoneNumber(const QString &name, const QString &phone);
    void sendMedia(const QStringList &jids, const QString &path);
    void sendVCard(const QStringList &jids, const QString &name, const QString& data);
    QString rotateImage(const QString &path, int rotation);
    QString saveVoice(const QString &path);
    QString saveImage(const QString &path);
    void openProfile(const QString &name, const QString &phone, const QString avatar = QString());
    void removeAccount();
    void syncContacts(const QStringList &numbers, const QStringList &names, const QStringList &avatars);
    void setPresenceAvailable();
    void setPresenceUnavailable();
    void syncAllPhonebook();
    void removeAccountFromServer();
    void forceConnection();
    void setLocale(const QString &localeName);
    void setLocale(int  index);
    int getExifRotation(const QString &image);
    void windowActive();
    bool checkLogfile();
    bool checkAutostart();
    void setAutostart(bool enabled);
    void sendLocation(const QStringList &jids, const QString &latitude, const QString &longitude, int zoom, bool googlemaps = false);
    void renewAccount(const QString &method, int years);
    QString checkIfExists(const QString &path);
    void unsubscribe(const QString &jid);
    QString getAvatarForJid(const QString &jid);
    void rejectMediaCapture(const QString &path);

    QStringList getLocalesNames();
    int getCurrentLocaleIndex();

//Settings

private:
    QSettings *settings;

public slots:
    Q_INVOKABLE void save(const QString &key, const QVariant &value);
    Q_INVOKABLE QVariant load(const QString &key, const QVariant &defaultValue = QVariant());
    Q_INVOKABLE QVariantList loadGroup(const QString &name);
    Q_INVOKABLE void clearGroup(const QString &name);
};

#endif // MITAKUULUU_H
