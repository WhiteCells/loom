#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "${script_dir}/.." && pwd)"
app_target="LoomDesktop"
config="${CONFIG:-Release}"
build_dir="${BUILD_DIR:-${project_root}/build/package-macos}"
dist_dir="${DIST_DIR:-${project_root}/dist}"
generator="${CMAKE_GENERATOR:-}"
qt_prefix="${QT_PREFIX:-}"
clean=0

usage() {
    cat <<EOF
Usage: script/package-macos.sh [options]

Options:
  --config <name>       CMake build type, default: Release
  --build-dir <path>    Build directory, default: build/package-macos
  --dist-dir <path>     Output directory, default: dist
  --generator <name>    CMake generator, default: Ninja when available
  --qt-prefix <path>    Qt/CMake prefix, forwarded to CMAKE_PREFIX_PATH
  --clean               Remove the package build directory first
  -h, --help            Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)
            config="$2"
            shift 2
            ;;
        --build-dir)
            build_dir="$2"
            shift 2
            ;;
        --dist-dir)
            dist_dir="$2"
            shift 2
            ;;
        --generator)
            generator="$2"
            shift 2
            ;;
        --qt-prefix)
            qt_prefix="$2"
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

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "package-macos.sh must be run on macOS." >&2
    exit 1
fi

command -v cmake >/dev/null 2>&1 || {
    echo "cmake is required." >&2
    exit 1
}

if [[ -z "${generator}" ]] && command -v ninja >/dev/null 2>&1; then
    generator="Ninja"
fi

version="$(sed -nE 's/^project\(LoomDesktop VERSION ([^ )]+).*/\1/p' "${project_root}/CMakeLists.txt" | head -n 1)"
if [[ -z "${version}" ]]; then
    echo "Unable to read project version from CMakeLists.txt." >&2
    exit 1
fi

arch="$(uname -m)"
package_name="${app_target}-${version}-macos-${arch}"
stage_parent="${dist_dir}/stage"
stage_dir="${stage_parent}/${package_name}"
dmg_path="${dist_dir}/${package_name}.dmg"
zip_path="${dist_dir}/${package_name}.zip"

if [[ "${clean}" -eq 1 ]]; then
    rm -rf "${build_dir}"
fi

cmake_args=(
    -S "${project_root}"
    -B "${build_dir}"
    -DCMAKE_BUILD_TYPE="${config}"
)

if [[ -n "${generator}" ]]; then
    cmake_args+=(-G "${generator}")
fi

if [[ -n "${qt_prefix}" ]]; then
    cmake_args+=(-DCMAKE_PREFIX_PATH="${qt_prefix}")
fi

cmake "${cmake_args[@]}"
cmake --build "${build_dir}" --config "${config}" --parallel

rm -rf "${stage_dir}"
mkdir -p "${stage_dir}" "${dist_dir}"
cmake --install "${build_dir}" --config "${config}" --prefix "${stage_dir}"

if command -v hdiutil >/dev/null 2>&1; then
    rm -f "${dmg_path}"
    hdiutil create -volname "${app_target}" -srcfolder "${stage_dir}" -ov -format UDZO "${dmg_path}"
    echo "Package created:"
    echo "  ${dmg_path}"
else
    rm -f "${zip_path}"
    ditto -c -k --sequesterRsrc --keepParent "${stage_dir}" "${zip_path}"
    echo "Package created:"
    echo "  ${zip_path}"
fi
