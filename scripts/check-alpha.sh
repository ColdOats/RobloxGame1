#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

bash scripts/build.sh
smoke=$(mktemp --suffix=.luau)
trap 'rm -f "$smoke"' EXIT
{
    cat tests/roblox_mock.luau
    printf '\nregister("MiningConfig", services.ReplicatedStorage, (function()\n'
    cat src/shared/Config.lua
    printf '\nend)())\n'
    for module in Pickaxes World Premium SessionStore; do
        printf '\nregister("%s", services.ServerScriptService, (function()\n' "$module"
        cat "src/server/$module.lua"
        printf '\nend)())\n'
    done
    printf '\n'
    cat src/server/Main.server.lua
    printf '\n'
    cat tests/alpha_smoke.luau
} > "$smoke"
.tools/luau-0.748 "$smoke"

{
    cat tests/roblox_mock.luau
    printf '\nregister("MiningConfig", services.ReplicatedStorage, (function()\n'
    cat src/shared/Config.lua
    printf '\nend)())\n'
    cat tests/client_setup.luau
    for module in MiningAudio BiomeView; do
        printf '\nregister("%s", services.ReplicatedStorage, (function()\n' "$module"
        cat "src/client/$module.lua"
        printf '\nend)())\n'
    done
    printf '\n'
    cat src/client/Main.client.lua
    printf '\n'
    cat tests/client_smoke.luau
} > "$smoke"
.tools/luau-0.748 "$smoke"
