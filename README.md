# Kanto Arena

A modular Roblox real-time creature arena project with a prebuilt 151-slot Kanto asset library. Players control one creature directly, bring three-creature teams, and fight in server-owned isolated arenas. This repository contains a working implementation intended for Studio validation, **not a certified production release**. Roblox Studio and live service validation cannot run on this Linux cloud machine.

## Download

- [Download the Roblox Studio game file](https://github.com/SoumitroSarkarzz/pokemonroblox/raw/refs/heads/main/releases/KantoArena-Polish.rbxl)
- [Download the complete project ZIP](https://github.com/SoumitroSarkarzz/pokemonroblox/raw/refs/heads/main/releases/KantoArena-Polish.zip)

Open `KantoArena.rbxl` in Roblox Studio. The ZIP includes source code, documentation and built place files. After a fresh source checkout, run the setup below to regenerate `build/`, or use the committed game file in `releases/` directly. To refresh the committed download packages after building, run `python3 tools/package.py`.

## Comic polish upgrade

The current build upgrades the existing project in place: shared comic styling, animated menus, a portrait HUD, switch selector, move tooltips, detailed elemental moves, hit feedback, result statistics, spectator camera, detailed districts and six arena themes. All 151 creature slots and core service interfaces remain. Read [the polish notes](docs/POLISH.md) and [QA ledger](docs/QA.md) for what changed and what remains unverified.

If your old local file has imported models or art, use the asset-preserving source merge below instead of replacing that file with a fresh build.

## Open the game

1. Open `build/KantoArena.rbxlx` (or the validated binary `build/KantoArena.rbxl`) in Roblox Studio.
2. Press **Play**. Open **Crates** and open the three Starter crates. A valid three-creature team fills automatically.
3. Choose **Training → Normal Bot** or **Training Dummy** for a solo session.
4. Use Studio's **Server & Clients** test with two clients to enter the same Casual 1v1 circle. Both must stay for the full 10-second countdown.
5. In Play, switch the command bar to **Server** and run `require(game.ServerStorage.StudioChecks).Run()`.

The generated place sets `Workspace.UseMockData=true`: Studio uses temporary test profiles without opening any DataStore or leaderboard API. Missing attributes also default to temporary profiles; only an explicit false enables real API testing in Studio. This works in unpublished local places. The Output window explicitly identifies mock sessions. Nothing from mock sessions is saved. Published servers never use mock data; failed loads deny entry instead of overwriting existing profiles. To test real persistence, publish a private test experience, enable Studio API access for that test experience, set `Workspace.UseMockData` to false, and follow [the test checklist](docs/TESTING.md). Use a separate test universe to protect production data.

## Build and validate in the cloud

Requires Node.js 22+ and Python 3.10+. No game runtime dependencies, plugins, paid packages, tokens, or external art are required.

```sh
cd /workspace/pokemonroblox
npm ci --cache /tmp/pokemon-npm-cache --ignore-scripts
npm run setup
```

`setup` installs a checksum-pinned official `rbxmk` validator outside the checkout, builds the place, compiles every Luau module, executes domain tests in Luau WASM, decodes the generated Roblox XML, verifies all 151 asset trees, and round-trips the binary place. It does **not** start Roblox. Run `python3 tools/package.py` after setup to refresh the downloadable ZIP and game files. The Node dependency is solely for cloud testing. The Python builder itself has no external dependencies.

Individual commands:

```sh
npm run build       # XML place + standalone asset library + source manifest
npm test            # Luau compilation and executable domain tests
npm run test:place  # Roblox file decoding and binary round trip
```

## Controls

| Action | Desktop | Mobile |
| --- | --- | --- |
| Move / jump | WASD / Space | Roblox joystick / jump |
| Aim / camera | Mouse; hold right button to orbit | Roblox touch camera |
| Basic combo | Left click | M1 button |
| Abilities | 1–4 | Four ability buttons |
| Dash | Q | Dash button |
| Switch | R | Switch button |
| Guard | Hold F | Hold Guard button |
| Potion | G | Potion button |

The camera follows the combat character. Settings include optional pointer locking. Movement intents go to the server at 20 Hz; the server owns roots and all competitive state. Responsiveness under real latency still needs playtesting; advanced client movement prediction/reconciliation is not implemented.

## Systems included

- Explorable generated lobby with seven queue circles, live player/rank displays, countdown cancellation, shops, crates, collection, team builder, daily rewards, statistics, leaderboards, training, settings, and model showcases.
- Casual and Ranked 1v1/2v2/3v3, local MMR compatibility windows and beginner protection, team balancing, scaled arenas, previews, match countdown, timers, results, rewards, and lobby return.
- Three creatures per player, two voluntary switches, preserved HP/cooldowns, automatic forced replacements, elimination, team victory, timer tiebreaks, sudden death, and simultaneous-elimination draws.
- Server-validated basic combos, launching finishers, airborne ground slams, melee hit windows, swept projectiles, line-of-sight checks, AOE, dash attacks, ward, guard/stamina, stun, knockback, invulnerability windows, and one interruptible 25-HP potion per match.
- Session-leased DataStore profiles, load failure protection, save/release, autosaves, bounded shutdown saving, in-memory reward receipts, server-priced purchases, server RNG, duplicate compensation, daily rewards, favorites, saved teams, XP, mastery, and Elo-style rank changes.
- Four bot difficulties, dummy practice with damage/combo/DPS readings and reset, teammate outlines, rosters, cooldown numbers and segmented cooldown rings, touch buttons, reusable visual effects, and custom animation/sound/VFX hooks.
- All 151 modern-typed Kanto entries; standardized 100 HP; four functioning detailed elemental moves for each entry, with authored move assignments for the launch roster; configurable rig/scale/camera settings; model-independent hurtboxes.

## Replace art without changing gameplay

See [ASSETS.md](docs/ASSETS.md). The place already contains every asset folder in edit mode. Run the idempotent Studio setup utility only to repair missing slots. Existing imported models are preserved.

The cloud builder generates a **fresh** place. It never reads your Studio edits. Save your imported-asset working place outside `build/`, for example `studio/Working.rbxlx`. To merge repository source changes into that XML place while preserving its models, animations, icons and other objects:

```sh
python3 tools/update_place.py studio/Working.rbxlx build/Updated.rbxlx
```

This refuses to overwrite an existing output, updates known script Source properties, and adds missing upgrade modules without replacing imported assets. It fails on conflicting non-script objects. Known script edits are replaced, so review your custom code separately. Save your Studio work before merging, then open the new output and inspect it. Binary `.rbxl` inputs must first be saved as XML `.rbxlx` in Studio.

## Architecture

`src/server` owns gameplay and persistence. `src/client` owns input, camera, menus, previews and effects. `src/shared` contains catalogue, combat configuration, map configuration and asset adapters. `src/studio` contains explicit Studio utilities. `tools/build.py` embeds the source and creates the full asset library in a standalone place.

- `CombatService` accepts action intents; it never accepts target IDs, damage or client hit claims.
- `MatchService` creates isolated match folders and manages actor state. Arenas are inside the same server, not reserved-server teleports.
- `MatchmakingService` validates physical queue presence and cancels countdowns when a player leaves.
- `EconomyService` owns crates, purchases, teams, progression, daily rewards and result receipts.
- `CreatureService` creates standardized physics roots/hurtboxes and attaches sanitized visual models while preserving their rig joints.
- `PokemonModelLoader` is the only source for combat and preview models. Asset names never appear in core combat logic.

## Release work still required

See [TESTING.md](docs/TESTING.md) for the unrun engine checks and [STATUS.md](docs/STATUS.md) for precise implementation limits. Elemental move families, authored launch-roster assignments, comic presentation and themed procedural scenery are implemented. Final imported art, full-roster unique mechanics and rig-specific audio/animation assets remain content work. Cross-server matchmaking, reserved-server transfer, durable match-result journals, spectators, moderation/admin tools, production telemetry, high-latency reconciliation and device performance certification are not included. Global ordered leaderboards are implemented but require Roblox API access for validation.

No Roblox experience was published. Committed files in `releases/` provide downloadable development builds; they do not establish production readiness.
