#include "settingsmanager.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QSaveFile>

#include <algorithm>

namespace {
constexpr int kSettingsVersion = 1;

QStringList densities()
{
    return {QStringLiteral("Comfortable"), QStringLiteral("Compact")};
}

QStringList backupRetentions()
{
    return {QStringLiteral("7 days"), QStringLiteral("14 days"), QStringLiteral("30 days")};
}

QStringList wireApis()
{
    return {QStringLiteral("responses"), QStringLiteral("chat")};
}

QStringList sections()
{
    return {QStringLiteral("Dashboard"),
            QStringLiteral("Profiles"),
            QStringLiteral("Health Checks"),
            QStringLiteral("Token Usage"),
            QStringLiteral("Settings")};
}

QStringList languages()
{
    return {QStringLiteral("en"), QStringLiteral("zh")};
}

QString validatedChoice(const QString &value, const QStringList &choices, const QString &fallback)
{
    return choices.contains(value) ? value : fallback;
}

QString nonEmptyString(QString value, const QString &fallback)
{
    value = value.trimmed();
    return value.isEmpty() ? fallback : value;
}

int boundedAccentIndex(int value)
{
    return std::clamp(value, 0, 5);
}

int boundedPort(int value)
{
    return std::clamp(value, 1024, 65535);
}

bool jsonBool(const QJsonObject &object, const QString &key, bool fallback)
{
    const QJsonValue value = object.value(key);
    return value.isBool() ? value.toBool() : fallback;
}

int jsonInt(const QJsonObject &object, const QString &key, int fallback)
{
    const QJsonValue value = object.value(key);
    return value.isDouble() ? value.toInt() : fallback;
}

QString jsonString(const QJsonObject &object, const QString &key, const QString &fallback)
{
    const QJsonValue value = object.value(key);
    return value.isString() ? value.toString() : fallback;
}
} // namespace

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
{
    m_persistTimer.setSingleShot(true);
    m_persistTimer.setInterval(250);
    connect(&m_persistTimer, &QTimer::timeout, this, [this] {
        writeSettingsToDisk(false);
    });

    loadFromDisk(false);
}

SettingsManager::~SettingsManager()
{
    if (m_persistTimer.isActive()) {
        m_persistTimer.stop();
        writeSettingsToDisk(false);
    }
}

bool SettingsManager::darkTheme() const
{
    return m_darkTheme;
}

void SettingsManager::setDarkTheme(bool darkTheme)
{
    if (m_darkTheme == darkTheme) {
        return;
    }

    m_darkTheme = darkTheme;
    emit darkThemeChanged();
    emit valuesChanged();
    persistAfterChange();
}

QString SettingsManager::density() const
{
    return m_density;
}

void SettingsManager::setDensity(const QString &density)
{
    const QString nextDensity = validatedChoice(density.trimmed(), densities(), QStringLiteral("Comfortable"));
    if (m_density == nextDensity) {
        return;
    }

    m_density = nextDensity;
    emit densityChanged();
    emit valuesChanged();
    persistAfterChange();
}

int SettingsManager::accentIndex() const
{
    return m_accentIndex;
}

void SettingsManager::setAccentIndex(int accentIndex)
{
    const int nextAccentIndex = boundedAccentIndex(accentIndex);
    if (m_accentIndex == nextAccentIndex) {
        return;
    }

    m_accentIndex = nextAccentIndex;
    emit accentIndexChanged();
    emit valuesChanged();
    persistAfterChange();
}

bool SettingsManager::launchAtLogin() const
{
    return m_launchAtLogin;
}

void SettingsManager::setLaunchAtLogin(bool launchAtLogin)
{
    if (m_launchAtLogin == launchAtLogin) {
        return;
    }

    m_launchAtLogin = launchAtLogin;
    emit launchAtLoginChanged();
    emit valuesChanged();
    persistAfterChange();
}

bool SettingsManager::restoreLastSection() const
{
    return m_restoreLastSection;
}

void SettingsManager::setRestoreLastSection(bool restoreLastSection)
{
    if (m_restoreLastSection == restoreLastSection) {
        return;
    }

    m_restoreLastSection = restoreLastSection;
    emit restoreLastSectionChanged();
    emit valuesChanged();
    persistAfterChange();
}

bool SettingsManager::healthCheckOnActivate() const
{
    return m_healthCheckOnActivate;
}

void SettingsManager::setHealthCheckOnActivate(bool healthCheckOnActivate)
{
    if (m_healthCheckOnActivate == healthCheckOnActivate) {
        return;
    }

    m_healthCheckOnActivate = healthCheckOnActivate;
    emit healthCheckOnActivateChanged();
    emit valuesChanged();
    persistAfterChange();
}

bool SettingsManager::loomProxyEnabled() const
{
    return m_loomProxyEnabled;
}

void SettingsManager::setLoomProxyEnabled(bool loomProxyEnabled)
{
    const bool proxyChanged = m_loomProxyEnabled != loomProxyEnabled;
    const bool routesChanged = m_codexRoutesThroughLoom != loomProxyEnabled;
    if (!proxyChanged && !routesChanged) {
        return;
    }

    m_loomProxyEnabled = loomProxyEnabled;
    m_codexRoutesThroughLoom = loomProxyEnabled;
    if (proxyChanged) {
        emit loomProxyEnabledChanged();
    }
    if (routesChanged) {
        emit codexRoutesThroughLoomChanged();
    }
    emit valuesChanged();
    persistAfterChange();
}

int SettingsManager::loomProxyPort() const
{
    return m_loomProxyPort;
}

void SettingsManager::setLoomProxyPort(int loomProxyPort)
{
    const int nextPort = boundedPort(loomProxyPort);
    if (m_loomProxyPort == nextPort) {
        return;
    }

    m_loomProxyPort = nextPort;
    emit loomProxyPortChanged();
    emit valuesChanged();
    persistAfterChange();
}

QString SettingsManager::loomProxyUrl() const
{
    return QStringLiteral("http://127.0.0.1:%1/v1").arg(m_loomProxyPort);
}

bool SettingsManager::codexRoutesThroughLoom() const
{
    return m_codexRoutesThroughLoom;
}

void SettingsManager::setCodexRoutesThroughLoom(bool codexRoutesThroughLoom)
{
    setLoomProxyEnabled(codexRoutesThroughLoom);
}

QString SettingsManager::language() const
{
    return m_language;
}

void SettingsManager::setLanguage(const QString &language)
{
    const QString nextLanguage = validatedChoice(language.trimmed(), languages(), QStringLiteral("en"));
    if (m_language == nextLanguage) {
        return;
    }

    m_language = nextLanguage;
    emit languageChanged();
    emit valuesChanged();
    persistAfterChange();
}

bool SettingsManager::confirmProfileDeletion() const
{
    return true;
}

bool SettingsManager::maskSecrets() const
{
    return m_maskSecrets;
}

void SettingsManager::setMaskSecrets(bool maskSecrets)
{
    if (m_maskSecrets == maskSecrets) {
        return;
    }

    m_maskSecrets = maskSecrets;
    emit maskSecretsChanged();
    emit valuesChanged();
    persistAfterChange();
}

bool SettingsManager::keepBackups() const
{
    return m_keepBackups;
}

void SettingsManager::setKeepBackups(bool keepBackups)
{
    if (m_keepBackups == keepBackups) {
        return;
    }

    m_keepBackups = keepBackups;
    emit keepBackupsChanged();
    emit valuesChanged();
    persistAfterChange();
}

QString SettingsManager::backupRetention() const
{
    return m_backupRetention;
}

void SettingsManager::setBackupRetention(const QString &backupRetention)
{
    const QString nextRetention = validatedChoice(backupRetention.trimmed(), backupRetentions(), QStringLiteral("14 days"));
    if (m_backupRetention == nextRetention) {
        return;
    }

    m_backupRetention = nextRetention;
    emit backupRetentionChanged();
    emit valuesChanged();
    persistAfterChange();
}

QString SettingsManager::lastSection() const
{
    return m_lastSection;
}

void SettingsManager::setLastSection(const QString &lastSection)
{
    const QString nextSection = validatedChoice(lastSection.trimmed(), sections(), QStringLiteral("Dashboard"));
    if (m_lastSection == nextSection) {
        return;
    }

    m_lastSection = nextSection;
    emit lastSectionChanged();
    emit valuesChanged();
    persistAfterChange();
}

QString SettingsManager::selectedProfileFolder() const
{
    return m_selectedProfileFolder;
}

void SettingsManager::setSelectedProfileFolder(const QString &selectedProfileFolder)
{
    const QString nextFolder = selectedProfileFolder.trimmed();
    if (m_selectedProfileFolder == nextFolder) {
        return;
    }

    m_selectedProfileFolder = nextFolder;
    emit selectedProfileFolderChanged();
    emit valuesChanged();
    persistAfterChange();
}

QString SettingsManager::activeProfileFolder() const
{
    return m_activeProfileFolder;
}

void SettingsManager::setActiveProfileFolder(const QString &activeProfileFolder)
{
    const QString nextFolder = activeProfileFolder.trimmed();
    if (m_activeProfileFolder == nextFolder) {
        return;
    }

    m_activeProfileFolder = nextFolder;
    emit activeProfileFolderChanged();
    emit valuesChanged();
    persistAfterChange();
}

QVariantMap SettingsManager::interfaceConfig() const
{
    QVariantMap config;
    config.insert(QStringLiteral("profileName"), m_interfaceProfileName);
    config.insert(QStringLiteral("modelProvider"), m_interfaceModelProvider);
    config.insert(QStringLiteral("model"), m_interfaceModel);
    config.insert(QStringLiteral("reasoningEffort"), m_interfaceReasoningEffort);
    config.insert(QStringLiteral("baseUrl"), m_interfaceBaseUrl);
    config.insert(QStringLiteral("httpProxy"), m_interfaceHttpProxy);
    config.insert(QStringLiteral("httpsProxy"), m_interfaceHttpsProxy);
    config.insert(QStringLiteral("disableResponseStorage"), m_interfaceDisableResponseStorage);
    config.insert(QStringLiteral("wireApi"), m_interfaceWireApi);
    config.insert(QStringLiteral("requiresOpenAiAuth"), m_interfaceRequiresOpenAiAuth);
    return config;
}

QString SettingsManager::dataLocation() const
{
    return QDir::current().filePath(QStringLiteral("loomprofile"));
}

QString SettingsManager::settingsPath() const
{
    return QDir(dataLocation()).filePath(QStringLiteral("setting.json"));
}

QString SettingsManager::statusMessage() const
{
    return m_statusMessage;
}

QVariantMap SettingsManager::values() const
{
    return toJsonObject(false).toVariantMap();
}

bool SettingsManager::reload()
{
    return loadFromDisk(true);
}

bool SettingsManager::save()
{
    return writeSettingsToDisk(true);
}

void SettingsManager::saveInterfaceConfig(const QString &profileName,
                                          const QString &modelProvider,
                                          const QString &model,
                                          const QString &reasoningEffort,
                                          const QString &baseUrl,
                                          const QString &httpProxy,
                                          const QString &httpsProxy,
                                          bool disableResponseStorage,
                                          const QString &wireApi,
                                          bool requiresOpenAiAuth)
{
    const QString nextProfileName = profileName.trimmed();
    const QString nextProvider = nonEmptyString(modelProvider, QStringLiteral("OpenAI"));
    const QString nextModel = nonEmptyString(model, QStringLiteral("gpt-5.5"));
    const QString nextEffort = validatedChoice(reasoningEffort.trimmed(), {QStringLiteral("low"), QStringLiteral("medium"), QStringLiteral("high"), QStringLiteral("xhigh")},
                                               QStringLiteral("high"));
    const QString nextBaseUrl = baseUrl.trimmed();
    const QString nextHttpProxy = httpProxy.trimmed();
    const QString nextHttpsProxy = httpsProxy.trimmed();
    const QString nextWireApi = validatedChoice(wireApi.trimmed(), wireApis(), QStringLiteral("responses"));

    bool changed = false;
    const auto assignString = [&changed](QString &target, const QString &value) {
        if (target != value) {
            target = value;
            changed = true;
        }
    };
    const auto assignBool = [&changed](bool &target, bool value) {
        if (target != value) {
            target = value;
            changed = true;
        }
    };

    assignString(m_interfaceProfileName, nextProfileName);
    assignString(m_interfaceModelProvider, nextProvider);
    assignString(m_interfaceModel, nextModel);
    assignString(m_interfaceReasoningEffort, nextEffort);
    assignString(m_interfaceBaseUrl, nextBaseUrl);
    assignString(m_interfaceHttpProxy, nextHttpProxy);
    assignString(m_interfaceHttpsProxy, nextHttpsProxy);
    assignString(m_interfaceWireApi, nextWireApi);
    assignBool(m_interfaceDisableResponseStorage, disableResponseStorage);
    assignBool(m_interfaceRequiresOpenAiAuth, requiresOpenAiAuth);

    if (!changed) {
        return;
    }

    emit interfaceConfigChanged();
    emit valuesChanged();
    persistAfterChange();
}

bool SettingsManager::ensureSettingsRoot()
{
    QDir root(dataLocation());
    if (root.exists()) {
        return true;
    }

    if (!QDir().mkpath(root.path())) {
        setStatusMessage(QStringLiteral("Failed to create %1").arg(root.path()));
        return false;
    }
    return true;
}

void SettingsManager::emitAllChanged()
{
    emit darkThemeChanged();
    emit densityChanged();
    emit accentIndexChanged();
    emit launchAtLoginChanged();
    emit restoreLastSectionChanged();
    emit healthCheckOnActivateChanged();
    emit loomProxyEnabledChanged();
    emit loomProxyPortChanged();
    emit codexRoutesThroughLoomChanged();
    emit languageChanged();
    emit maskSecretsChanged();
    emit keepBackupsChanged();
    emit backupRetentionChanged();
    emit lastSectionChanged();
    emit selectedProfileFolderChanged();
    emit activeProfileFolderChanged();
    emit interfaceConfigChanged();
    emit valuesChanged();
}

bool SettingsManager::loadFromDisk(bool announce)
{
    m_loading = true;

    if (!ensureSettingsRoot()) {
        m_loading = false;
        return false;
    }

    QFile file(settingsPath());
    if (!file.exists()) {
        m_loading = false;
        const bool saved = writeSettingsToDisk(false);
        if (announce && saved) {
            setStatusMessage(QStringLiteral("Settings initialized at %1").arg(settingsPath()));
        }
        return saved;
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_loading = false;
        setStatusMessage(QStringLiteral("Failed to read %1").arg(settingsPath()));
        return false;
    }

    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        m_loading = false;
        setStatusMessage(QStringLiteral("Invalid setting.json, defaults restored"));
        return writeSettingsToDisk(false);
    }

    const QJsonObject root = document.object();
    const QJsonObject appearance = root.value(QStringLiteral("appearance")).toObject();
    const QJsonObject behavior = root.value(QStringLiteral("behavior")).toObject();
    const QJsonObject profiles = root.value(QStringLiteral("profiles")).toObject();
    const QJsonObject interfaceConfig = root.value(QStringLiteral("interfaceConfig")).toObject();
    const QJsonObject storage = root.value(QStringLiteral("storage")).toObject();

    const QString theme = jsonString(appearance, QStringLiteral("theme"), m_darkTheme ? QStringLiteral("Dark") : QStringLiteral("Light"));
    m_darkTheme = theme.compare(QStringLiteral("Light"), Qt::CaseInsensitive) != 0;
    m_density = validatedChoice(jsonString(appearance, QStringLiteral("density"), m_density), densities(), QStringLiteral("Comfortable"));
    m_accentIndex = boundedAccentIndex(jsonInt(appearance, QStringLiteral("accentIndex"), m_accentIndex));
    m_language = validatedChoice(jsonString(appearance, QStringLiteral("language"), m_language).trimmed(), languages(), QStringLiteral("en"));

    m_launchAtLogin = jsonBool(behavior, QStringLiteral("launchAtLogin"), m_launchAtLogin);
    m_restoreLastSection = jsonBool(behavior, QStringLiteral("restoreLastSection"), m_restoreLastSection);
    m_healthCheckOnActivate = jsonBool(behavior, QStringLiteral("healthCheckOnActivate"), m_healthCheckOnActivate);
    const QJsonObject proxy = root.value(QStringLiteral("proxy")).toObject();
    m_loomProxyEnabled = jsonBool(proxy, QStringLiteral("enabled"), m_loomProxyEnabled);
    m_loomProxyPort = boundedPort(jsonInt(proxy, QStringLiteral("port"), m_loomProxyPort));
    m_codexRoutesThroughLoom = m_loomProxyEnabled;
    m_lastSection = validatedChoice(jsonString(behavior, QStringLiteral("lastSection"), m_lastSection), sections(), QStringLiteral("Dashboard"));

    m_selectedProfileFolder = jsonString(profiles, QStringLiteral("selectedProfileFolder"), m_selectedProfileFolder).trimmed();
    m_activeProfileFolder = jsonString(profiles, QStringLiteral("activeProfileFolder"), m_activeProfileFolder).trimmed();

    m_interfaceProfileName = jsonString(interfaceConfig, QStringLiteral("profileName"), m_interfaceProfileName).trimmed();
    m_interfaceModelProvider = nonEmptyString(jsonString(interfaceConfig, QStringLiteral("modelProvider"), m_interfaceModelProvider), QStringLiteral("OpenAI"));
    m_interfaceModel = nonEmptyString(jsonString(interfaceConfig, QStringLiteral("model"), m_interfaceModel), QStringLiteral("gpt-5.5"));
    m_interfaceReasoningEffort = validatedChoice(jsonString(interfaceConfig, QStringLiteral("reasoningEffort"), m_interfaceReasoningEffort).trimmed(),
                                                 {QStringLiteral("low"), QStringLiteral("medium"), QStringLiteral("high"), QStringLiteral("xhigh")},
                                                 QStringLiteral("high"));
    m_interfaceBaseUrl = jsonString(interfaceConfig, QStringLiteral("baseUrl"), m_interfaceBaseUrl).trimmed();
    m_interfaceHttpProxy = jsonString(interfaceConfig, QStringLiteral("httpProxy"), m_interfaceHttpProxy).trimmed();
    m_interfaceHttpsProxy = jsonString(interfaceConfig, QStringLiteral("httpsProxy"), m_interfaceHttpsProxy).trimmed();
    m_interfaceDisableResponseStorage = jsonBool(interfaceConfig, QStringLiteral("disableResponseStorage"), m_interfaceDisableResponseStorage);
    m_interfaceWireApi = validatedChoice(jsonString(interfaceConfig, QStringLiteral("wireApi"), m_interfaceWireApi).trimmed(), wireApis(), QStringLiteral("responses"));
    m_interfaceRequiresOpenAiAuth = jsonBool(interfaceConfig, QStringLiteral("requiresOpenAiAuth"), m_interfaceRequiresOpenAiAuth);

    m_maskSecrets = jsonBool(storage, QStringLiteral("maskSecrets"), m_maskSecrets);
    m_keepBackups = jsonBool(storage, QStringLiteral("keepBackups"), m_keepBackups);
    m_backupRetention = validatedChoice(jsonString(storage, QStringLiteral("backupRetention"), m_backupRetention), backupRetentions(), QStringLiteral("14 days"));

    m_loading = false;
    emitAllChanged();

    if (announce) {
        setStatusMessage(QStringLiteral("Settings loaded from %1").arg(settingsPath()));
    } else {
        setStatusMessage(QStringLiteral("Settings are local"));
    }
    return true;
}

void SettingsManager::persistAfterChange()
{
    if (!m_loading) {
        m_persistTimer.start();
    }
}

void SettingsManager::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message) {
        return;
    }

    m_statusMessage = message;
    emit statusMessageChanged();
}

QJsonObject SettingsManager::toJsonObject(bool includeUpdatedAt) const
{
    QJsonObject appearance;
    appearance.insert(QStringLiteral("theme"), m_darkTheme ? QStringLiteral("Dark") : QStringLiteral("Light"));
    appearance.insert(QStringLiteral("density"), m_density);
    appearance.insert(QStringLiteral("accentIndex"), m_accentIndex);
    appearance.insert(QStringLiteral("language"), m_language);

    QJsonObject behavior;
    behavior.insert(QStringLiteral("launchAtLogin"), m_launchAtLogin);
    behavior.insert(QStringLiteral("restoreLastSection"), m_restoreLastSection);
    behavior.insert(QStringLiteral("healthCheckOnActivate"), m_healthCheckOnActivate);
    behavior.insert(QStringLiteral("confirmProfileDeletion"), confirmProfileDeletion());
    behavior.insert(QStringLiteral("lastSection"), m_lastSection);

    QJsonObject proxy;
    proxy.insert(QStringLiteral("enabled"), m_loomProxyEnabled);
    proxy.insert(QStringLiteral("port"), m_loomProxyPort);
    proxy.insert(QStringLiteral("url"), loomProxyUrl());
    proxy.insert(QStringLiteral("codexRoutesThroughLoom"), m_codexRoutesThroughLoom);

    QJsonObject profiles;
    profiles.insert(QStringLiteral("selectedProfileFolder"), m_selectedProfileFolder);
    profiles.insert(QStringLiteral("activeProfileFolder"), m_activeProfileFolder);

    QJsonObject interfaceConfig;
    interfaceConfig.insert(QStringLiteral("profileName"), m_interfaceProfileName);
    interfaceConfig.insert(QStringLiteral("modelProvider"), m_interfaceModelProvider);
    interfaceConfig.insert(QStringLiteral("model"), m_interfaceModel);
    interfaceConfig.insert(QStringLiteral("reasoningEffort"), m_interfaceReasoningEffort);
    interfaceConfig.insert(QStringLiteral("baseUrl"), m_interfaceBaseUrl);
    interfaceConfig.insert(QStringLiteral("httpProxy"), m_interfaceHttpProxy);
    interfaceConfig.insert(QStringLiteral("httpsProxy"), m_interfaceHttpsProxy);
    interfaceConfig.insert(QStringLiteral("disableResponseStorage"), m_interfaceDisableResponseStorage);
    interfaceConfig.insert(QStringLiteral("wireApi"), m_interfaceWireApi);
    interfaceConfig.insert(QStringLiteral("requiresOpenAiAuth"), m_interfaceRequiresOpenAiAuth);

    QJsonObject storage;
    storage.insert(QStringLiteral("dataLocation"), dataLocation());
    storage.insert(QStringLiteral("maskSecrets"), m_maskSecrets);
    storage.insert(QStringLiteral("keepBackups"), m_keepBackups);
    storage.insert(QStringLiteral("backupRetention"), m_backupRetention);

    QJsonObject root;
    root.insert(QStringLiteral("version"), kSettingsVersion);
    if (includeUpdatedAt) {
        root.insert(QStringLiteral("updatedAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate));
    } else {
        root.insert(QStringLiteral("settingsPath"), settingsPath());
    }
    root.insert(QStringLiteral("appearance"), appearance);
    root.insert(QStringLiteral("behavior"), behavior);
    root.insert(QStringLiteral("proxy"), proxy);
    root.insert(QStringLiteral("profiles"), profiles);
    root.insert(QStringLiteral("interfaceConfig"), interfaceConfig);
    root.insert(QStringLiteral("storage"), storage);
    return root;
}

bool SettingsManager::writeSettingsToDisk(bool announce)
{
    if (announce && m_persistTimer.isActive()) {
        m_persistTimer.stop();
    }

    if (!ensureSettingsRoot()) {
        return false;
    }

    const QByteArray data = QJsonDocument(toJsonObject(true)).toJson(QJsonDocument::Indented);

    QSaveFile file(settingsPath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        setStatusMessage(QStringLiteral("Failed to write %1").arg(settingsPath()));
        return false;
    }

    if (file.write(data) != data.size() || !file.commit()) {
        setStatusMessage(QStringLiteral("Failed to save %1").arg(settingsPath()));
        return false;
    }

    if (announce) {
        setStatusMessage(QStringLiteral("Settings saved to %1").arg(settingsPath()));
    }
    return true;
}
