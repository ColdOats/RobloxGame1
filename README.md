# Crystal Mining Simulator — prototype

## Build and play

Run `bash scripts/build.sh` from this checkout in the x86-64 Linux cloud environment. It installs checksum-verified versions of Luau and Rojo on first use, checks the Luau source, and builds `dist/CrystalMiningSimulator.rbxl`.

On pushes and pull requests, the **Build Roblox place** workflow runs the same command and uploads the result as the **CrystalMiningSimulator** artifact. Download and extract it, open the `.rbxl` in Roblox Studio, and press **Play**.

The game generates its own map and spawn. Walk up to a crystal and use the **Mine** prompt. Sell at the gold station, upgrade at the blue station, and hatch at the pink station. Studio can run with temporary progress. To test saving, use a separate private test experience with Studio API access enabled.

## Development

Edit the scripts under `src/` and rebuild. The shared configuration lives in `src/shared/Config.lua`. The CI build checks compilation and packaging. Test gameplay and persistence in Studio before publishing an update.

`InstallInStudio.lua` is the installer from the original prototype archive. Open the generated place file to play the latest build.

## Features and limitations
Three generated zones, 36 regenerating nodes, four pickaxes, sell station, capacity, three randomized pets (best auto-equipped), rebirths, leaderstats, basic save/load. Eggs use earned coins only. No trading, pet models, inventory, paid products, or global leaderboard yet. Map uses primitive parts. All reward actions are server-side and distance checked. This is an untested Studio prototype, not production-ready; persistence uses simple SetAsync and requires further testing and session-locking before public release.
