#pragma once

#include <QObject>
#include <QDate>
#include <QDir>
#include <QJsonObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

class ProfileManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString activeSection READ activeSection WRITE setActiveSection NOTIFY activeSectionChanged)
    Q_PROPERTY(QVariantMap currentProfile READ currentProfile NOTIFY currentProfileChanged)
    Q_PROPERTY(QVariantMap dashboard READ dashboard NOTIFY dashboardChanged)
    Q_PROPERTY(QVariantList healthChecks READ healthChecks NOTIFY healthChecksChanged)
    Q_PROPERTY(QVariantList profiles READ profiles NOTIFY profilesChanged)
    Q_PROPERTY(int selectedProfileIndex READ selectedProfileIndex NOTIFY selectedProfileIndexChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QVariantList tokenDailySeries READ tokenDailySeries NOTIFY tokenUsageChanged)
    Q_PROPERTY(QVariantList tokenSessions READ tokenSessions NOTIFY tokenUsageChanged)
    Q_PROPERTY(QVariantMap tokenSummary READ tokenSummary NOTIFY tokenUsageChanged)
    Q_PROPERTY(QVariantList tokenUsage READ tokenUsage NOTIFY tokenUsageChanged)

public:
    explicit ProfileManager(QObject *parent = nullptr);

    QString activeSection() const;
    void setActiveSection(const QString &section);

    QVariantMap currentProfile() const;
    QVariantMap dashboard() const;
    QVariantList healthChecks() const;
    QVariantList profiles() const;
    int selectedProfileIndex() const;
    QString statusMessage() const;
    QVariantList tokenDailySeries() const;
    QVariantList tokenSessions() const;
    QVariantMap tokenSummary() const;
    QVariantList tokenUsage() const;

    Q_INVOKABLE bool activateSelectedProfile();
    Q_INVOKABLE void createProfile();
    Q_INVOKABLE bool createProfileWithConfiguration(const QString &name,
                                                    const QString &agentType,
                                                    const QString &modelProvider,
                                                    const QString &model,
                                                    const QString &reasoningEffort,
                                                    const QString &baseUrl,
                                                    const QString &apiKey,
                                                    const QString &httpProxy,
                                                    const QString &httpsProxy,
                                                    bool disableResponseStorage,
                                                    const QString &wireApi,
                                                    bool requiresOpenAiAuth);
    Q_INVOKABLE void deleteSelectedProfile();
    Q_INVOKABLE void editSelectedProfile();
    Q_INVOKABLE void runHealthCheck();
    Q_INVOKABLE bool saveConfiguration(const QString &name,
                                       const QString &agentType,
                                       const QString &modelProvider,
                                       const QString &model,
                                       const QString &reasoningEffort,
                                       const QString &baseUrl,
                                       const QString &apiKey,
                                       const QString &httpProxy,
                                       const QString &httpsProxy,
                                       bool disableResponseStorage,
                                       const QString &wireApi,
                                       bool requiresOpenAiAuth);
    Q_INVOKABLE void selectProfile(int index);
    Q_INVOKABLE bool selectProfileByFolderName(const QString &folderName);
    Q_INVOKABLE bool setActiveProfileByFolderName(const QString &folderName);
    Q_INVOKABLE void selectSection(const QString &section);
    Q_INVOKABLE void shiftTokenDate(int days);
    Q_INVOKABLE void shiftTokenRangeStart(int days);
    Q_INVOKABLE void shiftTokenRangeEnd(int days);
    Q_INVOKABLE void setTokenDateRange(const QString &startDate, const QString &endDate);
    Q_INVOKABLE void setTokenRecentRange(int days);
    Q_INVOKABLE void refreshTokenUsage();

signals:
    void activeSectionChanged();
    void currentProfileChanged();
    void dashboardChanged();
    void healthChecksChanged();
    void profilesChanged();
    void selectedProfileIndexChanged();
    void statusMessageChanged();
    void tokenUsageChanged();

private:
    struct Profile
    {
        QString name;
        QString agentType;
        QString description;
        QString modelProvider;
        QString model;
        QString reasoningEffort;
        QString baseUrl;
        QString apiKey;
        QString httpProxy;
        QString httpsProxy;
        QString wireApi = QStringLiteral("responses");
        QString folderName;
        int todayTokens = 0;
        int monthlyLimit = 500000;
        bool active = false;
        bool disableResponseStorage = true;
        bool requiresOpenAiAuth = true;
    };

    struct HealthCheck
    {
        QString profileName;
        QString endpoint;
        QString status;
        int latencyMs = 0;
        QString checkedAt;
    };

    struct TokenTotals
    {
        qint64 inputTokens = 0;
        qint64 cachedInputTokens = 0;
        qint64 outputTokens = 0;
        qint64 reasoningOutputTokens = 0;
        qint64 totalTokens = 0;
    };

    struct TokenSession
    {
        QString id;
        QString fileName;
        QString filePath;
        QString cwd;
        QString originator;
        QString source;
        QString modelProvider;
        QString startedAt;
        QString lastUpdatedAt;
        QString limitId;
        QString planType;
        int turnCount = 0;
        qint64 contextWindow = 0;
        TokenTotals totals;
        QVector<qint64> hourlyTokens = QVector<qint64>(24);
    };

    struct TokenDay
    {
        QDate date;
        qint64 totalTokens = 0;
        int sessionCount = 0;
        int hour = -1;
    };

    QVariantMap healthCheckToMap(const HealthCheck &check) const;
    bool applySelectedProfileToCodex();
    void applyConfiguration(Profile &profile,
                            const QString &name,
                            const QString &agentType,
                            const QString &modelProvider,
                            const QString &model,
                            const QString &reasoningEffort,
                            const QString &baseUrl,
                            const QString &apiKey,
                            const QString &httpProxy,
                            const QString &httpsProxy,
                            bool disableResponseStorage,
                            const QString &wireApi,
                            bool requiresOpenAiAuth);
    bool copyFileReplacing(const QString &sourcePath, const QString &targetPath);
    bool ensureProfileRoot();
    QString fileError(const QString &action, const QString &path) const;
    QString profileFolderName(const QString &profileName) const;
    QDir profileRootDir() const;
    QDir codexSessionsRootDir() const;
    bool isValidProfileName(const QString &name) const;
    void loadProfilesFromDisk();
    QString maskedApiKey(const QString &apiKey) const;
    QVariantMap profileToMap(const Profile &profile, int index) const;
    bool readProfileFromDirectory(const QString &folderName, Profile *profile) const;
    void loadTodayTokenUsage();
    void loadTokenUsage();
    void normalizeTokenRange();
    QVector<TokenSession> readTokenSessionsForDate(const QDate &date,
                                                   TokenTotals *totals,
                                                   qint64 *contextWindow,
                                                   QString *lastUpdated) const;
    bool readTokenSessionFile(const QString &path, TokenSession *session) const;
    TokenTotals readTokenTotals(const QJsonObject &object) const;
    QVariantMap tokenDayToMap(const TokenDay &day) const;
    QVariantMap tokenSessionToMap(const TokenSession &session) const;
    QVariantMap tokenTotalsToMap(const TokenTotals &totals) const;
    Profile *selectedProfile();
    const Profile *selectedProfile() const;
    void emitDataChanged();
    void setStatusMessage(const QString &message);
    bool writeProfileToDisk(Profile *profile, const QString &previousFolderName = QString());

    QVector<Profile> m_profiles;
    QVector<HealthCheck> m_healthChecks;
    QVector<TokenDay> m_tokenDailySeries;
    QVector<TokenSession> m_tokenSessions;
    QDate m_tokenSelectedDate;
    QDate m_tokenRangeStartDate;
    QDate m_tokenRangeEndDate;
    TokenTotals m_tokenSelectedTotals;
    TokenTotals m_tokenTodayTotals;
    qint64 m_tokenSelectedContextWindow = 0;
    int m_tokenTodaySessionCount = 0;
    bool m_tokenUsageLoaded = false;
    QString m_tokenLastUpdated;
    QString m_tokenSessionsPath;
    QString m_activeSection;
    int m_selectedProfileIndex = -1;
    QString m_statusMessage;
};
