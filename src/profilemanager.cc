#include "profilemanager.h"

#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QTextStream>
#include <QDateTime>
#include <QRandomGenerator>

#include <algorithm>
#include <numeric>

namespace {
QString nowLabel()
{
    return QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss"));
}

QString tomlString(const QString &value)
{
    QString escaped = value;
    escaped.replace(QLatin1Char('\\'), QStringLiteral("\\\\"));
    escaped.replace(QLatin1Char('"'), QStringLiteral("\\\""));
    return QStringLiteral("\"%1\"").arg(escaped);
}

QString envValue(const QString &value)
{
    QString escaped = value;
    escaped.replace(QLatin1Char('\\'), QStringLiteral("\\\\"));
    escaped.replace(QLatin1Char('"'), QStringLiteral("\\\""));
    escaped.replace(QLatin1Char('\n'), QStringLiteral("\\n"));
    return QStringLiteral("\"%1\"").arg(escaped);
}

QString unquoteValue(QString value)
{
    value = value.trimmed();
    if ((value.startsWith(QLatin1Char('"')) && value.endsWith(QLatin1Char('"')))
        || (value.startsWith(QLatin1Char('\'')) && value.endsWith(QLatin1Char('\'')))) {
        value = value.mid(1, value.size() - 2);
    }
    value.replace(QStringLiteral("\\n"), QStringLiteral("\n"));
    value.replace(QStringLiteral("\\\""), QStringLiteral("\""));
    value.replace(QStringLiteral("\\\\"), QStringLiteral("\\"));
    return value;
}

QHash<QString, QString> readKeyValueFile(const QString &path, const QChar separator)
{
    QHash<QString, QString> values;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return values;
    }

    QTextStream stream(&file);
    while (!stream.atEnd()) {
        QString line = stream.readLine().trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) {
            continue;
        }

        const qsizetype separatorIndex = line.indexOf(separator);
        if (separatorIndex <= 0) {
            continue;
        }

        const QString key = line.left(separatorIndex).trimmed();
        const QString value = unquoteValue(line.mid(separatorIndex + 1));
        values.insert(key, value);
    }
    return values;
}

QHash<QString, QString> readTomlValues(const QString &path)
{
    QHash<QString, QString> values;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return values;
    }

    QString section;
    QTextStream stream(&file);
    while (!stream.atEnd()) {
        QString line = stream.readLine().trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) {
            continue;
        }

        if (line.startsWith(QLatin1Char('[')) && line.endsWith(QLatin1Char(']'))) {
            section = line.mid(1, line.size() - 2).trimmed();
            continue;
        }

        const qsizetype separatorIndex = line.indexOf(QLatin1Char('='));
        if (separatorIndex <= 0) {
            continue;
        }

        const QString key = line.left(separatorIndex).trimmed();
        const QString value = unquoteValue(line.mid(separatorIndex + 1));
        values.insert(section.isEmpty() ? key : section + QLatin1Char('.') + key, value);
    }
    return values;
}

bool tomlBool(const QHash<QString, QString> &values, const QString &key, bool fallback)
{
    const QString value = values.value(key).trimmed().toLower();
    if (value == QStringLiteral("true")) {
        return true;
    }
    if (value == QStringLiteral("false")) {
        return false;
    }
    return fallback;
}
}

ProfileManager::ProfileManager(QObject *parent)
    : QObject(parent)
    , m_activeSection(QStringLiteral("Dashboard"))
{
    ensureProfileRoot();
    loadProfilesFromDisk();

    if (m_profiles.isEmpty()) {
        setStatusMessage(QStringLiteral("Create a profile to begin"));
    } else {
        m_profiles[0].active = true;
        setStatusMessage(QStringLiteral("Loaded %1 profiles").arg(m_profiles.size()));
    }
}

QString ProfileManager::activeSection() const
{
    return m_activeSection;
}

void ProfileManager::setActiveSection(const QString &section)
{
    if (m_activeSection == section) {
        return;
    }

    m_activeSection = section;
    emit activeSectionChanged();
}

QVariantMap ProfileManager::currentProfile() const
{
    const Profile *profile = selectedProfile();
    if (!profile) {
        Profile emptyProfile;
        emptyProfile.name = QStringLiteral("No Profile Selected");
        emptyProfile.agentType = QStringLiteral("-");
        emptyProfile.description = QStringLiteral("Create a profile to begin");
        emptyProfile.modelProvider = QStringLiteral("-");
        emptyProfile.model = QStringLiteral("-");
        emptyProfile.reasoningEffort = QStringLiteral("-");
        emptyProfile.baseUrl = QString();
        return profileToMap(emptyProfile, -1);
    }

    return profileToMap(*profile, m_selectedProfileIndex);
}

QVariantMap ProfileManager::dashboard() const
{
    QVariantMap result;
    const auto activeIt = std::find_if(m_profiles.cbegin(), m_profiles.cend(), [](const Profile &profile) {
        return profile.active;
    });

    const Profile *activeProfile = activeIt == m_profiles.cend() ? selectedProfile() : &(*activeIt);
    const int totalTokens = std::accumulate(m_profiles.cbegin(), m_profiles.cend(), 0, [](int total, const Profile &profile) {
        return total + profile.todayTokens;
    });
    const int healthyCount = std::count_if(m_healthChecks.cbegin(), m_healthChecks.cend(), [](const HealthCheck &check) {
        return check.status == QStringLiteral("OK");
    });

    result.insert(QStringLiteral("activeProfile"), activeProfile ? activeProfile->name : QStringLiteral("-"));
    result.insert(QStringLiteral("activeAgent"), activeProfile ? activeProfile->agentType : QStringLiteral("-"));
    result.insert(QStringLiteral("profileCount"), m_profiles.size());
    result.insert(QStringLiteral("systemHealth"), healthyCount == m_healthChecks.size() ? QStringLiteral("All Systems Go") : QStringLiteral("Needs Attention"));
    result.insert(QStringLiteral("healthDetail"), QStringLiteral("%1 of %2 checks healthy").arg(healthyCount).arg(m_healthChecks.size()));
    result.insert(QStringLiteral("lastChecked"), m_healthChecks.isEmpty() ? QStringLiteral("No checks yet") : QStringLiteral("Last checked at %1").arg(m_healthChecks.first().checkedAt));
    result.insert(QStringLiteral("tokensToday"), totalTokens);
    result.insert(QStringLiteral("tokenDetail"), QStringLiteral("Across %1 profiles").arg(m_profiles.size()));

    return result;
}

QVariantList ProfileManager::healthChecks() const
{
    QVariantList list;
    list.reserve(m_healthChecks.size());
    for (const HealthCheck &check : m_healthChecks) {
        list.append(healthCheckToMap(check));
    }
    return list;
}

QVariantList ProfileManager::profiles() const
{
    QVariantList list;
    list.reserve(m_profiles.size());
    for (int i = 0; i < m_profiles.size(); ++i) {
        list.append(profileToMap(m_profiles.at(i), i));
    }
    return list;
}

int ProfileManager::selectedProfileIndex() const
{
    return m_selectedProfileIndex;
}

QString ProfileManager::statusMessage() const
{
    return m_statusMessage;
}

QVariantList ProfileManager::tokenUsage() const
{
    QVariantList list;
    list.reserve(m_profiles.size());
    for (int i = 0; i < m_profiles.size(); ++i) {
        const Profile &profile = m_profiles.at(i);
        QVariantMap item;
        item.insert(QStringLiteral("index"), i);
        item.insert(QStringLiteral("name"), profile.name);
        item.insert(QStringLiteral("agentType"), profile.agentType);
        item.insert(QStringLiteral("tokens"), profile.todayTokens);
        item.insert(QStringLiteral("limit"), profile.monthlyLimit);
        item.insert(QStringLiteral("ratio"), profile.monthlyLimit == 0 ? 0.0 : static_cast<double>(profile.todayTokens) / profile.monthlyLimit);
        item.insert(QStringLiteral("active"), profile.active);
        list.append(item);
    }
    return list;
}

bool ProfileManager::activateSelectedProfile()
{
    if (!selectedProfile()) {
        return false;
    }

    if (!applySelectedProfileToCodex()) {
        return false;
    }

    for (int i = 0; i < m_profiles.size(); ++i) {
        m_profiles[i].active = (i == m_selectedProfileIndex);
    }

    setStatusMessage(QStringLiteral("%1 is now active").arg(m_profiles.at(m_selectedProfileIndex).name));
    emitDataChanged();
    return true;
}

void ProfileManager::createProfile()
{
    setStatusMessage(QStringLiteral("Profile name is required"));
}

bool ProfileManager::createProfileWithConfiguration(const QString &name,
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
                                                    bool requiresOpenAiAuth)
{
    const QString trimmedName = name.trimmed();
    if (!isValidProfileName(trimmedName)) {
        setStatusMessage(QStringLiteral("Profile name is required and cannot contain / or \\"));
        return false;
    }

    const QString folderName = profileFolderName(trimmedName);
    const auto duplicate = std::find_if(m_profiles.cbegin(), m_profiles.cend(), [&folderName](const Profile &profile) {
        return profile.folderName == folderName;
    });
    if (duplicate != m_profiles.cend()) {
        setStatusMessage(QStringLiteral("%1 already exists").arg(trimmedName));
        return false;
    }

    Profile profile;
    profile.name = trimmedName;
    profile.description = QStringLiteral("New agent configuration");
    profile.active = false;
    profile.todayTokens = 0;

    applyConfiguration(profile,
                       name,
                       agentType,
                       modelProvider,
                       model,
                       reasoningEffort,
                       baseUrl,
                       apiKey,
                       httpProxy,
                       httpsProxy,
                       disableResponseStorage,
                       wireApi,
                       requiresOpenAiAuth);
    if (!writeProfileToDisk(&profile)) {
        return false;
    }

    m_profiles.append(profile);
    m_selectedProfileIndex = m_profiles.size() - 1;

    setStatusMessage(QStringLiteral("%1 created").arg(profile.name));
    emit selectedProfileIndexChanged();
    emitDataChanged();
    return true;
}

void ProfileManager::deleteSelectedProfile()
{
    if (!selectedProfile() || m_profiles.size() <= 1) {
        setStatusMessage(QStringLiteral("At least one profile must remain"));
        return;
    }

    const QString removedName = m_profiles.at(m_selectedProfileIndex).name;
    const bool removedActive = m_profiles.at(m_selectedProfileIndex).active;
    const QString removedFolderName = m_profiles.at(m_selectedProfileIndex).folderName;
    m_profiles.removeAt(m_selectedProfileIndex);

    QString removalWarning;
    QDir profileDir(profileRootDir().filePath(removedFolderName));
    if (profileDir.exists() && !profileDir.removeRecursively()) {
        removalWarning = QStringLiteral("Deleted from UI, but failed to remove %1").arg(profileDir.path());
    }

    if (m_selectedProfileIndex >= m_profiles.size()) {
        m_selectedProfileIndex = m_profiles.size() - 1;
    }

    if (removedActive && !m_profiles.isEmpty()) {
        m_profiles[m_selectedProfileIndex].active = true;
    }

    setStatusMessage(removalWarning.isEmpty() ? QStringLiteral("%1 deleted").arg(removedName) : removalWarning);
    emit selectedProfileIndexChanged();
    emitDataChanged();
}

void ProfileManager::editSelectedProfile()
{
    if (!selectedProfile()) {
        return;
    }

    setStatusMessage(QStringLiteral("Editing %1").arg(selectedProfile()->name));
}

void ProfileManager::runHealthCheck()
{
    const Profile *profile = selectedProfile();
    if (!profile) {
        return;
    }

    const int latency = static_cast<int>(QRandomGenerator::global()->bounded(160, 680));
    const QString status = latency > 560 ? QStringLiteral("WARN") : QStringLiteral("OK");
    const QString endpoint = profile->baseUrl
                                 .trimmed()
                                 .remove(QStringLiteral("https://"))
                                 .remove(QStringLiteral("http://"))
                                 .append(QStringLiteral("/models"));

    m_healthChecks.prepend({profile->name, endpoint, status, latency, nowLabel()});
    while (m_healthChecks.size() > 8) {
        m_healthChecks.removeLast();
    }

    setStatusMessage(QStringLiteral("Health check finished for %1").arg(profile->name));
    emit healthChecksChanged();
    emit dashboardChanged();
}

bool ProfileManager::saveConfiguration(const QString &name,
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
                                       bool requiresOpenAiAuth)
{
    Profile *profile = selectedProfile();
    if (!profile) {
        return false;
    }

    const QString trimmedName = name.trimmed();
    if (!isValidProfileName(trimmedName)) {
        setStatusMessage(QStringLiteral("Profile name is required and cannot contain / or \\"));
        return false;
    }

    const QString nextFolderName = profileFolderName(trimmedName);
    for (int i = 0; i < m_profiles.size(); ++i) {
        if (i != m_selectedProfileIndex && m_profiles.at(i).folderName == nextFolderName) {
            setStatusMessage(QStringLiteral("%1 already exists").arg(trimmedName));
            return false;
        }
    }

    const QString previousFolderName = profile->folderName;
    applyConfiguration(*profile,
                       name,
                       agentType,
                       modelProvider,
                       model,
                       reasoningEffort,
                       baseUrl,
                       apiKey,
                       httpProxy,
                       httpsProxy,
                       disableResponseStorage,
                       wireApi,
                       requiresOpenAiAuth);
    if (!writeProfileToDisk(profile, previousFolderName)) {
        profile->folderName = previousFolderName;
        return false;
    }

    setStatusMessage(QStringLiteral("%1 saved").arg(profile->name));
    emitDataChanged();
    return true;
}

void ProfileManager::applyConfiguration(Profile &profile,
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
                                        bool requiresOpenAiAuth)
{
    const QString trimmedName = name.trimmed();
    if (!trimmedName.isEmpty()) {
        profile.name = trimmedName;
    }
    profile.agentType = agentType.trimmed().isEmpty() ? profile.agentType : agentType.trimmed();
    profile.modelProvider = modelProvider.trimmed().isEmpty() ? profile.modelProvider : modelProvider.trimmed();
    profile.model = model.trimmed().isEmpty() ? profile.model : model.trimmed();
    profile.reasoningEffort = reasoningEffort.trimmed().isEmpty() ? profile.reasoningEffort : reasoningEffort.trimmed();
    profile.baseUrl = baseUrl.trimmed();
    profile.httpProxy = httpProxy.trimmed();
    profile.httpsProxy = httpsProxy.trimmed();
    profile.disableResponseStorage = disableResponseStorage;
    profile.wireApi = wireApi.trimmed().isEmpty() ? QStringLiteral("responses") : wireApi.trimmed();
    profile.requiresOpenAiAuth = requiresOpenAiAuth;

    const QString trimmedApiKey = apiKey.trimmed();
    if (!trimmedApiKey.isEmpty() && trimmedApiKey != maskedApiKey(profile.apiKey)) {
        profile.apiKey = trimmedApiKey;
    }

    profile.description = QStringLiteral("%1 %2 Configuration").arg(profile.modelProvider, profile.agentType);
    profile.folderName = profileFolderName(profile.name);
}

void ProfileManager::selectProfile(int index)
{
    if (index < 0 || index >= m_profiles.size() || index == m_selectedProfileIndex) {
        return;
    }

    m_selectedProfileIndex = index;
    setStatusMessage(QStringLiteral("%1 selected").arg(m_profiles.at(index).name));
    emit selectedProfileIndexChanged();
    emit currentProfileChanged();
}

bool ProfileManager::selectProfileByFolderName(const QString &folderName)
{
    const QString targetFolderName = folderName.trimmed();
    if (targetFolderName.isEmpty()) {
        return false;
    }

    for (int i = 0; i < m_profiles.size(); ++i) {
        if (m_profiles.at(i).folderName == targetFolderName) {
            selectProfile(i);
            return true;
        }
    }

    return false;
}

bool ProfileManager::setActiveProfileByFolderName(const QString &folderName)
{
    const QString targetFolderName = folderName.trimmed();
    if (targetFolderName.isEmpty()) {
        return false;
    }

    bool found = false;
    for (int i = 0; i < m_profiles.size(); ++i) {
        const bool active = m_profiles.at(i).folderName == targetFolderName;
        found = found || active;
        m_profiles[i].active = active;
    }

    if (!found) {
        return false;
    }

    emitDataChanged();
    return true;
}

void ProfileManager::selectSection(const QString &section)
{
    setActiveSection(section);
}

QVariantMap ProfileManager::healthCheckToMap(const HealthCheck &check) const
{
    QVariantMap map;
    map.insert(QStringLiteral("profile"), check.profileName);
    map.insert(QStringLiteral("endpoint"), check.endpoint);
    map.insert(QStringLiteral("status"), check.status);
    map.insert(QStringLiteral("latency"), QStringLiteral("%1ms").arg(check.latencyMs));
    map.insert(QStringLiteral("latencyValue"), check.latencyMs);
    map.insert(QStringLiteral("checkedAt"), check.checkedAt);
    return map;
}

bool ProfileManager::applySelectedProfileToCodex()
{
    const Profile *profile = selectedProfile();
    if (!profile) {
        return false;
    }

    const QDir sourceDir(profileRootDir().filePath(profile->folderName));
    if (!sourceDir.exists()) {
        setStatusMessage(QStringLiteral("Profile folder does not exist: %1").arg(sourceDir.path()));
        return false;
    }

    QDir codexDir(QDir::homePath() + QStringLiteral("/.codex"));
    if (!codexDir.exists() && !QDir().mkpath(codexDir.path())) {
        setStatusMessage(fileError(QStringLiteral("create"), codexDir.path()));
        return false;
    }

    const QStringList files = {QStringLiteral(".env"), QStringLiteral("config.toml"), QStringLiteral("auth.json")};
    for (const QString &fileName : files) {
        const QString sourcePath = sourceDir.filePath(fileName);
        const QString targetPath = codexDir.filePath(fileName);
        if (!copyFileReplacing(sourcePath, targetPath)) {
            return false;
        }
    }

    return true;
}

bool ProfileManager::copyFileReplacing(const QString &sourcePath, const QString &targetPath)
{
    QFile sourceFile(sourcePath);
    if (!sourceFile.open(QIODevice::ReadOnly)) {
        setStatusMessage(fileError(QStringLiteral("find"), sourcePath));
        return false;
    }

    QSaveFile targetFile(targetPath);
    if (!targetFile.open(QIODevice::WriteOnly)) {
        setStatusMessage(fileError(QStringLiteral("write"), targetPath));
        return false;
    }

    if (targetFile.write(sourceFile.readAll()) == -1 || !targetFile.commit()) {
        setStatusMessage(fileError(QStringLiteral("replace"), targetPath));
        return false;
    }

    return true;
}

bool ProfileManager::ensureProfileRoot()
{
    const QDir root = profileRootDir();
    if (root.exists()) {
        return true;
    }

    if (!QDir().mkpath(root.path())) {
        setStatusMessage(fileError(QStringLiteral("create"), root.path()));
        return false;
    }
    return true;
}

QString ProfileManager::fileError(const QString &action, const QString &path) const
{
    return QStringLiteral("Failed to %1 %2").arg(action, path);
}

QString ProfileManager::profileFolderName(const QString &profileName) const
{
    return profileName.trimmed();
}

QDir ProfileManager::profileRootDir() const
{
    return QDir(QDir::current().filePath(QStringLiteral("loomprofile")));
}

bool ProfileManager::isValidProfileName(const QString &name) const
{
    const QString trimmed = name.trimmed();
    return !trimmed.isEmpty()
        && !trimmed.contains(QLatin1Char('/'))
        && !trimmed.contains(QLatin1Char('\\'))
        && trimmed != QStringLiteral(".")
        && trimmed != QStringLiteral("..");
}

void ProfileManager::loadProfilesFromDisk()
{
    m_profiles.clear();
    const QDir root = profileRootDir();
    const QFileInfoList entries = root.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &entry : entries) {
        Profile profile;
        if (readProfileFromDirectory(entry.fileName(), &profile)) {
            m_profiles.append(profile);
        }
    }

    m_selectedProfileIndex = m_profiles.isEmpty() ? -1 : 0;
    m_healthChecks.clear();
}

QString ProfileManager::maskedApiKey(const QString &apiKey) const
{
    if (apiKey.isEmpty()) {
        return QString();
    }

    const QString suffix = apiKey.size() > 4 ? apiKey.right(4) : QStringLiteral("key");
    return QStringLiteral("sk-************%1").arg(suffix);
}

QVariantMap ProfileManager::profileToMap(const Profile &profile, int index) const
{
    QVariantMap map;
    map.insert(QStringLiteral("index"), index);
    map.insert(QStringLiteral("name"), profile.name);
    map.insert(QStringLiteral("agentType"), profile.agentType);
    map.insert(QStringLiteral("description"), profile.description);
    map.insert(QStringLiteral("modelProvider"), profile.modelProvider);
    map.insert(QStringLiteral("model"), profile.model);
    map.insert(QStringLiteral("reasoningEffort"), profile.reasoningEffort);
    map.insert(QStringLiteral("baseUrl"), profile.baseUrl);
    map.insert(QStringLiteral("apiKey"), profile.apiKey);
    map.insert(QStringLiteral("maskedApiKey"), maskedApiKey(profile.apiKey));
    map.insert(QStringLiteral("httpProxy"), profile.httpProxy);
    map.insert(QStringLiteral("httpsProxy"), profile.httpsProxy);
    map.insert(QStringLiteral("disableResponseStorage"), profile.disableResponseStorage);
    map.insert(QStringLiteral("wireApi"), profile.wireApi);
    map.insert(QStringLiteral("requiresOpenAiAuth"), profile.requiresOpenAiAuth);
    map.insert(QStringLiteral("folderName"), profile.folderName);
    map.insert(QStringLiteral("todayTokens"), profile.todayTokens);
    map.insert(QStringLiteral("monthlyLimit"), profile.monthlyLimit);
    map.insert(QStringLiteral("active"), profile.active);
    return map;
}

bool ProfileManager::readProfileFromDirectory(const QString &folderName, Profile *profile) const
{
    if (!profile) {
        return false;
    }

    const QDir dir(profileRootDir().filePath(folderName));
    if (!dir.exists()) {
        return false;
    }

    const QHash<QString, QString> env = readKeyValueFile(dir.filePath(QStringLiteral(".env")), QLatin1Char('='));
    const QHash<QString, QString> config = readTomlValues(dir.filePath(QStringLiteral("config.toml")));

    QJsonObject auth;
    QFile authFile(dir.filePath(QStringLiteral("auth.json")));
    if (authFile.open(QIODevice::ReadOnly)) {
        const QJsonDocument document = QJsonDocument::fromJson(authFile.readAll());
        auth = document.object();
    }

    profile->folderName = folderName;
    profile->name = folderName;
    profile->agentType = QStringLiteral("Codex");
    profile->modelProvider = config.value(QStringLiteral("model_provider"), QStringLiteral("OpenAI"));
    const QString providerPrefix = QStringLiteral("model_providers.%1.").arg(profile->modelProvider);
    profile->model = config.value(QStringLiteral("model"), QStringLiteral("gpt-5.5"));
    profile->reasoningEffort = config.value(QStringLiteral("model_reasoning_effort"), QStringLiteral("high"));
    profile->disableResponseStorage = tomlBool(config, QStringLiteral("disable_response_storage"), true);
    profile->baseUrl = config.value(providerPrefix + QStringLiteral("base_url"),
                                    config.value(QStringLiteral("base_url"), env.value(QStringLiteral("BASE_URL"))));
    profile->wireApi = config.value(providerPrefix + QStringLiteral("wire_api"), QStringLiteral("responses"));
    profile->requiresOpenAiAuth = tomlBool(config, providerPrefix + QStringLiteral("requires_openai_auth"), true);
    profile->httpProxy = env.value(QStringLiteral("HTTP_PROXY"));
    profile->httpsProxy = env.value(QStringLiteral("HTTPS_PROXY"));
    profile->apiKey = auth.value(QStringLiteral("OPENAI_API_KEY")).toString();
    if (profile->apiKey.isEmpty()) {
        profile->apiKey = env.value(QStringLiteral("OPENAI_API_KEY"));
    }
    profile->description = QStringLiteral("%1 %2 Configuration").arg(profile->modelProvider, profile->agentType);
    profile->todayTokens = 0;
    profile->monthlyLimit = 500000;
    profile->active = false;
    return QFileInfo::exists(dir.filePath(QStringLiteral(".env")))
        || QFileInfo::exists(dir.filePath(QStringLiteral("config.toml")))
        || QFileInfo::exists(dir.filePath(QStringLiteral("auth.json")));
}

ProfileManager::Profile *ProfileManager::selectedProfile()
{
    if (m_selectedProfileIndex < 0 || m_selectedProfileIndex >= m_profiles.size()) {
        return nullptr;
    }

    return &m_profiles[m_selectedProfileIndex];
}

const ProfileManager::Profile *ProfileManager::selectedProfile() const
{
    if (m_selectedProfileIndex < 0 || m_selectedProfileIndex >= m_profiles.size()) {
        return nullptr;
    }

    return &m_profiles.at(m_selectedProfileIndex);
}

void ProfileManager::emitDataChanged()
{
    emit profilesChanged();
    emit currentProfileChanged();
    emit dashboardChanged();
    emit tokenUsageChanged();
}

void ProfileManager::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message) {
        return;
    }

    m_statusMessage = message;
    emit statusMessageChanged();
}

bool ProfileManager::writeProfileToDisk(Profile *profile, const QString &previousFolderName)
{
    if (!profile) {
        return false;
    }

    if (!ensureProfileRoot()) {
        return false;
    }

    profile->folderName = profileFolderName(profile->name);
    const QDir root = profileRootDir();
    const QString profilePath = root.filePath(profile->folderName);
    if (!QDir().mkpath(profilePath)) {
        setStatusMessage(fileError(QStringLiteral("create"), profilePath));
        return false;
    }

    QSaveFile envFile(QDir(profilePath).filePath(QStringLiteral(".env")));
    if (!envFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        setStatusMessage(fileError(QStringLiteral("write"), envFile.fileName()));
        return false;
    }
    QTextStream envStream(&envFile);
    if (!profile->httpProxy.isEmpty()) {
        envStream << "HTTP_PROXY=" << envValue(profile->httpProxy) << "\n";
    }
    if (!profile->httpsProxy.isEmpty()) {
        envStream << "HTTPS_PROXY=" << envValue(profile->httpsProxy) << "\n";
    }
    if (!envFile.commit()) {
        setStatusMessage(fileError(QStringLiteral("write"), envFile.fileName()));
        return false;
    }

    QSaveFile configFile(QDir(profilePath).filePath(QStringLiteral("config.toml")));
    if (!configFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        setStatusMessage(fileError(QStringLiteral("write"), configFile.fileName()));
        return false;
    }
    QTextStream configStream(&configFile);
    configStream << "model_provider = " << tomlString(profile->modelProvider) << "\n";
    configStream << "model = " << tomlString(profile->model) << "\n";
    configStream << "model_reasoning_effort = " << tomlString(profile->reasoningEffort) << "\n";
    configStream << "disable_response_storage = " << (profile->disableResponseStorage ? "true" : "false") << "\n\n";
    configStream << "[model_providers." << profile->modelProvider << "]\n";
    configStream << "name = " << tomlString(profile->modelProvider) << "\n";
    configStream << "base_url = " << tomlString(profile->baseUrl) << "\n";
    configStream << "wire_api = " << tomlString(profile->wireApi) << "\n";
    configStream << "requires_openai_auth = " << (profile->requiresOpenAiAuth ? "true" : "false") << "\n";
    if (!configFile.commit()) {
        setStatusMessage(fileError(QStringLiteral("write"), configFile.fileName()));
        return false;
    }

    QJsonObject auth;
    auth.insert(QStringLiteral("auth_mode"), QStringLiteral("apikey"));
    auth.insert(QStringLiteral("OPENAI_API_KEY"), profile->apiKey);
    QSaveFile authFile(QDir(profilePath).filePath(QStringLiteral("auth.json")));
    if (!authFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        setStatusMessage(fileError(QStringLiteral("write"), authFile.fileName()));
        return false;
    }
    authFile.write(QJsonDocument(auth).toJson(QJsonDocument::Indented));
    if (!authFile.commit()) {
        setStatusMessage(fileError(QStringLiteral("write"), authFile.fileName()));
        return false;
    }

    if (!previousFolderName.isEmpty() && previousFolderName != profile->folderName) {
        QDir oldDir(root.filePath(previousFolderName));
        if (oldDir.exists() && !oldDir.removeRecursively()) {
            setStatusMessage(QStringLiteral("%1 saved, but old folder could not be removed").arg(profile->name));
        }
    }

    return true;
}
