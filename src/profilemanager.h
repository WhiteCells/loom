#pragma once

#include <QObject>
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
    QVariantList tokenUsage() const;

    Q_INVOKABLE void activateSelectedProfile();
    Q_INVOKABLE void createProfile();
    Q_INVOKABLE void deleteSelectedProfile();
    Q_INVOKABLE void editSelectedProfile();
    Q_INVOKABLE void runHealthCheck();
    Q_INVOKABLE void saveConfiguration(const QString &name,
                                       const QString &agentType,
                                       const QString &modelProvider,
                                       const QString &model,
                                       const QString &reasoningEffort,
                                       const QString &baseUrl,
                                       const QString &apiKey,
                                       const QString &httpProxy,
                                       const QString &httpsProxy);
    Q_INVOKABLE void selectProfile(int index);
    Q_INVOKABLE void selectSection(const QString &section);

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
        int todayTokens = 0;
        int monthlyLimit = 500000;
        bool active = false;
    };

    struct HealthCheck
    {
        QString profileName;
        QString endpoint;
        QString status;
        int latencyMs = 0;
        QString checkedAt;
    };

    QVariantMap healthCheckToMap(const HealthCheck &check) const;
    QString maskedApiKey(const QString &apiKey) const;
    QVariantMap profileToMap(const Profile &profile, int index) const;
    Profile *selectedProfile();
    const Profile *selectedProfile() const;
    void emitDataChanged();
    void setStatusMessage(const QString &message);

    QVector<Profile> m_profiles;
    QVector<HealthCheck> m_healthChecks;
    QString m_activeSection;
    int m_selectedProfileIndex = 0;
    QString m_statusMessage;
};
