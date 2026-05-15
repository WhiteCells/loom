import requests

STATUS_URLS = {
    "openai": "https://status.openai.com/api/v2/status.json",
    "anthropic": "https://status.claude.com/api/v2/status.json",
}

def check_provider_status(provider):
    resp = requests.get(STATUS_URLS[provider], timeout=5)
    resp.raise_for_status()

    data = resp.json()
    indicator = data.get("status", {}).get("indicator")

    return {
        "provider": provider,
        "ok": indicator == "none",
        "indicator": indicator,
        "description": data.get("status", {}).get("description"),
    }

print(check_provider_status("openai"))
print(check_provider_status("anthropic"))
