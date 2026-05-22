#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "${script_dir}/../../.." && pwd)"
dist_dir="${DIST_DIR:-${project_root}/dist/archlinux}"
work_dir="${BUILD_DIR:-${project_root}/build/archlinux-package}"
pkgname="loom-desktop"
clean=0

usage() {
    cat <<EOF
Usage: script/linux/archlinux/build-package.sh [options]

Options:
  --dist-dir <path>     Output directory, default: dist/archlinux
  --build-dir <path>    makepkg work directory, default: build/archlinux-package
  --clean               Remove the Arch package build directory first
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dist-dir)
            dist_dir="$2"
            shift 2
            ;;
        --build-dir)
            work_dir="$2"
            shift 2
            ;;
        --clean)
            clean=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "build-package.sh must be run on Linux." >&2
    exit 1
fi

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "arch" && " ${ID_LIKE:-} " != *" arch "* ]]; then
        echo "Warning: makepkg is normally available on Arch Linux or Arch-based distributions." >&2
    fi
fi

command -v makepkg >/dev/null 2>&1 || {
    echo "makepkg is required. Install pacman/contrib tools on Arch Linux first." >&2
    exit 1
}

command -v git >/dev/null 2>&1 || {
    echo "git is required to list source files." >&2
    exit 1
}

command -v tar >/dev/null 2>&1 || {
    echo "tar is required to create the source archive." >&2
    exit 1
}

version="$(sed -nE 's/^project\(LoomDesktop VERSION ([^ )]+).*/\1/p' "${project_root}/CMakeLists.txt" | head -n 1)"
if [[ -z "${version}" ]]; then
    echo "Unable to read project version from CMakeLists.txt." >&2
    exit 1
fi

if [[ "${clean}" -eq 1 ]]; then
    rm -rf "${work_dir}"
fi

mkdir -p "${work_dir}" "${dist_dir}"

cp "${script_dir}/PKGBUILD" "${work_dir}/PKGBUILD"
cp "${script_dir}/loom.desktop" "${work_dir}/loom.desktop"
sed -i "s/^pkgver=.*/pkgver=${version}/" "${work_dir}/PKGBUILD"

source_archive="${work_dir}/${pkgname}-${version}.tar.gz"
git -C "${project_root}" ls-files --cached --others --exclude-standard -z \
    | tar -C "${project_root}" \
        --null \
        --files-from=- \
        --transform="s|^|${pkgname}-${version}/|" \
        -czf "${source_archive}"

(
    cd "${work_dir}"
    makepkg --force --syncdeps --noconfirm
)

find "${work_dir}" -maxdepth 1 -type f -name "${pkgname}-${version}-*.pkg.tar.*" -exec cp -f {} "${dist_dir}/" \;

echo "Arch Linux package created under:"
echo "  ${dist_dir}"
