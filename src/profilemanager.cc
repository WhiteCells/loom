#include "profilemanager.h"

#include <QByteArray>
#include <QDate>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QDateTime>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QList>
#include <QSaveFile>
#include <QStringList>
#include <QTextStream>
#include <QUrl>

#include <algorithm>
#include <numeric>
#include <utility>

namespace {
QString nowLabel()
{
    return QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss"));
}

QString normalizedProviderKey(const QString &provider, const QString &baseUrl)
{
    const QString normalizedProvider = provider.trimmed().toLower();
    const QString normalizedEndpoint = baseUrl.trimmed().toLower();

    if (normalizedProvider.contains(QStringLiteral("anthropic"))
        || normalizedProvider.contains(QStringLiteral("claude"))
        || normalizedEndpoint.contains(QStringLiteral("anthropic"))
        || normalizedEndpoint.contains(QStringLiteral("claude"))) {
        return QStringLiteral("anthropic");
    }

    if (normalizedProvider.contains(QStringLiteral("openai"))
        || normalizedEndpoint.contains(QStringLiteral("openai"))
        || normalizedEndpoint.contains(QStringLiteral("jucode"))) {
        return QStringLiteral("openai");
    }

    return normalizedProvider.isEmpty() ? QStringLiteral("custom") : normalizedProvider;
}

QString providerLabel(const QString &providerKey, const QString &fallback)
{
    if (providerKey == QStringLiteral("openai")) {
        return QStringLiteral("OpenAI");
    }
    if (providerKey == QStringLiteral("anthropic")) {
        return QStringLiteral("Anthropic");
    }

    const QString trimmedFallback = fallback.trimmed();
    return trimmedFallback.isEmpty() ? QStringLiteral("Custom") : trimmedFallback;
}

QString providerStatusEndpoint(const QString &providerKey)
{
    if (providerKey == QStringLiteral("openai")) {
        return QStringLiteral("https://status.openai.com/api/v2/status.json");
    }
    if (providerKey == QStringLiteral("anthropic")) {
        return QStringLiteral("https://status.claude.com/api/v2/status.json");
    }

    return QString();
}

QString modelOptionsEndpoint(const QString &baseUrl)
{
    QString endpoint = baseUrl.trimmed();
    if (endpoint.isEmpty()) {
        return QString();
    }

    while (endpoint.endsWith(QLatin1Char('/'))) {
        endpoint.chop(1);
    }
    if (!endpoint.endsWith(QStringLiteral("/models"))) {
        endpoint += QStringLiteral("/models");
    }
    return endpoint;
}

QString healthDescription(const QString &description, const QString &fallback)
{
    const QString trimmed = description.trimmed();
    return trimmed.isEmpty() ? fallback : trimmed;
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

QString readTextFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString();
    }
    return QString::fromUtf8(file.readAll());
}

bool parseSectionHeader(const QString &line, QString *section)
{
    const QString trimmed = line.trimmed();
    if (!trimmed.startsWith(QLatin1Char('[')) || !trimmed.endsWith(QLatin1Char(']'))
        || trimmed.startsWith(QStringLiteral("[["))) {
        return false;
    }

    if (section) {
        *section = trimmed.mid(1, trimmed.size() - 2).trimmed();
    }
    return true;
}

bool parseAssignmentKey(const QString &line, QString *key)
{
    const QString trimmed = line.trimmed();
    if (trimmed.isEmpty() || trimmed.startsWith(QLatin1Char('#')) || trimmed.startsWith(QLatin1Char('['))) {
        return false;
    }

    const qsizetype separatorIndex = trimmed.indexOf(QLatin1Char('='));
    if (separatorIndex <= 0) {
        return false;
    }

    if (key) {
        *key = trimmed.left(separatorIndex).trimmed();
    }
    return key ? !key->isEmpty() : true;
}

void removeTrailingEmptyLines(QStringList *lines)
{
    while (lines && !lines->isEmpty() && lines->last().trimmed().isEmpty()) {
        lines->removeLast();
    }
}

void upsertTomlSection(QStringList *lines, const QString &section, const QVector<QPair<QString, QString>> &assignments)
{
    if (!lines || assignments.isEmpty()) {
        return;
    }

    QHash<QString, QString> valuesByKey;
    for (const auto &assignment : assignments) {
        valuesByKey.insert(assignment.first, assignment.second);
    }

    int sectionStart = 0;
    int sectionEnd = lines->size();
    if (section.isEmpty()) {
        for (int i = 0; i < lines->size(); ++i) {
            QString currentSection;
            if (parseSectionHeader(lines->at(i), &currentSection)) {
                sectionEnd = i;
                break;
            }
        }
    } else {
        sectionStart = -1;
        for (int i = 0; i < lines->size(); ++i) {
            QString currentSection;
            if (!parseSectionHeader(lines->at(i), &currentSection)) {
                continue;
            }

            if (currentSection != section) {
                continue;
            }

            sectionStart = i + 1;
            sectionEnd = lines->size();
            for (int j = i + 1; j < lines->size(); ++j) {
                QString nextSection;
                if (parseSectionHeader(lines->at(j), &nextSection)) {
                    sectionEnd = j;
                    break;
                }
            }
            break;
        }

        if (sectionStart < 0) {
            removeTrailingEmptyLines(lines);
            if (!lines->isEmpty()) {
                lines->append(QString());
            }
            lines->append(QStringLiteral("[%1]").arg(section));
            for (const auto &assignment : assignments) {
                lines->append(QStringLiteral("%1 = %2").arg(assignment.first, assignment.second));
            }
            return;
        }
    }

    QStringList updatedKeys;
    for (int i = sectionStart; i < sectionEnd; ++i) {
        QString key;
        if (!parseAssignmentKey(lines->at(i), &key) || !valuesByKey.contains(key)) {
            continue;
        }

        (*lines)[i] = QStringLiteral("%1 = %2").arg(key, valuesByKey.value(key));
        updatedKeys.append(key);
    }

    int insertIndex = sectionEnd;
    for (const auto &assignment : assignments) {
        if (updatedKeys.contains(assignment.first)) {
            continue;
        }

        lines->insert(insertIndex, QStringLiteral("%1 = %2").arg(assignment.first, assignment.second));
        ++insertIndex;
    }
}

QString mergedLoomToml(QString existing,
                       const QString &providerName,
                       const QString &baseUrl,
                       const QString &model,
                       const QString &reasoningEffort,
                       bool disableResponseStorage,
                       const QString &wireApi,
                       bool requiresOpenAiAuth)
{
    QStringList lines = existing.isEmpty() ? QStringList() : existing.split(QLatin1Char('\n'));
    removeTrailingEmptyLines(&lines);

    upsertTomlSection(&lines,
                      QString(),
                      {{QStringLiteral("model_provider"), tomlString(providerName)},
                       {QStringLiteral("model"), tomlString(model)},
                       {QStringLiteral("model_reasoning_effort"), tomlString(reasoningEffort)},
                       {QStringLiteral("disable_response_storage"), disableResponseStorage ? QStringLiteral("true") : QStringLiteral("false")}});
    upsertTomlSection(&lines,
                      QStringLiteral("model_providers.%1").arg(providerName),
                      {{QStringLiteral("name"), tomlString(providerName)},
                       {QStringLiteral("base_url"), tomlString(baseUrl)},
                       {QStringLiteral("wire_api"), tomlString(wireApi)},
                       {QStringLiteral("requires_openai_auth"), requiresOpenAiAuth ? QStringLiteral("true") : QStringLiteral("false")}});

    removeTrailingEmptyLines(&lines);
    return lines.join(QLatin1Char('\n')) + QLatin1Char('\n');
}

QString mergedEnvFile(QString existing, const QVector<QPair<QString, QString>> &assignments)
{
    QStringList lines = existing.isEmpty() ? QStringList() : existing.split(QLatin1Char('\n'));
    removeTrailingEmptyLines(&lines);

    QStringList managedKeys;
    QHash<QString, QString> valuesByKey;
    for (const auto &assignment : assignments) {
        managedKeys.append(assignment.first);
        valuesByKey.insert(assignment.first, assignment.second);
    }

    QStringList merged;
    QStringList writtenKeys;
    for (const QString &line : std::as_const(lines)) {
        QString key;
        if (!parseAssignmentKey(line, &key) || !managedKeys.contains(key)) {
            merged.append(line);
            continue;
        }

        const QString value = valuesByKey.value(key);
        if (!value.isEmpty()) {
            merged.append(QStringLiteral("%1=%2").arg(key, value));
            writtenKeys.append(key);
        }
    }

    for (const auto &assignment : assignments) {
        if (!assignment.second.isEmpty() && !writtenKeys.contains(assignment.first)) {
            merged.append(QStringLiteral("%1=%2").arg(assignment.first, assignment.second));
        }
    }

    removeTrailingEmptyLines(&merged);
    return merged.join(QLatin1Char('\n')) + QLatin1Char('\n');
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

qint64 jsonInteger(const QJsonObject &object, const QString &key)
{
    const QJsonValue value = object.value(key);
    if (value.isDouble()) {
        return static_cast<qint64>(value.toDouble());
    }
    if (value.isString()) {
        bool ok = false;
        const qint64 result = value.toString().toLongLong(&ok);
        return ok ? result : 0;
    }
    return 0;
}

QVariantList modelIdsFromJson(const QJsonDocument &document)
{
    QVariantList models;
    QStringList seen;

    const QJsonValue dataValue = document.object().value(QStringLiteral("data"));
    const QJsonArray data = dataValue.isArray() ? dataValue.toArray() : document.array();
    for (const QJsonValue &itemValue : data) {
        QString id;
        if (itemValue.isObject()) {
            id = itemValue.toObject().value(QStringLiteral("id")).toString().trimmed();
        } else if (itemValue.isString()) {
            id = itemValue.toString().trimmed();
        }

        if (id.isEmpty() || seen.contains(id)) {
            continue;
        }

        seen.append(id);
        models.append(id);
    }

    return models;
}

QString displayDateTime(const QString &isoTimestamp)
{
    QDateTime dateTime = QDateTime::fromString(isoTimestamp, Qt::ISODateWithMs);
    if (dateTime.isValid()) {
        return dateTime.toLocalTime().toString(QStringLiteral("yyyy-MM-dd hh:mm"));
    }

    const QDateTime fallback = QDateTime::fromString(isoTimestamp, Qt::ISODate);
    return fallback.isValid() ? fallback.toLocalTime().toString(QStringLiteral("yyyy-MM-dd hh:mm")) : isoTimestamp;
}

int timestampHour(const QString &isoTimestamp)
{
    QDateTime dateTime = QDateTime::fromString(isoTimestamp, Qt::ISODateWithMs);
    if (!dateTime.isValid()) {
        dateTime = QDateTime::fromString(isoTimestamp, Qt::ISODate);
    }
    return dateTime.isValid() ? dateTime.toLocalTime().time().hour() : 0;
}

QString displayRelativeDate(const QDate &date)
{
    const QDate today = QDate::currentDate();
    if (date == today) {
        return QStringLiteral("Today");
    }
    if (date == today.addDays(-1)) {
        return QStringLiteral("Yesterday");
    }
    if (date == today.addDays(1)) {
        return QStringLiteral("Tomorrow");
    }
    return date.toString(QStringLiteral("yyyy-MM-dd"));
}
} // namespace

ProfileManager::ProfileManager(QObject *parent)
    : QObject(parent)
    , m_healthNetwork(new QNetworkAccessManager(this))
{
    ensureProfileRoot();
    loadProfilesFromDisk();
    m_tokenSelectedDate = QDate::currentDate();
    m_tokenRangeStartDate = m_tokenSelectedDate;
    m_tokenRangeEndDate = m_tokenSelectedDate;
    loadTodayTokenUsage();

    if (m_profiles.isEmpty()) {
        setStatusMessage(QStringLiteral("Create a profile to begin"));
    } else {
        m_profiles[0].active = true;
        m_selectedProfileIndex = 0;
        setStatusMessage(QStringLiteral("Loaded %1 profiles").arg(m_profiles.size()));
    }
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
    const int healthyCount = std::count_if(m_healthChecks.cbegin(), m_healthChecks.cend(), [](const HealthCheck &check) {
        return check.ok;
    });
    const bool hasPendingHealthChecks = std::any_of(m_healthChecks.cbegin(), m_healthChecks.cend(), [](const HealthCheck &check) {
        return check.status == QStringLiteral("CHECKING");
    });

    result.insert(QStringLiteral("activeProfile"), activeProfile ? activeProfile->name : QStringLiteral("-"));
    result.insert(QStringLiteral("activeAgent"), activeProfile ? activeProfile->agentType : QStringLiteral("-"));
    result.insert(QStringLiteral("profileCount"), m_profiles.size());
    result.insert(QStringLiteral("systemHealth"),
                  m_healthChecks.isEmpty()
                      ? QStringLiteral("No checks yet")
                      : (hasPendingHealthChecks
                             ? QStringLiteral("Checking")
                             : (healthyCount == m_healthChecks.size() ? QStringLiteral("All Systems Go") : QStringLiteral("Needs Attention"))));
    result.insert(QStringLiteral("healthDetail"),
                  m_healthChecks.isEmpty()
                      ? QStringLiteral("No checks yet")
                      : QStringLiteral("%1 of %2 checks healthy").arg(healthyCount).arg(m_healthChecks.size()));
    result.insert(QStringLiteral("lastChecked"), m_healthChecks.isEmpty() ? QStringLiteral("No checks yet") : QStringLiteral("Last checked at %1").arg(m_healthChecks.first().checkedAt));
    result.insert(QStringLiteral("tokensToday"), m_tokenTodayTotals.totalTokens);
    result.insert(QStringLiteral("tokenDetail"), QStringLiteral("Across %1 sessions").arg(m_tokenTodaySessionCount));

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

QVariantList ProfileManager::tokenDailySeries() const
{
    QVariantList list;
    list.reserve(m_tokenDailySeries.size());
    for (const TokenDay &day : m_tokenDailySeries) {
        list.append(tokenDayToMap(day));
    }
    return list;
}

QVariantList ProfileManager::tokenSessions() const
{
    QVariantList list;
    list.reserve(m_tokenSessions.size());
    for (const TokenSession &session : m_tokenSessions) {
        list.append(tokenSessionToMap(session));
    }
    return list;
}

QVariantMap ProfileManager::tokenSummary() const
{
    QVariantMap map = tokenTotalsToMap(m_tokenSelectedTotals);
    map.insert(QStringLiteral("date"), m_tokenRangeStartDate == m_tokenRangeEndDate
                                           ? m_tokenRangeStartDate.toString(QStringLiteral("yyyy-MM-dd"))
                                           : QStringLiteral("%1 - %2")
                                                 .arg(m_tokenRangeStartDate.toString(QStringLiteral("yyyy-MM-dd")),
                                                      m_tokenRangeEndDate.toString(QStringLiteral("yyyy-MM-dd"))));
    map.insert(QStringLiteral("dateLabel"), m_tokenRangeStartDate == m_tokenRangeEndDate
                                                ? displayRelativeDate(m_tokenRangeStartDate)
                                                : QStringLiteral("%1 days")
                                                      .arg(m_tokenRangeStartDate.daysTo(m_tokenRangeEndDate) + 1));
    map.insert(QStringLiteral("startDate"), m_tokenRangeStartDate.toString(QStringLiteral("yyyy-MM-dd")));
    map.insert(QStringLiteral("startDateLabel"), displayRelativeDate(m_tokenRangeStartDate));
    map.insert(QStringLiteral("endDate"), m_tokenRangeEndDate.toString(QStringLiteral("yyyy-MM-dd")));
    map.insert(QStringLiteral("endDateLabel"), displayRelativeDate(m_tokenRangeEndDate));
    map.insert(QStringLiteral("sessionCount"), m_tokenSessions.size());
    map.insert(QStringLiteral("contextWindow"), m_tokenSelectedContextWindow);
    map.insert(QStringLiteral("lastUpdated"), m_tokenLastUpdated.isEmpty() ? QStringLiteral("No token events") : m_tokenLastUpdated);
    map.insert(QStringLiteral("sessionsPath"), m_tokenSessionsPath);
    return map;
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

QVariantMap ProfileManager::activeProfileProxyConfig() const
{
    QVariantMap config;
    const Profile *profile = activeProfile();
    if (!profile) {
        return config;
    }

    config.insert(QStringLiteral("name"), profile->name);
    config.insert(QStringLiteral("modelProvider"), profile->modelProvider);
    config.insert(QStringLiteral("model"), profile->model);
    config.insert(QStringLiteral("reasoningEffort"), profile->reasoningEffort);
    config.insert(QStringLiteral("baseUrl"), profile->baseUrl);
    config.insert(QStringLiteral("apiKey"), profile->apiKey);
    config.insert(QStringLiteral("httpProxy"), profile->httpProxy);
    config.insert(QStringLiteral("httpsProxy"), profile->httpsProxy);
    config.insert(QStringLiteral("disableResponseStorage"), profile->disableResponseStorage);
    config.insert(QStringLiteral("wireApi"), profile->wireApi);
    config.insert(QStringLiteral("requiresOpenAiAuth"), profile->requiresOpenAiAuth);
    return config;
}

bool ProfileManager::codexRoutesThroughLoom() const
{
    return m_codexRoutesThroughLoom;
}

void ProfileManager::setCodexRoutesThroughLoom(bool codexRoutesThroughLoom)
{
    if (m_codexRoutesThroughLoom == codexRoutesThroughLoom) {
        return;
    }

    m_codexRoutesThroughLoom = codexRoutesThroughLoom;
    emit codexRoutesThroughLoomChanged();
}

bool ProfileManager::activateSelectedProfile()
{
    if (!selectedProfile()) {
        return false;
    }

    if (!m_codexRoutesThroughLoom && !applySelectedProfileToCodex()) {
        return false;
    }

    for (int i = 0; i < m_profiles.size(); ++i) {
        m_profiles[i].active = (i == m_selectedProfileIndex);
    }

    setStatusMessage(m_codexRoutesThroughLoom
                         ? QStringLiteral("%1 is now active for Loom").arg(m_profiles.at(m_selectedProfileIndex).name)
                         : QStringLiteral("%1 is now active").arg(m_profiles.at(m_selectedProfileIndex).name));
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

    invalidateHealthChecks();
    setStatusMessage(QStringLiteral("%1 created").arg(profile.name));
    emitDataChanged();
    emit selectedProfileIndexChanged();
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

    invalidateHealthChecks();
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

bool ProfileManager::applyActiveProfileToCodex()
{
    const Profile *profile = activeProfile();
    if (!profile) {
        setStatusMessage(QStringLiteral("No active profile selected"));
        return false;
    }

    if (!applyProfileToCodex(*profile)) {
        return false;
    }

    setCodexRoutesThroughLoom(false);
    setStatusMessage(QStringLiteral("%1 applied to Codex").arg(profile->name));
    return true;
}

bool ProfileManager::applyLoomProxyToCodex(const QString &loomBaseUrl)
{
    const Profile *profile = activeProfile();
    if (!profile) {
        setStatusMessage(QStringLiteral("No active profile selected"));
        return false;
    }

    if (!writeLoomProxyConfigurationToCodex(*profile, loomBaseUrl)) {
        return false;
    }

    setCodexRoutesThroughLoom(true);
    setStatusMessage(QStringLiteral("Codex now routes through Loom"));
    return true;
}

void ProfileManager::runHealthCheck()
{
    refreshHealthChecks();
}

void ProfileManager::loadModelOptions(const QString &baseUrl,
                                      const QString &apiKey,
                                      const QString &modelProvider)
{
    abortPendingModelOptions();

    const QString endpoint = modelOptionsEndpoint(baseUrl);
    const QString providerKey = normalizedProviderKey(modelProvider, baseUrl);
    const QString provider = providerLabel(providerKey, modelProvider);
    if (endpoint.isEmpty()) {
        emit modelOptionsLoaded(baseUrl.trimmed(), provider, QVariantList(), QStringLiteral("Endpoint required before loading model options."));
        return;
    }

    if (apiKey.trimmed().isEmpty()) {
        emit modelOptionsLoaded(endpoint, provider, QVariantList(), QStringLiteral("API key required before loading model options."));
        return;
    }

    QNetworkRequest request{QUrl(endpoint)};
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("LoomDesktop/0.1"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(apiKey.trimmed()).toUtf8());
    request.setTransferTimeout(8000);

    m_pendingModelOptionsReply = m_healthNetwork->get(request);
    QNetworkReply *reply = m_pendingModelOptionsReply;
    connect(reply, &QNetworkReply::finished, this, [this, reply, endpoint, provider] {
        if (!reply || reply != m_pendingModelOptionsReply) {
            if (reply) {
                reply->deleteLater();
            }
            return;
        }

        m_pendingModelOptionsReply = nullptr;

        QVariantList models;
        QString errorMessage;

        if (reply->error() != QNetworkReply::NoError) {
            errorMessage = reply->errorString();
        } else {
            QJsonParseError error;
            const QJsonDocument document = QJsonDocument::fromJson(reply->readAll(), &error);
            if (error.error != QJsonParseError::NoError) {
                errorMessage = error.errorString();
            } else {
                models = modelIdsFromJson(document);
                if (models.isEmpty()) {
                    errorMessage = QStringLiteral("No model options found");
                }
            }
        }

        if (!errorMessage.isEmpty()) {
            emit modelOptionsLoaded(endpoint, provider, QVariantList(), errorMessage);
        } else {
            emit modelOptionsLoaded(endpoint, provider, models, QString());
        }

        reply->deleteLater();
    });
}

void ProfileManager::refreshHealthChecks()
{
    abortPendingHealthChecks();

    if (m_profiles.isEmpty()) {
        m_healthChecks.clear();
        setStatusMessage(QStringLiteral("Create a profile to begin"));
        emit healthChecksChanged();
        emit dashboardChanged();
        return;
    }

    const QString checkedAt = nowLabel();
    m_pendingHealthCheckResults.clear();
    m_pendingHealthCheckCount = m_profiles.size();
    m_healthChecks.clear();
    m_healthChecks.reserve(m_profiles.size());

    for (int i = 0; i < m_profiles.size(); ++i) {
        const Profile &existingProfile = m_profiles.at(i);
        const HealthCheck pendingCheck = buildHealthCheckForProfile(existingProfile, checkedAt);
        m_healthChecks.append(pendingCheck);

        if (pendingCheck.endpoint.isEmpty()) {
            m_pendingHealthCheckResults.insert(i, pendingCheck);
            continue;
        }

        QNetworkRequest request{QUrl(pendingCheck.endpoint)};
        request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("LoomDesktop/0.1"));
        request.setTransferTimeout(5000);

        QNetworkReply *reply = m_healthNetwork->get(request);
        m_pendingHealthChecks.insert(reply,
                                     {i,
                                      pendingCheck.profileName,
                                      pendingCheck.provider,
                                      pendingCheck.endpoint,
                                      pendingCheck.checkedAt,
                                      QDateTime::currentMSecsSinceEpoch()});
        connect(reply, &QNetworkReply::finished, this, [this, reply] {
            const HealthCheckRequest request = m_pendingHealthChecks.take(reply);
            if (request.index < 0) {
                reply->deleteLater();
                return;
            }
            HealthCheck check;
            check.profileName = request.profileName;
            check.provider = request.provider;
            check.endpoint = request.endpoint;
            check.checkedAt = request.checkedAt;
            check.latencyMs = static_cast<int>(std::max<qint64>(0, QDateTime::currentMSecsSinceEpoch() - request.startedAtMs));

            if (reply->error() != QNetworkReply::NoError) {
                check.status = QStringLiteral("WARN");
                check.indicator = QStringLiteral("error");
                check.description = reply->errorString();
                check.ok = false;
            } else {
                QJsonParseError error;
                const QJsonDocument document = QJsonDocument::fromJson(reply->readAll(), &error);
                const QJsonObject status = document.object().value(QStringLiteral("status")).toObject();
                check.indicator = status.value(QStringLiteral("indicator")).toString(QStringLiteral("unknown"));
                check.description = healthDescription(status.value(QStringLiteral("description")).toString(),
                                                      QStringLiteral("No status description"));
                check.ok = error.error == QJsonParseError::NoError && check.indicator == QStringLiteral("none");
                check.status = check.ok ? QStringLiteral("OK") : QStringLiteral("WARN");

                if (error.error != QJsonParseError::NoError) {
                    check.indicator = QStringLiteral("invalid_json");
                    check.description = error.errorString();
                    check.ok = false;
                    check.status = QStringLiteral("WARN");
                }
            }

            if (request.index >= 0) {
                m_pendingHealthCheckResults.insert(request.index, check);
            }
            reply->deleteLater();
            finalizeHealthChecks();
        });
    }

    setStatusMessage(QStringLiteral("Refreshing health checks for %1 profiles").arg(m_profiles.size()));
    emit healthChecksChanged();
    emit dashboardChanged();
    finalizeHealthChecks();
}

void ProfileManager::abortPendingModelOptions()
{
    if (!m_pendingModelOptionsReply) {
        return;
    }

    m_pendingModelOptionsReply->disconnect(this);
    m_pendingModelOptionsReply->abort();
    m_pendingModelOptionsReply->deleteLater();
    m_pendingModelOptionsReply = nullptr;
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

    const Profile previousProfile = *profile;
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
    if (!writeProfileToDisk(profile, previousProfile.folderName)) {
        *profile = previousProfile;
        return false;
    }

    if (profile->active && !m_codexRoutesThroughLoom && !applySelectedProfileToCodex()) {
        *profile = previousProfile;
        emitDataChanged();
        return false;
    }

    invalidateHealthChecks();
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
    if (trimmedApiKey != maskedApiKey(profile.apiKey)) {
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

void ProfileManager::shiftTokenDate(int days)
{
    if (!m_tokenSelectedDate.isValid()) {
        m_tokenSelectedDate = QDate::currentDate();
    }

    m_tokenSelectedDate = m_tokenSelectedDate.addDays(days);
    m_tokenRangeStartDate = m_tokenSelectedDate;
    m_tokenRangeEndDate = m_tokenSelectedDate;
    loadTokenUsage();
    setStatusMessage(QStringLiteral("Token usage loaded for %1").arg(m_tokenSelectedDate.toString(QStringLiteral("yyyy-MM-dd"))));
}

void ProfileManager::shiftTokenRangeStart(int days)
{
    normalizeTokenRange();
    m_tokenRangeStartDate = m_tokenRangeStartDate.addDays(days);
    normalizeTokenRange();
    loadTokenUsage();
    setStatusMessage(QStringLiteral("Token usage loaded for %1").arg(tokenSummary().value(QStringLiteral("date")).toString()));
}

void ProfileManager::shiftTokenRangeEnd(int days)
{
    normalizeTokenRange();
    m_tokenRangeEndDate = m_tokenRangeEndDate.addDays(days);
    normalizeTokenRange();
    loadTokenUsage();
    setStatusMessage(QStringLiteral("Token usage loaded for %1").arg(tokenSummary().value(QStringLiteral("date")).toString()));
}

void ProfileManager::setTokenDateRange(const QString &startDate, const QString &endDate)
{
    const QDate parsedStart = QDate::fromString(startDate, QStringLiteral("yyyy-MM-dd"));
    const QDate parsedEnd = QDate::fromString(endDate, QStringLiteral("yyyy-MM-dd"));
    if (parsedStart.isValid()) {
        m_tokenRangeStartDate = parsedStart;
    }
    if (parsedEnd.isValid()) {
        m_tokenRangeEndDate = parsedEnd;
    }
    normalizeTokenRange();
    loadTokenUsage();
    setStatusMessage(QStringLiteral("Token usage loaded for %1").arg(tokenSummary().value(QStringLiteral("date")).toString()));
}

void ProfileManager::setTokenRecentRange(int days)
{
    const int normalizedDays = std::max(1, days);
    m_tokenRangeEndDate = QDate::currentDate();
    m_tokenRangeStartDate = m_tokenRangeEndDate.addDays(-(normalizedDays - 1));
    normalizeTokenRange();
    loadTokenUsage();
    setStatusMessage(QStringLiteral("Token usage loaded for %1").arg(tokenSummary().value(QStringLiteral("date")).toString()));
}

void ProfileManager::refreshTokenUsage()
{
    loadTokenUsage();
    setStatusMessage(QStringLiteral("Token usage refreshed"));
}

QVariantMap ProfileManager::healthCheckToMap(const HealthCheck &check) const
{
    QVariantMap map;
    map.insert(QStringLiteral("profile"), check.profileName);
    map.insert(QStringLiteral("provider"), check.provider);
    map.insert(QStringLiteral("endpoint"), check.endpoint.isEmpty() ? QStringLiteral("Not supported") : check.endpoint);
    map.insert(QStringLiteral("status"), check.status);
    map.insert(QStringLiteral("indicator"), check.indicator);
    map.insert(QStringLiteral("description"), check.description);
    map.insert(QStringLiteral("latency"), check.latencyMs > 0 ? QStringLiteral("%1ms").arg(check.latencyMs) : QStringLiteral("N/A"));
    map.insert(QStringLiteral("latencyValue"), check.latencyMs);
    map.insert(QStringLiteral("checkedAt"), check.checkedAt);
    map.insert(QStringLiteral("ok"), check.ok);
    return map;
}

ProfileManager::HealthCheck ProfileManager::buildHealthCheckForProfile(const Profile &profile, const QString &checkedAt) const
{
    const QString providerKey = normalizedProviderKey(profile.modelProvider, profile.baseUrl);
    const QString endpoint = providerStatusEndpoint(providerKey);
    const QString provider = providerLabel(providerKey, profile.modelProvider);
    if (endpoint.isEmpty()) {
        return {profile.name,
                provider,
                QString(),
                QStringLiteral("WARN"),
                QStringLiteral("unsupported"),
                QStringLiteral("No provider status endpoint configured"),
                0,
                checkedAt,
                false};
    }

    return {profile.name,
            provider,
            endpoint,
            QStringLiteral("CHECKING"),
            QStringLiteral("pending"),
            QStringLiteral("Checking provider status"),
            0,
            checkedAt,
            false};
}

void ProfileManager::abortPendingHealthChecks()
{
    const QList<QNetworkReply *> replies = m_pendingHealthChecks.keys();
    for (QNetworkReply *reply : replies) {
        if (!reply) {
            continue;
        }
        reply->disconnect(this);
        reply->abort();
        reply->deleteLater();
    }

    m_pendingHealthChecks.clear();
    m_pendingHealthCheckResults.clear();
    m_pendingHealthCheckCount = 0;
}

void ProfileManager::finalizeHealthChecks()
{
    if (m_pendingHealthCheckResults.size() < m_pendingHealthCheckCount || !m_pendingHealthChecks.isEmpty()) {
        return;
    }

    QVector<HealthCheck> checks;
    checks.reserve(m_pendingHealthCheckResults.size());
    for (auto it = m_pendingHealthCheckResults.cbegin(); it != m_pendingHealthCheckResults.cend(); ++it) {
        checks.append(it.value());
    }

    m_healthChecks = checks;
    m_pendingHealthCheckResults.clear();
    m_pendingHealthCheckCount = 0;
    setStatusMessage(QStringLiteral("Health checks refreshed for %1 profiles").arg(m_healthChecks.size()));
    emit healthChecksChanged();
    emit dashboardChanged();
}

bool ProfileManager::applySelectedProfileToCodex()
{
    const Profile *profile = selectedProfile();
    if (!profile) {
        return false;
    }

    return applyProfileToCodex(*profile);
}

bool ProfileManager::applyProfileToCodex(const Profile &profile)
{
    const QDir sourceDir(profileRootDir().filePath(profile.folderName));
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

bool ProfileManager::writeLoomProxyConfigurationToCodex(const Profile &profile, const QString &loomBaseUrl)
{
    QString baseUrl = loomBaseUrl.trimmed();
    if (baseUrl.isEmpty()) {
        setStatusMessage(QStringLiteral("Loom proxy URL is required"));
        return false;
    }
    while (baseUrl.endsWith(QLatin1Char('/'))) {
        baseUrl.chop(1);
    }

    QDir codexDir(QDir::homePath() + QStringLiteral("/.codex"));
    if (!codexDir.exists() && !QDir().mkpath(codexDir.path())) {
        setStatusMessage(fileError(QStringLiteral("create"), codexDir.path()));
        return false;
    }

    const QString providerName = QStringLiteral("Loom");
    QJsonObject auth;
    QFile existingAuthFile(codexDir.filePath(QStringLiteral("auth.json")));
    if (existingAuthFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QJsonDocument document = QJsonDocument::fromJson(existingAuthFile.readAll());
        if (document.isObject()) {
            auth = document.object();
        }
    }
    auth.insert(QStringLiteral("auth_mode"), QStringLiteral("apikey"));
    if (profile.apiKey.isEmpty()) {
        auth.remove(QStringLiteral("OPENAI_API_KEY"));
    } else {
        auth.insert(QStringLiteral("OPENAI_API_KEY"), profile.apiKey);
    }

    const auto writeTextFile = [this](const QString &path, const QString &content) {
        QSaveFile file(path);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            setStatusMessage(fileError(QStringLiteral("write"), file.fileName()));
            return false;
        }

        const QByteArray data = content.toUtf8();
        if (file.write(data) != data.size() || !file.commit()) {
            setStatusMessage(fileError(QStringLiteral("write"), file.fileName()));
            return false;
        }
        return true;
    };

    const QString envPath = codexDir.filePath(QStringLiteral(".env"));
    const QString configPath = codexDir.filePath(QStringLiteral("config.toml"));
    const QString envContent = mergedEnvFile(readTextFile(envPath),
                                             {{QStringLiteral("OPENAI_API_KEY"), profile.apiKey.isEmpty() ? QString() : envValue(profile.apiKey)},
                                              {QStringLiteral("HTTP_PROXY"), profile.httpProxy.isEmpty() ? QString() : envValue(profile.httpProxy)},
                                              {QStringLiteral("HTTPS_PROXY"), profile.httpsProxy.isEmpty() ? QString() : envValue(profile.httpsProxy)}});
    const QString configContent = mergedLoomToml(readTextFile(configPath),
                                                 providerName,
                                                 baseUrl,
                                                 profile.model,
                                                 profile.reasoningEffort,
                                                 profile.disableResponseStorage,
                                                 profile.wireApi,
                                                 profile.requiresOpenAiAuth);

    if (!writeTextFile(envPath, envContent)
        || !writeTextFile(configPath, configContent)) {
        return false;
    }

    QSaveFile authFile(codexDir.filePath(QStringLiteral("auth.json")));
    if (!authFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        setStatusMessage(fileError(QStringLiteral("write"), authFile.fileName()));
        return false;
    }
    authFile.write(QJsonDocument(auth).toJson(QJsonDocument::Indented));
    if (!authFile.commit()) {
        setStatusMessage(fileError(QStringLiteral("write"), authFile.fileName()));
        return false;
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

QDir ProfileManager::codexSessionsRootDir() const
{
    return QDir(QDir::homePath() + QStringLiteral("/.codex/sessions"));
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

void ProfileManager::loadTodayTokenUsage()
{
    const QDate today = QDate::currentDate();
    qint64 contextWindow = 0;
    QString lastUpdated;
    const QVector<TokenSession> sessions = readTokenSessionsForDate(today, &m_tokenTodayTotals, &contextWindow, &lastUpdated);
    m_tokenTodaySessionCount = static_cast<int>(sessions.size());

    if (m_tokenSelectedDate == today) {
        m_tokenSessions = sessions;
        m_tokenSelectedTotals = m_tokenTodayTotals;
        m_tokenSelectedContextWindow = contextWindow;
        m_tokenLastUpdated = lastUpdated.isEmpty() ? QString() : displayDateTime(lastUpdated);
        m_tokenSessionsPath = codexSessionsRootDir().filePath(m_tokenSelectedDate.toString(QStringLiteral("yyyy/MM/dd")));
    }

    emit tokenUsageChanged();
    emit dashboardChanged();
}

void ProfileManager::normalizeTokenRange()
{
    const QDate today = QDate::currentDate();
    if (!m_tokenRangeStartDate.isValid()) {
        m_tokenRangeStartDate = m_tokenSelectedDate.isValid() ? m_tokenSelectedDate : today;
    }
    if (!m_tokenRangeEndDate.isValid()) {
        m_tokenRangeEndDate = m_tokenRangeStartDate;
    }
    if (m_tokenRangeStartDate > m_tokenRangeEndDate) {
        std::swap(m_tokenRangeStartDate, m_tokenRangeEndDate);
    }
    m_tokenSelectedDate = m_tokenRangeEndDate;
}

void ProfileManager::loadTokenUsage()
{
    normalizeTokenRange();

    m_tokenDailySeries.clear();
    m_tokenSessions.clear();
    m_tokenSelectedTotals = TokenTotals();
    m_tokenSelectedContextWindow = 0;
    m_tokenLastUpdated.clear();

    const QDate today = QDate::currentDate();
    bool todayLoaded = false;
    const bool hourlySeries = m_tokenRangeStartDate == m_tokenRangeEndDate;
    QString lastUpdatedIso;
    for (QDate date = m_tokenRangeStartDate; date <= m_tokenRangeEndDate; date = date.addDays(1)) {
        TokenTotals dayTotals;
        qint64 contextWindow = 0;
        QString dayLastUpdated;
        const QVector<TokenSession> sessions = readTokenSessionsForDate(date, &dayTotals, &contextWindow, &dayLastUpdated);

        if (hourlySeries) {
            QVector<qint64> hourlyTokens(24);
            QVector<int> hourlySessions(24);
            for (const TokenSession &session : sessions) {
                bool countedSession = false;
                for (int hour = 0; hour < session.hourlyTokens.size() && hour < 24; ++hour) {
                    if (session.hourlyTokens.at(hour) <= 0) {
                        continue;
                    }

                    hourlyTokens[hour] += session.hourlyTokens.at(hour);
                    ++hourlySessions[hour];
                    countedSession = true;
                }

                if (!countedSession && session.totals.totalTokens > 0) {
                    const QString timestamp = session.lastUpdatedAt.isEmpty() ? session.startedAt : session.lastUpdatedAt;
                    const int hour = std::clamp(timestampHour(timestamp), 0, 23);
                    hourlyTokens[hour] += session.totals.totalTokens;
                    ++hourlySessions[hour];
                }
            }
            for (int hour = 0; hour < 24; ++hour) {
                m_tokenDailySeries.append({date, hourlyTokens[hour], hourlySessions[hour], hour});
            }
        } else {
            m_tokenDailySeries.append({date, dayTotals.totalTokens, static_cast<int>(sessions.size())});
        }
        m_tokenSelectedTotals.inputTokens += dayTotals.inputTokens;
        m_tokenSelectedTotals.cachedInputTokens += dayTotals.cachedInputTokens;
        m_tokenSelectedTotals.outputTokens += dayTotals.outputTokens;
        m_tokenSelectedTotals.reasoningOutputTokens += dayTotals.reasoningOutputTokens;
        m_tokenSelectedTotals.totalTokens += dayTotals.totalTokens;
        m_tokenSelectedContextWindow = std::max(m_tokenSelectedContextWindow, contextWindow);
        if (!dayLastUpdated.isEmpty() && (lastUpdatedIso.isEmpty() || dayLastUpdated > lastUpdatedIso)) {
            lastUpdatedIso = dayLastUpdated;
        }
        if (date == today) {
            m_tokenTodayTotals = dayTotals;
            m_tokenTodaySessionCount = sessions.size();
            todayLoaded = true;
        }
        m_tokenSessions += sessions;
    }

    if (!todayLoaded) {
        qint64 todayContextWindow = 0;
        QString todayLastUpdated;
        const QVector<TokenSession> todaySessions =
            readTokenSessionsForDate(today, &m_tokenTodayTotals, &todayContextWindow, &todayLastUpdated);
        m_tokenTodaySessionCount = static_cast<int>(todaySessions.size());
    }

    std::sort(m_tokenSessions.begin(), m_tokenSessions.end(), [](const TokenSession &left, const TokenSession &right) {
        return left.startedAt > right.startedAt;
    });

    m_tokenLastUpdated = lastUpdatedIso.isEmpty() ? QString() : displayDateTime(lastUpdatedIso);

    const QDir sessionsRoot = codexSessionsRootDir();
    m_tokenSessionsPath = m_tokenRangeStartDate == m_tokenRangeEndDate
                              ? sessionsRoot.filePath(m_tokenRangeStartDate.toString(QStringLiteral("yyyy/MM/dd")))
                              : QStringLiteral("%1 - %2")
                                    .arg(sessionsRoot.filePath(m_tokenRangeStartDate.toString(QStringLiteral("yyyy/MM/dd"))),
                                         sessionsRoot.filePath(m_tokenRangeEndDate.toString(QStringLiteral("yyyy/MM/dd"))));

    emit tokenUsageChanged();
    emit dashboardChanged();
}

QVector<ProfileManager::TokenSession> ProfileManager::readTokenSessionsForDate(const QDate &date,
                                                                               TokenTotals *totals,
                                                                               qint64 *contextWindow,
                                                                               QString *lastUpdated) const
{
    if (totals) {
        *totals = TokenTotals();
    }
    if (contextWindow) {
        *contextWindow = 0;
    }
    if (lastUpdated) {
        lastUpdated->clear();
    }

    QVector<TokenSession> sessions;
    if (!date.isValid()) {
        return sessions;
    }

    const QDir dayDir(codexSessionsRootDir().filePath(date.toString(QStringLiteral("yyyy/MM/dd"))));
    if (!dayDir.exists()) {
        return sessions;
    }

    const QFileInfoList entries = dayDir.entryInfoList({QStringLiteral("*.jsonl")}, QDir::Files, QDir::Name);
    sessions.reserve(entries.size());
    for (const QFileInfo &entry : entries) {
        TokenSession session;
        if (!readTokenSessionFile(entry.absoluteFilePath(), &session)) {
            continue;
        }

        if (totals) {
            totals->inputTokens += session.totals.inputTokens;
            totals->cachedInputTokens += session.totals.cachedInputTokens;
            totals->outputTokens += session.totals.outputTokens;
            totals->reasoningOutputTokens += session.totals.reasoningOutputTokens;
            totals->totalTokens += session.totals.totalTokens;
        }
        if (contextWindow && session.contextWindow > *contextWindow) {
            *contextWindow = session.contextWindow;
        }
        if (lastUpdated && !session.lastUpdatedAt.isEmpty()
            && (lastUpdated->isEmpty() || session.lastUpdatedAt > *lastUpdated)) {
            *lastUpdated = session.lastUpdatedAt;
        }
        sessions.append(session);
    }

    std::sort(sessions.begin(), sessions.end(), [](const TokenSession &left, const TokenSession &right) {
        return left.startedAt > right.startedAt;
    });

    return sessions;
}

bool ProfileManager::readTokenSessionFile(const QString &path, TokenSession *session) const
{
    if (!session) {
        return false;
    }

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }

    TokenSession result;
    result.filePath = path;
    result.fileName = QFileInfo(path).fileName();
    result.hourlyTokens = QVector<qint64>(24);

    bool hasTotals = false;
    TokenTotals previousTotals;
    QTextStream stream(&file);
    while (!stream.atEnd()) {
        const QByteArray line = stream.readLine().toUtf8();
        if (line.trimmed().isEmpty()) {
            continue;
        }

        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(line, &error);
        if (error.error != QJsonParseError::NoError || !document.isObject()) {
            continue;
        }

        const QJsonObject object = document.object();
        const QString type = object.value(QStringLiteral("type")).toString();
        const QString timestamp = object.value(QStringLiteral("timestamp")).toString();

        if (type == QStringLiteral("session_meta")) {
            const QJsonObject payload = object.value(QStringLiteral("payload")).toObject();
            result.id = payload.value(QStringLiteral("id")).toString();
            result.cwd = payload.value(QStringLiteral("cwd")).toString();
            result.originator = payload.value(QStringLiteral("originator")).toString();
            result.source = payload.value(QStringLiteral("source")).toString();
            result.modelProvider = payload.value(QStringLiteral("model_provider")).toString();
            result.startedAt = payload.value(QStringLiteral("timestamp")).toString(timestamp);
            continue;
        }

        if (type != QStringLiteral("event_msg")) {
            continue;
        }

        const QJsonObject payload = object.value(QStringLiteral("payload")).toObject();
        if (payload.value(QStringLiteral("type")).toString() == QStringLiteral("user_message")) {
            ++result.turnCount;
            continue;
        }
        if (payload.value(QStringLiteral("type")).toString() != QStringLiteral("token_count")) {
            continue;
        }

        const QJsonObject info = payload.value(QStringLiteral("info")).toObject();
        if (info.isEmpty()) {
            continue;
        }

        const QJsonObject totalUsage = info.value(QStringLiteral("total_token_usage")).toObject();
        if (totalUsage.isEmpty()) {
            continue;
        }

        const TokenTotals currentTotals = readTokenTotals(totalUsage);
        const int hour = std::clamp(timestampHour(timestamp), 0, 23);
        const qint64 tokenDelta = hasTotals
                                      ? std::max<qint64>(0, currentTotals.totalTokens - previousTotals.totalTokens)
                                      : currentTotals.totalTokens;
        result.hourlyTokens[hour] += tokenDelta;
        result.totals = currentTotals;
        result.contextWindow = jsonInteger(info, QStringLiteral("model_context_window"));
        previousTotals = currentTotals;

        const QJsonObject rateLimits = payload.value(QStringLiteral("rate_limits")).toObject();
        result.limitId = rateLimits.value(QStringLiteral("limit_id")).toString();
        result.planType = rateLimits.value(QStringLiteral("plan_type")).toString();
        result.lastUpdatedAt = timestamp;
        hasTotals = true;
    }

    if (!hasTotals) {
        return false;
    }

    if (result.startedAt.isEmpty()) {
        result.startedAt = result.lastUpdatedAt;
    }
    if (result.id.isEmpty()) {
        result.id = result.fileName;
    }

    *session = result;
    return true;
}

QVariantMap ProfileManager::tokenDayToMap(const TokenDay &day) const
{
    QVariantMap map;
    if (day.hour >= 0) {
        map.insert(QStringLiteral("date"),
                   QStringLiteral("%1 %2:00").arg(day.date.toString(QStringLiteral("yyyy-MM-dd")), QStringLiteral("%1").arg(day.hour, 2, 10, QLatin1Char('0'))));
        map.insert(QStringLiteral("label"), QStringLiteral("%1:00").arg(day.hour, 2, 10, QLatin1Char('0')));
    } else {
        map.insert(QStringLiteral("date"), day.date.toString(QStringLiteral("yyyy-MM-dd")));
        map.insert(QStringLiteral("label"), day.date.toString(QStringLiteral("MM-dd")));
    }
    map.insert(QStringLiteral("tokens"), day.totalTokens);
    map.insert(QStringLiteral("sessions"), day.sessionCount);
    return map;
}

ProfileManager::TokenTotals ProfileManager::readTokenTotals(const QJsonObject &object) const
{
    TokenTotals totals;
    totals.inputTokens = jsonInteger(object, QStringLiteral("input_tokens"));
    totals.cachedInputTokens = jsonInteger(object, QStringLiteral("cached_input_tokens"));
    totals.outputTokens = jsonInteger(object, QStringLiteral("output_tokens"));
    totals.reasoningOutputTokens = jsonInteger(object, QStringLiteral("reasoning_output_tokens"));
    totals.totalTokens = jsonInteger(object, QStringLiteral("total_tokens"));
    return totals;
}

QVariantMap ProfileManager::tokenSessionToMap(const TokenSession &session) const
{
    QVariantMap map = tokenTotalsToMap(session.totals);
    map.insert(QStringLiteral("id"), session.id);
    map.insert(QStringLiteral("fileName"), session.fileName);
    map.insert(QStringLiteral("filePath"), session.filePath);
    map.insert(QStringLiteral("cwd"), session.cwd.isEmpty() ? QStringLiteral("-") : session.cwd);
    map.insert(QStringLiteral("originator"), session.originator.isEmpty() ? QStringLiteral("-") : session.originator);
    map.insert(QStringLiteral("source"), session.source.isEmpty() ? QStringLiteral("-") : session.source);
    map.insert(QStringLiteral("modelProvider"), session.modelProvider.isEmpty() ? QStringLiteral("-") : session.modelProvider);
    map.insert(QStringLiteral("startedAt"), displayDateTime(session.startedAt));
    map.insert(QStringLiteral("lastUpdatedAt"), displayDateTime(session.lastUpdatedAt));
    map.insert(QStringLiteral("limitId"), session.limitId.isEmpty() ? QStringLiteral("-") : session.limitId);
    map.insert(QStringLiteral("planType"), session.planType.isEmpty() ? QStringLiteral("-") : session.planType);
    map.insert(QStringLiteral("turnCount"), session.turnCount);
    map.insert(QStringLiteral("contextWindow"), session.contextWindow);
    return map;
}

QVariantMap ProfileManager::tokenTotalsToMap(const TokenTotals &totals) const
{
    QVariantMap map;
    map.insert(QStringLiteral("inputTokens"), totals.inputTokens);
    map.insert(QStringLiteral("cachedInputTokens"), totals.cachedInputTokens);
    map.insert(QStringLiteral("outputTokens"), totals.outputTokens);
    map.insert(QStringLiteral("reasoningOutputTokens"), totals.reasoningOutputTokens);
    map.insert(QStringLiteral("totalTokens"), totals.totalTokens);
    return map;
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

const ProfileManager::Profile *ProfileManager::activeProfile() const
{
    const auto activeIt = std::find_if(m_profiles.cbegin(), m_profiles.cend(), [](const Profile &profile) {
        return profile.active;
    });
    return activeIt == m_profiles.cend() ? selectedProfile() : &(*activeIt);
}

void ProfileManager::emitDataChanged()
{
    emit profilesChanged();
    emit currentProfileChanged();
    emit dashboardChanged();
}

void ProfileManager::invalidateHealthChecks()
{
    abortPendingHealthChecks();
    if (m_healthChecks.isEmpty()) {
        return;
    }

    m_healthChecks.clear();
    emit healthChecksChanged();
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

    const auto writeTextFile = [this](const QString &path, const QString &content) {
        QSaveFile file(path);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            setStatusMessage(fileError(QStringLiteral("write"), file.fileName()));
            return false;
        }

        const QByteArray data = content.toUtf8();
        if (file.write(data) != data.size() || !file.commit()) {
            setStatusMessage(fileError(QStringLiteral("write"), file.fileName()));
            return false;
        }
        return true;
    };

    QString envContent;
    if (!profile->apiKey.isEmpty()) {
        envContent += QStringLiteral("OPENAI_API_KEY=%1\n").arg(envValue(profile->apiKey));
    }
    if (!profile->httpProxy.isEmpty()) {
        envContent += QStringLiteral("HTTP_PROXY=%1\n").arg(envValue(profile->httpProxy));
    }
    if (!profile->httpsProxy.isEmpty()) {
        envContent += QStringLiteral("HTTPS_PROXY=%1\n").arg(envValue(profile->httpsProxy));
    }
    if (!writeTextFile(QDir(profilePath).filePath(QStringLiteral(".env")), envContent)) {
        return false;
    }

    QString configContent;
    configContent += QStringLiteral("model_provider = %1\n").arg(tomlString(profile->modelProvider));
    configContent += QStringLiteral("model = %1\n").arg(tomlString(profile->model));
    configContent += QStringLiteral("model_reasoning_effort = %1\n").arg(tomlString(profile->reasoningEffort));
    configContent += QStringLiteral("disable_response_storage = %1\n\n").arg(profile->disableResponseStorage ? QStringLiteral("true") : QStringLiteral("false"));
    configContent += QStringLiteral("[model_providers.%1]\n").arg(profile->modelProvider);
    configContent += QStringLiteral("name = %1\n").arg(tomlString(profile->modelProvider));
    configContent += QStringLiteral("base_url = %1\n").arg(tomlString(profile->baseUrl));
    configContent += QStringLiteral("wire_api = %1\n").arg(tomlString(profile->wireApi));
    configContent += QStringLiteral("requires_openai_auth = %1\n").arg(profile->requiresOpenAiAuth ? QStringLiteral("true") : QStringLiteral("false"));
    if (!writeTextFile(QDir(profilePath).filePath(QStringLiteral("config.toml")), configContent)) {
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
