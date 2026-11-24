#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

if [[ "$(uname -s):$(uname -m)" != Linux:x86_64 ]]; then
    echo "This setup script requires x86-64 Linux. Use the cloud environment or GitHub Actions to build the place." >&2
    exit 1
fi

work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT
mkdir -p .tools

install_release() {
    local url=$1 checksum=$2 executable=$3 target=$4
    if [[ -x "$target" ]]; then
        return
    fi
    curl --fail --silent --show-error --location --retry 3 --proto '=https' \
        "$url" -o "$work_dir/release.zip"
    printf '%s  %s\n' "$checksum" "$work_dir/release.zip" | sha256sum --check
    unzip -p "$work_dir/release.zip" "$executable" > "$work_dir/$executable"
    install -m 755 "$work_dir/$executable" "$target"
}

install_release \
    https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip \
    00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4 rojo .tools/rojo-7.7.1
install_release \
    https://github.com/luau-lang/luau/releases/download/0.748/luau-ubuntu.zip \
    e6905c04dbccaeff54ca4986b0017f125db5aa301bcb34d0446355cbfee5bc83 luau-compile .tools/luau-compile-0.748
