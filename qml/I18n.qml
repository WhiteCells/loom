pragma Singleton

import QtQuick

QtObject {
    id: i18n

    property string language: "en"
    readonly property bool isChinese: language === "zh"

    function t(key) {
        var currentLanguage = language
        if (!key || currentLanguage !== "zh") {
            return key || ""
        }
        return zhCN[key] || key
    }

    function arg(pattern, value) {
        return String(pattern).replace("%1", value)
    }

    function arg2(pattern, first, second) {
        return String(pattern).replace("%1", first).replace("%2", second)
    }

    function status(message) {
        var currentLanguage = language
        if (!message || currentLanguage !== "zh") {
            return message || ""
        }

        var exact = zhCN[message]
        if (exact) {
            return exact
        }

        var match = String(message).match(/^Loaded (\d+) profiles$/)
        if (match) {
            return arg(t("Loaded %1 profiles"), match[1])
        }

        match = String(message).match(/^(.*) is now active$/)
        if (match) {
            return arg(t("%1 is now active"), match[1])
        }

        match = String(message).match(/^(.*) created$/)
        if (match) {
            return arg(t("%1 created"), match[1])
        }

        match = String(message).match(/^(.*) saved$/)
        if (match) {
            return arg(t("%1 saved"), match[1])
        }

        match = String(message).match(/^(.*) selected$/)
        if (match) {
            return arg(t("%1 selected"), match[1])
        }

        match = String(message).match(/^(.*) deleted$/)
        if (match) {
            return arg(t("%1 deleted"), match[1])
        }

        match = String(message).match(/^Editing (.*)$/)
        if (match) {
            return arg(t("Editing %1"), match[1])
        }

        match = String(message).match(/^Health check finished for (.*)$/)
        if (match) {
            return arg(t("Health check finished for %1"), match[1])
        }

        match = String(message).match(/^(.*) (.*) Configuration$/)
        if (match) {
            return arg2(t("%1 %2 Configuration"), match[1], match[2])
        }

        match = String(message).match(/^(\d+) of (\d+) checks healthy$/)
        if (match) {
            return arg2(t("%1 of %2 checks healthy"), match[1], match[2])
        }

        match = String(message).match(/^Last checked at (.*)$/)
        if (match) {
            return arg(t("Last checked at %1"), match[1])
        }

        match = String(message).match(/^Across (\d+) profiles$/)
        if (match) {
            return arg(t("Across %1 profiles"), match[1])
        }

        match = String(message).match(/^Across (\d+) sessions$/)
        if (match) {
            return arg(t("Across %1 sessions"), match[1])
        }

        match = String(message).match(/^Token usage loaded for (.*)$/)
        if (match) {
            return arg(t("Token usage loaded for %1"), match[1])
        }

        match = String(message).match(/^(\d+) days$/)
        if (match) {
            return arg(t("%1 days"), match[1])
        }

        match = String(message).match(/^Settings loaded from (.*)$/)
        if (match) {
            return arg(t("Settings loaded from %1"), match[1])
        }

        match = String(message).match(/^Settings saved to (.*)$/)
        if (match) {
            return arg(t("Settings saved to %1"), match[1])
        }

        return message
    }

    readonly property var zhCN: ({
        "Dashboard": "仪表盘",
        "Profiles": "配置",
        "Health Checks": "健康检查",
        "Token Usage": "Token 用量",
        "Settings": "设置",
        "Current: ": "当前：",
        "LOOM": "LOOM",

        "Overview": "概览",
        "Active Profile": "当前配置",
        "System Health": "系统健康",
        "Token Usage (Today)": "今日 Token 用量",
        "Recent Health Checks": "最近健康检查",
        "Profile": "配置",
        "Endpoint": "端点",
        "Status": "状态",
        "Latency": "延迟",
        "Checked At": "检查时间",
        "Run Health Check": "运行健康检查",
        "Usage Today": "今日用量",
        "Tracked Profiles": "已跟踪配置",
        "Health": "健康",
        "%1 active": "%1 已启用",
        "Total Tokens": "总 Token",
        "Input Tokens": "输入 Token",
        "Output Tokens": "输出 Token",
        "Context Window": "上下文窗口",
        "Range Usage": "区间总用量",
        "%1 sessions": "%1 个会话",
        "%1 cached": "%1 缓存",
        "%1 reasoning": "%1 推理",
        "Daily Flow": "每日流量",
        "Hourly Flow": "小时流量",
        "Cached": "缓存",
        "Reasoning": "推理",
        "Updated": "更新",
        "Date Range": "时间区间",
        "Start Date": "开始日期",
        "End Date": "结束日期",
        "Last 7 Days": "近一周",
        "Last 30 Days": "近一个月",
        "Year": "年份",
        "Month": "月份",
        "Confirm": "确认",
        "Previous Year": "上一年",
        "Next Year": "下一年",
        "Previous Month": "上个月",
        "Next Month": "下个月",
        "Sun": "日",
        "Mon": "一",
        "Tue": "二",
        "Wed": "三",
        "Thu": "四",
        "Fri": "五",
        "Sat": "六",
        "%1 days": "%1 天",
        "Refresh": "刷新",
        "Today": "今天",
        "Yesterday": "昨天",
        "Tomorrow": "明天",
        "Token usage refreshed": "Token 用量已刷新",
        "Token usage loaded for %1": "已加载 %1 的 Token 用量",
        "Across %1 sessions": "跨 %1 个会话",

        "SOFTWARE": "软件",
        "Appearance": "外观",
        "Behavior": "行为",
        "Storage & Privacy": "存储与隐私",
        "Startup, restore, and confirmation preferences.": "启动、恢复和确认偏好。",
        "Local data, backups, and secret visibility.": "本地数据、备份和密钥可见性。",
        "Theme, density, and accent preferences.": "主题、密度和强调色偏好。",
        "Color Theme": "色彩主题",
        "Dark": "深色",
        "Light": "浅色",
        "Interface Density": "界面密度",
        "Comfortable": "舒适",
        "Compact": "紧凑",
        "Accent Color": "强调色",
        "Blue": "蓝色",
        "Green": "绿色",
        "Amber": "琥珀色",
        "Language": "语言",
        "English": "英文",
        "Chinese": "中文",
        "Launch at Login": "登录时启动",
        "On": "开",
        "Off": "关",
        "Restore Last Section": "恢复上次页面",
        "Confirm Profile Deletion": "删除配置需确认",
        "Required": "必需",
        "Health Check on Activate": "启用配置时健康检查",
        "Data Location": "数据位置",
        "Reveal": "显示",
        "Mask Secrets": "隐藏密钥",
        "Local Backups": "本地备份",
        "Backup Retention": "备份保留",
        "7 days": "7 天",
        "14 days": "14 天",
        "30 days": "30 天",
        "Clear Cache": "清除缓存",
        "Save Settings": "保存设置",
        "Settings are local": "设置保存在本地",
        "Dark theme enabled": "已启用深色主题",
        "Light theme enabled": "已启用浅色主题",
        "%1 density enabled": "已启用%1密度",
        "%1 accent enabled": "已启用%1强调色",
        "Language changed": "语言已切换",
        "Launch at login enabled": "已启用登录时启动",
        "Launch at login disabled": "已关闭登录时启动",
        "Last section restore enabled": "已启用恢复上次页面",
        "Last section restore disabled": "已关闭恢复上次页面",
        "Health check on activate enabled": "已启用激活时健康检查",
        "Health check on activate disabled": "已关闭激活时健康检查",
        "Secret masking enabled": "已启用密钥隐藏",
        "Secret masking disabled": "已关闭密钥隐藏",
        "Local backups enabled": "已启用本地备份",
        "Local backups disabled": "已关闭本地备份",
        "%1 backup retention enabled": "备份保留已设为%1",
        "Cache cleared": "缓存已清除",

        "Create Profile": "创建配置",
        "Search profiles": "搜索配置",
        "No profiles found": "未找到配置",
        "Activate": "启用",
        "Edit": "编辑",
        "Delete": "删除",
        "Active": "已启用",
        "Runtime": "运行时",
        "Currently active": "当前启用",
        "Ready to activate": "可启用",
        "Model": "模型",
        "Effort": "推理强度",
        "Reasoning intensity": "推理强度",
        "Connection & Security": "连接与安全",
        "Key saved": "密钥已保存",
        "No key": "无密钥",
        "Base URL": "基础 URL",
        "Host: ": "主机：",
        "API Key": "API Key",
        "Not configured": "未配置",
        "Secret": "密钥",
        "Proxy Routing": "代理路由",
        "Proxy on": "代理开启",
        "Direct": "直连",
        "HTTP Proxy": "HTTP 代理",
        "HTTPS Proxy": "HTTPS 代理",
        "Disabled": "已禁用",
        "Enabled": "已启用",
        "Create Profile": "创建配置",
        "Edit Profile": "编辑配置",
        "Close": "关闭",
        "Identity": "身份",
        "Name the profile and choose its model provider.": "命名配置并选择模型提供商。",
        "Profile Name": "配置名称",
        "Model Provider": "模型提供商",
        "Custom": "自定义",
        "Codex Runtime": "Codex 运行时",
        "Provider table options written into config.toml.": "写入 config.toml 的提供商表选项。",
        "Wire API": "Wire API",
        "Disable Response Storage": "禁用响应存储",
        "Requires OpenAI Auth": "需要 OpenAI 认证",
        "Connection": "连接",
        "Endpoint and key used to load available models.": "用于加载可用模型的端点和密钥。",
        "Model & Effort": "模型与推理强度",
        "Load from Endpoint": "从端点加载",
        "Reasoning Effort": "推理强度",
        "Proxy": "代理",
        "Optional local routing applied after the provider and model are selected.": "选择提供商和模型后应用的本地可选路由。",
        "Cancel": "取消",
        "Save Profile": "保存配置",
        "Delete Profile?": "删除配置？",
        "This will remove the selected configuration from Loom.": "将从 Loom 中移除所选配置。",
        "This action cannot be undone.": "此操作无法撤销。",
        "Selected Profile": "所选配置",
        "Profile name is required.": "需要填写配置名称。",
        "Profile name cannot contain / or \\.": "配置名称不能包含 / 或 \\。",
        "Enter an endpoint to load model options.": "输入端点以加载模型选项。",
        "Endpoint required before loading model options.": "加载模型选项前需要填写端点。",
        "Endpoint changed. Load options before choosing a model.": "端点已变更，请先加载选项再选择模型。",
        "%1 model options loaded": "已加载 %1 模型选项",
        "# No proxy configured": "# 未配置代理",

        "Show": "显示",
        "Hide": "隐藏",

        "No Profile Selected": "未选择配置",
        "Create a profile to begin": "创建配置以开始",
        "New agent configuration": "新代理配置",
        "%1 %2 Configuration": "%1 %2 配置",
        "Loaded %1 profiles": "已加载 %1 个配置",
        "All Systems Go": "全部正常",
        "Needs Attention": "需要关注",
        "%1 of %2 checks healthy": "%1 / %2 项检查正常",
        "No checks yet": "尚未检查",
        "Last checked at %1": "上次检查于 %1",
        "Across %1 profiles": "共 %1 个配置",
        "%1 is now active": "%1 已启用",
        "Profile name is required": "需要填写配置名称",
        "Profile name is required and cannot contain / or \\": "需要填写配置名称，且不能包含 / 或 \\",
        "%1 created": "%1 已创建",
        "At least one profile must remain": "至少需要保留一个配置",
        "%1 deleted": "%1 已删除",
        "Editing %1": "正在编辑 %1",
        "Health check finished for %1": "%1 的健康检查已完成",
        "%1 saved": "%1 已保存",
        "%1 selected": "已选择 %1",
        "Settings loaded from %1": "已从 %1 加载设置",
        "Settings saved to %1": "设置已保存到 %1"
    })
}
