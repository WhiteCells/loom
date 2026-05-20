#pragma once

#include <QObject>
#include <QJsonObject>
#include <QTimer>
#include <QVariantMap>

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(QString density READ density WRITE setDensity NOTIFY densityChanged)
    Q_PROPERTY(int accentIndex READ accentIndex WRITE setAccentIndex NOTIFY accentIndexChanged)
    Q_PROPERTY(bool launchAtLogin READ launchAtLogin WRITE setLaunchAtLogin NOTIFY launchAtLoginChanged)
    Q_PROPERTY(bool restoreLastSection READ restoreLastSection WRITE setRestoreLastSection NOTIFY restoreLastSectionChanged)
    Q_PROPERTY(bool healthCheckOnActivate READ healthCheckOnActivate WRITE setHealthCheckOnActivate NOTIFY healthCheckOnActivateChanged)
    Q_PROPERTY(bool loomProxyEnabled READ loomProxyEnabled WRITE setLoomProxyEnabled NOTIFY loomProxyEnabledChanged)
    Q_PROPERTY(int loomProxyPort READ loomProxyPort WRITE setLoomProxyPort NOTIFY loomProxyPortChanged)
    Q_PROPERTY(QString loomProxyUrl READ loomProxyUrl NOTIFY loomProxyPortChanged)
    Q_PROPERTY(bool codexRoutesThroughLoom READ codexRoutesThroughLoom WRITE setCodexRoutesThroughLoom NOTIFY codexRoutesThroughLoomChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(bool confirmProfileDeletion READ confirmProfileDeletion CONSTANT)
    Q_PROPERTY(bool maskSecrets READ maskSecrets WRITE setMaskSecrets NOTIFY maskSecretsChanged)
    Q_PROPERTY(bool keepBackups READ keepBackups WRITE setKeepBackups NOTIFY keepBackupsChanged)
    Q_PROPERTY(QString backupRetention READ backupRetention WRITE setBackupRetention NOTIFY backupRetentionChanged)
    Q_PROPERTY(QString lastSection READ lastSection WRITE setLastSection NOTIFY lastSectionChanged)
    Q_PROPERTY(QString selectedProfileFolder READ selectedProfileFolder WRITE setSelectedProfileFolder NOTIFY selectedProfileFolderChanged)
    Q_PROPERTY(QString activeProfileFolder READ activeProfileFolder WRITE setActiveProfileFolder NOTIFY activeProfileFolderChanged)
    Q_PROPERTY(QVariantMap interfaceConfig READ interfaceConfig NOTIFY interfaceConfigChanged)
    Q_PROPERTY(QString dataLocation READ dataLocation CONSTANT)
    Q_PROPERTY(QString settingsPath READ settingsPath CONSTANT)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QVariantMap values READ values NOTIFY valuesChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);
    ~SettingsManager() override;

    bool darkTheme() const;
    void setDarkTheme(bool darkTheme);

    QString density() const;
    void setDensity(const QString &density);

    int accentIndex() const;
    void setAccentIndex(int accentIndex);

    bool launchAtLogin() const;
    void setLaunchAtLogin(bool launchAtLogin);

    bool restoreLastSection() const;
    void setRestoreLastSection(bool restoreLastSection);

    bool healthCheckOnActivate() const;
    void setHealthCheckOnActivate(bool healthCheckOnActivate);

    bool loomProxyEnabled() const;
    void setLoomProxyEnabled(bool loomProxyEnabled);

    int loomProxyPort() const;
    void setLoomProxyPort(int loomProxyPort);
    QString loomProxyUrl() const;

    bool codexRoutesThroughLoom() const;
    void setCodexRoutesThroughLoom(bool codexRoutesThroughLoom);

    QString language() const;
    void setLanguage(const QString &language);

    bool confirmProfileDeletion() const;

    bool maskSecrets() const;
    void setMaskSecrets(bool maskSecrets);

    bool keepBackups() const;
    void setKeepBackups(bool keepBackups);

    QString backupRetention() const;
    void setBackupRetention(const QString &backupRetention);

    QString lastSection() const;
    void setLastSection(const QString &lastSection);

    QString selectedProfileFolder() const;
    void setSelectedProfileFolder(const QString &selectedProfileFolder);

    QString activeProfileFolder() const;
    void setActiveProfileFolder(const QString &activeProfileFolder);

    QVariantMap interfaceConfig() const;

    QString dataLocation() const;
    QString settingsPath() const;
    QString statusMessage() const;
    QVariantMap values() const;

    Q_INVOKABLE bool reload();
    Q_INVOKABLE bool save();
    Q_INVOKABLE void saveInterfaceConfig(const QString &profileName,
                                         const QString &modelProvider,
                                         const QString &model,
                                         const QString &reasoningEffort,
                                         const QString &baseUrl,
                                         const QString &httpProxy,
                                         const QString &httpsProxy,
                                         bool disableResponseStorage,
                                         const QString &wireApi,
                                         bool requiresOpenAiAuth);

signals:
    void darkThemeChanged();
    void densityChanged();
    void accentIndexChanged();
    void launchAtLoginChanged();
    void restoreLastSectionChanged();
    void healthCheckOnActivateChanged();
    void loomProxyEnabledChanged();
    void loomProxyPortChanged();
    void codexRoutesThroughLoomChanged();
    void languageChanged();
    void maskSecretsChanged();
    void keepBackupsChanged();
    void backupRetentionChanged();
    void lastSectionChanged();
    void selectedProfileFolderChanged();
    void activeProfileFolderChanged();
    void interfaceConfigChanged();
    void statusMessageChanged();
    void valuesChanged();

private:
    bool ensureSettingsRoot();
    void emitAllChanged();
    bool loadFromDisk(bool announce);
    void persistAfterChange();
    void setStatusMessage(const QString &message);
    QJsonObject toJsonObject(bool includeUpdatedAt) const;
    bool writeSettingsToDisk(bool announce);

    bool m_darkTheme = true;
    QString m_density = QStringLiteral("Comfortable");
    int m_accentIndex = 0;
    bool m_launchAtLogin = false;
    bool m_restoreLastSection = true;
    bool m_healthCheckOnActivate = false;
    bool m_loomProxyEnabled = false;
    int m_loomProxyPort = 14567;
    bool m_codexRoutesThroughLoom = false;
    QString m_language = QStringLiteral("en");
    bool m_maskSecrets = true;
    bool m_keepBackups = true;
    QString m_backupRetention = QStringLiteral("14 days");
    QString m_lastSection = QStringLiteral("Dashboard");
    QString m_selectedProfileFolder;
    QString m_activeProfileFolder;
    QString m_interfaceProfileName;
    QString m_interfaceModelProvider = QStringLiteral("OpenAI");
    QString m_interfaceModel = QStringLiteral("gpt-5.5");
    QString m_interfaceReasoningEffort = QStringLiteral("high");
    QString m_interfaceBaseUrl = QStringLiteral("https://api.openai.com/v1");
    QString m_interfaceHttpProxy;
    QString m_interfaceHttpsProxy;
    QString m_interfaceWireApi = QStringLiteral("responses");
    bool m_interfaceDisableResponseStorage = true;
    bool m_interfaceRequiresOpenAiAuth = true;
    QString m_statusMessage;
    bool m_loading = false;
    QTimer m_persistTimer;
};
