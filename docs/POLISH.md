# Comic polish upgrade

This is an additive upgrade of the existing services, folders and game flow. It is not a new game or a claim of completed Studio QA.

## What changed

- `UITheme` centralizes palette, typography, elemental colors and graphics budgets. `ComicUI` supplies original angled accents, outlines, gradients, vector halftone details, hover motion, button compression and staggered menu text.
- `UIController` keeps its public methods and gains the requested menu/HUD/tooltip/result aliases. `HUDPresentation` supplies layered health cards, delayed damage bars, active/bench model portraits, status labels, defeated overlays, readable opponent information, a three-card switch selector, ready pops, stacked notifications, intro cards, signature cut-ins, combo feedback and reward/statistic result cards.
- `MoveDatabase` retains every legacy AbilityDatabase key and timing field. It supplies all requested move metadata, 18 elemental move families, and authored assignments for Bulbasaur, Venusaur, Charmander, Charizard, Squirtle, Blastoise, Pikachu, Gengar, Dragonite and Mewtwo. The other creatures use their elemental family's four moves. This does not give rarer creatures inflated HP.
- Existing hit validation, cooldowns, ownership, shop, crates, switching budgets, one-potion limits and DataStore namespace remain. Server hit statistics count actual damage, unique connected attacks, knockouts, recent assists, switches, potions and longest combo. Viewer-specific snapshots omit other players' cooldowns.
- `CameraEffects` provides bounded, adjustable shake, FOV punch, local animation hitstop, a short signature effect and a crate chamber camera. Team-mode elimination can follow living teammates. Camera and input bindings clean up when their UI is destroyed.
- `ElementalVFX` and a capped local pool provide cast/travel/impact/aftermath effects and animated impact numbers. `SoundController` centralizes quiet UI feedback and optional per-move cast/travel/impact sound layers. Rig adapters cache tracks and fall back if an animation cannot load.
- `WorldDecor` adds districts, a hologram, benches, plants, terminals, a training range, a movement course, a social walkway, team plinths, crate machinery, leaderboard screens, spectator stands and six themed arena backgrounds. Decorative geometry does not become combat cover. `SceneController` animates nearby details locally and reduces motion/particles/shadows in Low mode.
- Catalogue pages create at most 24 model previews at a time, rather than 151 simultaneous previews. Search and filters still cover the entire catalogue. Imported creature models and standardized combat colliders still use the same loader.
- Studio now uses temporary profiles unless `Workspace.UseMockData` is explicitly false. Published servers still require real storage, even when that attribute is missing or true. This avoids a missing local attribute silently triggering real API access and a kick.

## Apply the upgrade

The downloadable `KantoArena-Polish.rbxl` is a fresh build from the upgraded repository. Opening it does not update an older file that is already open in Studio. Keep your previous file as a backup.

If you added models, animation IDs, icons or map objects to your old place, preserve those edits:

1. Stop Play and use Studio **Save to File As** to save your working place as XML `.rbxlx` outside the extracted project's `build/` directory.
2. Back up that file. From the upgraded project directory run:

   ```sh
   python3 tools/update_place.py /path/to/Working.rbxlx build/Upgraded.rbxlx
   ```

3. Open the new `Upgraded.rbxlx` in Studio. The merge changes known script sources and adds missing upgrade modules. It preserves all other objects and never overwrites the input or an existing output. It refuses a conflicting non-script object with a required module name.
4. Review any custom code changes you previously made: known project script sources are intentionally replaced. The tool preserves assets, not arbitrary local modifications to those scripts.
5. Run the Studio checklist before publishing. Imported animation permissions and rig compatibility still require testing.

## Asset hooks and limits

UI feedback uses Roblox's bundled electronic ping as a quiet fallback. `SoundController.Slots` can replace individual UI sounds; `MoveSlots[MoveID]` or `MoveSlots[Type]` can supply Cast, Travel and Impact IDs. No third-party music or character assets are included. Final move audio and animation clips remain dependent on your supplied assets. Advanced charge/cancel mechanics, novel status systems and unique hand-authored moves for all 151 creatures are not implemented merely because metadata fields exist.

Arena layouts still retain the original standardized covers and boundaries. Scenery is procedural primitive geometry, not imported production environment art. Season labels are prepared presentation, not a completed seasonal ranking/reset backend. Movement remains server-authoritative; advanced client prediction/reconciliation is unchanged.
