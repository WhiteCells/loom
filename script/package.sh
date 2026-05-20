#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
system_name="$(uname -s)"

case "${system_name}" in
    Linux)
        exec "${script_dir}/package-linux.sh" "$@"
        ;;
    Darwin)
        exec "${script_dir}/package-macos.sh" "$@"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        if command -v pwsh >/dev/null 2>&1; then
            exec pwsh -NoProfile -ExecutionPolicy Bypass -File "${script_dir}/package-windows.ps1" "$@"
        fi
        exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${script_dir}/package-windows.ps1" "$@"
        ;;
    *)
        echo "Unsupported host platform: ${system_name}" >&2
        exit 1
        ;;
esac
