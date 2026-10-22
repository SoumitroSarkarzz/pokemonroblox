# Asset workflow

Every Kanto entry is already present in the generated place:

```text
ReplicatedStorage
  Pokemon
    Models
      025_Pikachu
        ModelSlot
          PlaceholderModel
        Animations   (22 Animation objects)
        VFX          (Ability1–Ability4 folders)
        Sounds       (8 Sound objects)
        UI           (Icon / Portrait slots)
    Icons            (151 folders, Icon / Portrait StringValues)
    Data             (PokemonDatabase / PokemonModelSettings module aliases)
    Animations
    VFX
    Sounds
  Shared             (catalogue, settings, loader, rig adapter, viewport, rules)
```

Use assets you have permission to use. Import a Model into the appropriate `ModelSlot`, then remove `PlaceholderModel`. The model's name is irrelevant. Custom models are preferred over placeholders even if both exist. A model must contain a BasePart or MeshPart. Missing PrimaryPart is inferred from HumanoidRootPart, Root, RootPart, Torso, Body, or the largest remaining part. An invalid model falls back to a generated placeholder instead of stopping gameplay.

`PokemonModelLoader:GetModel(id)` returns the source template or nil if no valid stored source exists; `ClonePokemon(id)` always generates a fallback for a known ID, normalizes its height, removes executable scripts and disables visual collisions. All spawning and previews use `ClonePokemon`. `GetPlaceholder`, `GetPokemonFolder`, `ValidateModel`, and `HasCustomModel` provide inspection utilities. Call methods using colon syntax.

Animations stay in the Pokémon's `Animations` folder. Set their `AnimationId` values to your published, experience-permitted assets. Locomotion and combat hooks use the rig adapter; animation compatibility across arbitrary imported skeletons still needs rig-specific animation authoring. An unanimated asset remains playable with simple procedural movement and generic effects. Humanoid models, bones, single MeshParts and disconnected multipart models use the same outer combat wrapper. Imported rig joints are preserved; disconnected components are welded; the visual's primary part attaches to a standardized server root.

Canonical image slots are `Pokemon.Icons.<FolderName>.Icon` and `.Portrait` StringValues. Set `Value` to `rbxassetid://...`. Collection/shop cards use the icon when present and fall back to live model viewports. Detail and crate views use the actual 3D model so replacement art appears automatically. `Models.<FolderName>.UI` contains prepared optional local references; the global Icons tree is authoritative. Portrait slots are available for further UI customization; not every screen renders a separate portrait today.

`PokemonModelSettings` defines Scale, TargetHeight, GroundOffset, RotationOffset in degrees, CameraDistance, HitboxSize and RootOffset. Model scaling never changes competitive hurtboxes. Hurtboxes remain 4×5×4 for every creature; HitboxSize is prepared metadata for future modes, not a way to gain a mesh-sized collision advantage. GroundDetector and hitbox-attachment containers are extension points; current combat uses roots, standardized dimensions and server raycasts.

To repair missing objects from the Studio command bar **outside Play**:

```lua
require(game.ServerStorage.PokemonAssetSetup).Run()
```

The utility does not overwrite existing instances. The database and settings templates are shipped modules; the utility repairs folders and slots rather than rewriting your configuration source. It prints installed-model/icon/animation counts, missing models and broken models. ReadyForBattle includes usable placeholders and is separate from final-art completion. Runtime listeners refresh status attributes as asset descendants change.

Custom VFX can be placed inside per-creature Ability1–Ability4 folders. ParticleEmitters are emitted with a maximum burst of 24; the optional `EmitCount` attribute selects a lower count. Sounds use matching per-creature names. Empty asset IDs are intentional; there are no fake uploaded IDs. To author a unique move, add a configuration in AbilityDatabase and reference its key in that creature's Abilities array. New effect/ability kinds require a server framework handler; replacing models never does.

For maps, replace a theme using a Model named exactly as its MapDatabase entry in `ServerStorage.Maps`. Its pivot is the arena center. The standardized floor, boundary walls and covers remain in place. Anchor imported scenery and avoid colliders that permanently hide fighters. The six supplied themes use primitive geometry and palettes, not finished environment art.
