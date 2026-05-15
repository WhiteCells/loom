#include "profilemanager.h"

#include <QDateTime>
#include <QRandomGenerator>

#include <algorithm>
#include <numeric>

namespace {
QString nowLabel()
{
    return QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss"));
}
}

ProfileManager::ProfileManager(QObject *parent)
    : QObject(parent)
    , m_activeSection(QStringLiteral("Dashboard"))
{
    m_profiles = {
        {QStringLiteral("openai-default"),
         QStringLiteral("Codex"),
         QStringLiteral("Default OpenAI Codex Configuration"),
         QStringLiteral("OpenAI"),
         QStringLiteral("gpt-5.5"),
         QStringLiteral("xhigh"),
         QStringLiteral("https://api.openai.com/v1"),
         QStringLiteral("sk-live-default-demo-key"),
         QStringLiteral("http://127.0.0.1:2080"),
         QStringLiteral("http://127.0.0.1:2080"),
         128450,
         300000,
         true},
        {QStringLiteral("openai-proxy"),
         QStringLiteral("Codex"),
         QStringLiteral("OpenAI Codex via local proxy"),
         QStringLiteral("OpenAI"),
         QStringLiteral("gpt-5.4"),
         QStringLiteral("high"),
         QStringLiteral("https://api.jucode.cn/v1"),
         QStringLiteral("sk-proxy-demo-key"),
         QStringLiteral("http://127.0.0.1:7890"),
         QStringLiteral("http://127.0.0.1:7890"),
         87320,
         250000,
         false},
        {QStringLiteral("claude-default"),
         QStringLiteral("Claude"),
         QStringLiteral("Default Claude Code Configuration"),
         QStringLiteral("Anthropic"),
         QStringLiteral("claude-sonnet-4.5"),
         QStringLiteral("high"),
         QStringLiteral("https://api.anthropic.com"),
         QStringLiteral("sk-ant-demo-key"),
         QString(),
         QString(),
         54320,
         200000,
         false},
    };

    m_healthChecks = {
        {QStringLiteral("openai-default"), QStringLiteral("api.openai.com/v1/models"), QStringLiteral("OK"), 328, nowLabel()},
        {QStringLiteral("openai-proxy"), QStringLiteral("api.jucode.cn/v1/models"), QStringLiteral("OK"), 214, nowLabel()},
        {QStringLiteral("claude-default"), QStringLiteral("api.anthropic.com/v1/models"), QStringLiteral("WARN"), 612, nowLabel()},
    };

    setStatusMessage(QStringLiteral("Ready"));
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
        return {};
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

void ProfileManager::activateSelectedProfile()
{
    if (!selectedProfile()) {
        return;
    }

    for (int i = 0; i < m_profiles.size(); ++i) {
        m_profiles[i].active = (i == m_selectedProfileIndex);
    }

    setStatusMessage(QStringLiteral("%1 is now active").arg(m_profiles.at(m_selectedProfileIndex).name));
    emitDataChanged();
}

void ProfileManager::createProfile()
{
    const int nextNumber = m_profiles.size() + 1;
    Profile profile = m_profiles.isEmpty() ? Profile{} : m_profiles.first();
    profile.name = QStringLiteral("new-profile-%1").arg(nextNumber);
    profile.description = QStringLiteral("New agent configuration");
    profile.active = false;
    profile.todayTokens = 0;
    m_profiles.append(profile);
    m_selectedProfileIndex = m_profiles.size() - 1;

    setStatusMessage(QStringLiteral("%1 created").arg(profile.name));
    emit selectedProfileIndexChanged();
    emitDataChanged();
    setActiveSection(QStringLiteral("Settings"));
}

void ProfileManager::deleteSelectedProfile()
{
    if (!selectedProfile() || m_profiles.size() <= 1) {
        setStatusMessage(QStringLiteral("At least one profile must remain"));
        return;
    }

    const QString removedName = m_profiles.at(m_selectedProfileIndex).name;
    const bool removedActive = m_profiles.at(m_selectedProfileIndex).active;
    m_profiles.removeAt(m_selectedProfileIndex);

    if (m_selectedProfileIndex >= m_profiles.size()) {
        m_selectedProfileIndex = m_profiles.size() - 1;
    }

    if (removedActive && !m_profiles.isEmpty()) {
        m_profiles[m_selectedProfileIndex].active = true;
    }

    setStatusMessage(QStringLiteral("%1 deleted").arg(removedName));
    emit selectedProfileIndexChanged();
    emitDataChanged();
}

void ProfileManager::editSelectedProfile()
{
    if (!selectedProfile()) {
        return;
    }

    setStatusMessage(QStringLiteral("Editing %1").arg(selectedProfile()->name));
    setActiveSection(QStringLiteral("Settings"));
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

void ProfileManager::saveConfiguration(const QString &name,
                                       const QString &agentType,
                                       const QString &modelProvider,
                                       const QString &model,
                                       const QString &reasoningEffort,
                                       const QString &baseUrl,
                                       const QString &apiKey,
                                       const QString &httpProxy,
                                       const QString &httpsProxy)
{
    Profile *profile = selectedProfile();
    if (!profile) {
        return;
    }

    const QString trimmedName = name.trimmed();
    if (!trimmedName.isEmpty()) {
        profile->name = trimmedName;
    }
    profile->agentType = agentType.trimmed().isEmpty() ? profile->agentType : agentType.trimmed();
    profile->modelProvider = modelProvider.trimmed().isEmpty() ? profile->modelProvider : modelProvider.trimmed();
    profile->model = model.trimmed().isEmpty() ? profile->model : model.trimmed();
    profile->reasoningEffort = reasoningEffort.trimmed().isEmpty() ? profile->reasoningEffort : reasoningEffort.trimmed();
    profile->baseUrl = baseUrl.trimmed();
    profile->httpProxy = httpProxy.trimmed();
    profile->httpsProxy = httpsProxy.trimmed();

    const QString trimmedApiKey = apiKey.trimmed();
    if (!trimmedApiKey.isEmpty() && trimmedApiKey != maskedApiKey(profile->apiKey)) {
        profile->apiKey = trimmedApiKey;
    }

    profile->description = QStringLiteral("%1 %2 Configuration").arg(profile->modelProvider, profile->agentType);

    setStatusMessage(QStringLiteral("%1 saved").arg(profile->name));
    emitDataChanged();
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
    map.insert(QStringLiteral("todayTokens"), profile.todayTokens);
    map.insert(QStringLiteral("monthlyLimit"), profile.monthlyLimit);
    map.insert(QStringLiteral("active"), profile.active);
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
