# Polish validation ledger

## Cloud checks executed

- 38 production Luau sources compiled.
- 7,436 domain assertions executed in Luau WASM with deterministic Roblox service/primitive doubles.
- Client startup regression verifies that profile delivery survives an unavailable input controller.
- Official `rbxmk` decodes the place, checks 151 asset trees and attributes, embeds the source, round-trips to binary and confirms the Studio mock attribute survives.
- Three source-merge tests verify imported model/metadata preservation, additive module creation and rejection of non-script name collisions/existing output overwrites.

The mode tests invoke the actual MatchmakingService, MatchService, EconomyService and CombatService. Engine primitives are doubles; they do not establish that movement, physics or replication works in Studio.

| Required scenario | Executed cloud coverage | Roblox Studio/live result |
| --- | --- | --- |
| Casual 1v1 | Queue, countdown cancellation, preview, battle state, disconnect forfeit, rewards, cleanup | UNRUN |
| Ranked 1v1 | Queue, preview, online forfeit, rating, single reward, cleanup | UNRUN |
| Casual 2v2 | Balanced sides, full lifecycle, team elimination and rewards | UNRUN |
| Ranked 2v2 | Balanced sides, full lifecycle, rating and rewards | UNRUN |
| Casual 3v3 | Balanced sides, full lifecycle, team elimination and rewards | UNRUN |
| Ranked 3v3 | Balanced sides, full lifecycle, rating and rewards | UNRUN |
| Practice | Valid team, bot decision path, preview, battle, no currency farming, return | UNRUN |
| Crates | Starter uniqueness, eligibility, weights, duplicate compensation, ownership | UNRUN reveal/camera/UI |
| Shop | Insufficient funds, authoritative price, duplicate ownership prevention | UNRUN UI interaction |
| Team editing | Ownership, uniqueness and exact size validation | UNRUN repeated menu interaction |
| Creature switching | Budgets, forced replacement, retained HP/cooldowns, transition guard | UNRUN animation/input/replication |
| Potion | One-use limit, healing, damage cancellation | UNRUN channel animation/feedback |
| Respawn / return | Exactly one lobby respawn per connected simulated player | UNRUN real avatar loading |
| Leave / disconnect | Single forfeit result and cleanup without respawning disconnected user | UNRUN network disconnect |
| Timer / sudden death | Living-creature/HP tiebreak, exact tie activation, impartial simultaneous draw | UNRUN live countdown/drain |
| Results / rank | Correct mode rewards, MMR rules, receipt idempotency, result phase | UNRUN result presentation |
| Every menu repeatedly | Sources compile; startup handshake tested | UNRUN visibility, stacking, layout and repeated actions |
| Camera / controls | Bounded settings and explicit cleanup paths in source | UNRUN camera reset, touch hold/release and spectator switching |
| Performance | Preview pagination, local effect caps, nearby ambient updates in source | UNRUN device/frame-time/memory measurements |

## Required next step

Complete `docs/TESTING.md` on Windows/macOS Studio, then on real devices and a private published test universe. Record failures with Server Output, mode, client count and reproduction steps. The polish pass is not production-certified while these engine checks remain unrun. Cloud assertions are not a substitute for the user's required full QA pass.
