#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

bash scripts/setup.sh
python3 scripts/studio_installer.py --check
.tools/luau-compile-0.748 --null InstallInStudio.lua
find src -type f \( -name '*.lua' -o -name '*.luau' \) -print0 | \
    xargs -0 --no-run-if-empty .tools/luau-compile-0.748 --null
mkdir -p dist
.tools/rojo-7.7.1 build default.project.json --output dist/CrystalMiningSimulator.rbxl
