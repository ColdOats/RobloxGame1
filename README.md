# Crystal Mining Simulator — pre-alpha

The pre-alpha opens all five mines through earned-coin progression. The guild, equipment upgrades, coin crates, crafting, and expeditions are playable. Starshard top-ups, premium crates, and game passes are marked **(in development)** and their purchase actions are disabled.

## Build and play

Run `bash scripts/build.sh` from this checkout in the x86-64 Linux cloud environment. It installs checksum-verified versions of Luau and Rojo on first use, checks the Luau source, and builds `dist/CrystalMiningSimulator.rbxl`.

On pushes and pull requests, the **Build Roblox place** workflow runs `bash scripts/check-alpha.sh` and uploads the result as the **CrystalMiningSimulator** artifact. Download and extract it, open the `.rbxl` in Roblox Studio, and press **Play**.

The place includes a solid spawn floor and generates the market and mines at runtime. Use the **Mine** prompt or equip your pickaxe and aim at nearby ore to strike. Follow the first commission through selling and forging Iron, then choose a cave or expedition in the journal. The journal starts folded to give the map room.

## Development

Edit the scripts under `src/` and regenerate the Studio installer with `python3 scripts/studio_installer.py`. Then run `bash scripts/check-alpha.sh` to check the installer, compile the scripts, build the place, and run the headless server and client smoke tests. Game balance and product IDs are set in `src/shared/Config.lua`.

Open the generated place file to play the latest build. For a manual install into an empty Studio place, remove the default Baseplate and SpawnLocation, then run the latest `InstallInStudio.lua` in the Studio Command Bar in Edit mode.

## Travel between caves

The free Meadow Mine teleporter is just past spawn, across from the market. The starter mine is a separate area. Four more cave teleporters sit on the Meadow promenade. Approach a pad to see its current status, price, or prerequisite. Every cave has a free **Meadow Hub** teleporter back to town. A cave unlock is a one-time purchase per rebirth.

## Field Guide

New players see a short, illustrated welcome on their first visit. **Start Mining** dismisses it and the trail marker leads to Guild Commissions. Open **Guide** directly from the journal header to revisit the basics. **Start** has illustrated steps for mining, selling, forging, and exploring. **Atlas** lists each region’s ore, activity, and unlock cost. Its **Return to Meadow** button keeps the player’s haul and is available outside timed expeditions. The **Display** page has sound and floating-name controls for the current session. Nearby ore shows a health card when its Mine prompt appears.

The first Iron purchase grants a one-time 20-coin kit. In Frozen Peaks, collect 75 Frost Ore and set it aside at Meadow’s Frost Seal Press. The crafted seal permanently adds 35 bag capacity. Partial deposits and the finished seal carry through rebirths.

## Sound and music

Meadow, the starter mine, and the four later biomes each have an original chiptune theme with melody, bass, harmony, and percussion. The game plays the music from Roblox’s built-in sound samples and changes themes when players travel. Ore hits have a pick ring, and depleted nodes have a crack and a crystal shatter. Rich veins add a higher chime. **Guide → Display** has separate switches for music and effects.

## Commissions and market upgrades

From spawn, take the left lane for Miners’ Services. The guild, sell counter, bag outfitter, forge, and geode appraiser are all on that side. The right lane leads to Market Shops for coin crates, the Style Gallery, and the Geode Compass.

New players can follow the Meadow trail marker to Guild Commissions. The first order, First Haul, asks them to mine four nodes and sell eight crystals. The reward covers an Iron pickaxe, and the trail continues until Amethyst Cavern unlocks. The Orders tab tracks the assigned zone, required mined nodes or market sales, and the payout. The guild cycles through mining, selling, and mixed orders. Return to the guild to claim the reward and accept the next order.

Bag Outfitters sells four capacity upgrades. Purchases carry through rebirths, and each rebirth adds 25 capacity. Rebirth clears active commissions so the guild can assign a new job in Meadow. Completed orders carry over. Gold-outlined rich veins yield double the zone’s base crystal amount before pet bonuses and bag limits.

## Ore and the Surveyor’s Lantern

Depleted ore takes 10 seconds to start regrowing in Meadow and up to 17 seconds in later mines. The Starter pickaxe needs 0.75 seconds between swings, and each upgrade shortens that wait. The **Tools** tab shows the power and swing time for each pickaxe.

The **Bags** tab lists ore by cave. Sell the whole bag as usual, or visit the Surveyor’s Workbench in Miners’ Services to set aside Amethyst. At 24 Amethyst, the workbench crafts a permanent lantern that marks nearby rich veins in every mine. Stored Amethyst and the crafted lantern carry through rebirth. Any ore from older saves is shown as Unsorted and can still be sold.

## Vein chains and geodes

Break three different ore nodes in one mine to uncover a geode. Each new node gives you 45 seconds to reach the next one. Take geodes to the Meadow appraiser for coins and a specimen from that mine. The **Caves** tab tracks geodes and specimens. Collect all five specimens to earn the Prismatic Fieldwork aura. The Geode Compass in Market Shops costs 450 coins, adds 20 seconds per link, and stays with the player after rebirth.

## Cave Mastery

Open the **Caves** tab or read the Cave Ledger near the Meadow wayshrines. Mining nodes earns Prospector rank and improves yields in that mine. To reach Master, mine additional nodes, survey the mine’s zone landmark, and complete its expedition where applicable. The larger Master bonus applies only in that mine. Mastery persists through rebirths, and existing surveys and expedition auras count toward it.

## Amethyst Cavern routes

Follow the amber signs into Lantern Drift for a short mining loop. The violet signs lead through Echo Tunnels, where rich veins are more common and three resonant veins open the Echo Chamber. The teal route leads to Deep Gallery, which has the toughest ore and the largest base yields in the cavern. Reach the lower lift on foot once to unlock the two-way shortcut for that player. Entrance signs lead back from the branches toward the center corridor.

## Crystal Resonance expedition

Unlock Amethyst Cavern through its Meadow wayshrine. Inside the mine, look for the three pulsing veins. Any player with Cavern access can help mine them, and each completed vein raises the pitch of the cavern’s chime. When all three are tuned, the Echo Chamber opens for 85 seconds. Each contributor can extract the echo deposit once per run for 150 coins and earn the Resonance Echo aura on their first clear. The aura can be equipped under **Crates → Auras**. A return prompt inside the chamber stays available after the gate closes.

## Heartstone Descent

Master Amethyst Cavern to unlock this expedition near the Deep Gallery lift. Enter within 18 seconds of friends to join the same survey team, or run it solo. Complete two survey stakes, then bank a safe coin payout or risk it on a 55-second Heartstone descent. Teams can split the stakes and seams. Each member must contribute in the phase they want to claim. Leaving or running out the clock forfeits the expedition haul. Regular ore and coins are safe.

The first bank earns 120 coins. The first deep clear earns 360 coins and a Heartstone Trophy players can display in Meadow. Repeat banks and clears pay 45 and 90 coins respectively.

## Whiteout Relay

Start at the shelter in Frozen Peaks. Follow your personal beacon marker from Pinewatch to Frostmine, then take the mine’s rear exit and turn right toward the tarn. Signal all three beacons in order within 100 seconds. The first clear grants 300 coins and the Icebound Trail aura. Replays grant 45 coins and let you improve your saved personal best. Each player runs their own clock.

## Tidekeeper puzzle

In Sunken Ruins, read the carving on the Tidekeeper Altar. Set the Reed, Arch, and Mosaic dials to match, then return to the altar to offer your settings. The Status panel displays your current dial positions. The first solution grants 475 coins and the Tideglass Halo aura. Dial settings are personal to each player and reset when they rejoin. The earned reward stays in their collection.

## Emberheart Tempering

Start at the Emberheart Anvil in Ember Forge. Strike when the gauge marker is inside the highlighted heat band. Complete Heat, Shape, and Quench within two minutes. Misses leave the current stage available to retry. The first clear grants 850 coins and the Emberheart Mantle aura, and later clears can improve the player’s saved personal best.

## Starshards and premium crates (in development)

**Crates → Shards** previews the Starshard packs and premium crate rewards. The pre-alpha disables both top-ups and opening premium crates. Pet, pickaxe, and cosmetic crates in Meadow use earned coins.

For a later release, create a **Developer Product** for each pack in the Roblox Creator Dashboard. Configure the IDs in `StarshardProducts` and set `StarshardSalesEnabled` to true in `src/shared/Config.lua` or `ReplicatedStorage.MiningConfig` before publishing. Keep any previously sold product IDs and amounts so the game can fulfill pending receipts.

Premium crates show the guaranteed cosmetic before spending. Meteor Etch adds gold inlays to the pickaxe head, and Dusk Comet adds a two-color particle trail. Neither changes mining stats.

Test with a separate private experience and its own product ID. The server stores Starshard balances, crate entitlements, and processed receipt IDs together in a dedicated DataStore record so repeated deliveries and repeated crate clicks cannot grant the same purchase twice.

## Game passes (in development)

Players can browse the **Trailblazer** and **Cavern Artist** passes at Meadow’s Style Gallery or under **Crates → Passes**. Each pass unlocks the listed pickaxe finish and aura permanently. Equip them from the Skins and Auras tabs. The journal shows a next objective from the first commission through the lantern and Crystal Resonance, including while the journal is folded.

To sell a pass, create it for this experience under **Monetization → Passes** in Creator Dashboard and set its Robux price there. Copy each numeric ID into its matching `GamePasses` entry in `src/shared/Config.lua` or `ReplicatedStorage.MiningConfig` in Studio. Each pass needs its own ID. Passes are currently marked **(in development)**. When you are ready to sell them, set `GamePassSalesEnabled` to true and publish the updated place. The Robux price appears in Roblox’s confirmation prompt.

## Publish a private pre-alpha

Open `dist/CrystalMiningSimulator.rbxl` in Roblox Studio. Use **File → Publish to Roblox As** and select a separate private test experience. Grant play access to your testers through Roblox. If you test persistence from **Studio**, enable **Studio Access to API Services** only for the test experience. The default build keeps paid features in development even when Roblox IDs are configured.

Before inviting testers, confirm the game opens and the Output window has no startup errors. Run one fresh player through spawn, sale, Iron, and the cavern unlock. The automated test covers the gameplay handlers and save flow with simulated Roblox services. Use Studio or a real Roblox client to check rendering, sound, click and touch input, device layout, and real DataStore access.

- In Amethyst Cavern, walk Lantern Drift and Deep Gallery, and try a two-player Crystal Resonance clear. Observe whether the signs work without a waypoint.
- Sell one haul and set Amethyst aside from another. Craft the lantern, then check that its markers stand out from the normal ore labels.
- Check the journal on a phone-sized screen with the HUD both folded and expanded. Verify mining prompts, tool selection, and the expedition controls.
- Acquire a bag upgrade, ore, cave mastery, and a cosmetic or lantern. Leave, rejoin, and compare them. If a previous session is still saving, retry after it closes.

When upgrading an existing published experience, shut down servers running the older save code before opening the alpha build. The new version reads legacy profiles and wraps them in a session-aware record. Older servers still use unconditional writes.

## Features and limitations
Meadow has a wooded market plaza and four travel wayshrines. Follow the unlock path through Amethyst Cavern, Frozen Peaks, Sunken Ruins, and Ember Forge. Every zone has a walk-in mine with 12 faceted crystal clusters that release sparks on impact and grow back after depletion and one landmark to survey for a one-time coin reward. Discoveries persist with player progress, including across rebirths.

Mine prompts equip the player's pickaxe and play a swing on successful hits. The market plaza features a fountain, pennants, planters, and striped shop awnings. Meadow has branching oaks, Frozen Peaks has snowy pines and flurries, Sunken Ruins has drifting motes, and Ember Forge has rising sparks.

The Pickaxe Forge displays all six tiers. Forge the next tier to replace your current pickaxe in the hotbar. The HUD has a status panel and a pickaxe catalog with prices and mining power.

The prototype includes a sell station, bag capacity, five collectible pets, rebirths, leaderstats, and basic save/load. Meadow sells three crate types for earned coins. The Crates tab lists odds and lets you equip collected pets, pickaxe finishes, and auras. Duplicate rolls refund half the cost, rounded down. A stronger pet auto-equips when discovered; finishes and auras are cosmetic. Collections survive rebirth. Gameplay saves use a server lease, autosave, and a final save on departure. Roblox Studio still needs an in-game persistence check before public release.
