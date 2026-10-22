# Validation and implementation status

This is an initial Studio-ready implementation, not evidence of a production-ready Roblox release.

## Verified on this cloud machine

- All 29 production Luau sources compile in Luau WASM.
- 3,279 executed domain assertions pass. They cover catalogue completeness, typed entries, four available ability configurations, standardized HP, team ownership, starter uniqueness, weighted crate eligibility, duplicate conversion, purchases, daily replay protection, MMR, idempotent reward application, queue compatibility, session leases, unsafe load refusal, hit startup, friendly fire, line of sight, guard/shield mitigation, potion interruption, voluntary/forced switching, cooldown preservation and result-phase action denial, swept projectile hits and projectile cover blocking, ground-slam damage and finisher launch velocity.
- Tests use deterministic Roblox primitive/service doubles. They exercise the actual server modules but do not emulate Roblox physics, replication, input controls or DataStore networking.
- Source-merge preservation test confirms imported model metadata survives and the original Studio file is untouched; existing outputs cannot be overwritten.
- Official `rbxmk` 0.9.1 decodes the generated XML, verifies 151 nested asset trees and serialized string/boolean/numeric attributes, verifies embedded entry points, and successfully writes/reads a binary Roblox place.
- Installation uses the npm lockfile, HTTPS verification and fixed SHA-256 checks for the official validator release.

## Unrun in this environment

Roblox Studio is not available on Linux here. No client/server play session, bot fight, avatar movement, imported rig playback, touch device test, real DataStore transaction, ordered leaderboard API call or live multiplayer match has been executed. Complete the Studio checklist before claiming those behaviors work. File decoding and unit tests do not substitute for them.

## Intentional initial scope

- All 151 creatures share four functioning configurable placeholder ability archetypes. Unique moves, passives, counters, type matchups and distinct combo routes are content work, not implemented for 151 entries.
- Six maps use distinct primitive scenery and the same safe scaled layout. They are not polished maps. The lobby and UI are generated functional development content.
- Queue matching is local to each server. Both teams enter an isolated arena in that server; no MemoryStore cross-server queue or TeleportService handoff exists.
- Basic attacks have a four-hit chain, a launching finisher, an airborne ground slam, hit stun and knockback. Advanced aerial state machines and chargeable move archetypes are not implemented.
- Clients send movement direction; roots remain server-owned. High-latency prediction/reconciliation, aim assist and custom camera collision behavior need further development and testing.
- Result receipts prevent duplicate application in a profile during normal match completion. They are not a durable distributed match journal; process crashes can lose recent unsaved progression. Draws grant no result rewards or rating changes.
- Studio can use explicitly announced temporary mock profiles. Production requires functioning DataStore access and fails closed otherwise. There is no automatic corruption repair or cross-version schema migration.
- UI includes dynamic catalogue search and filters, model previews, basic crate reveal, segmented cooldown rings and touch action buttons. It does not include polished crate-camera cinematics, drag/drop team editing, a spectator system or authored UI artwork. Clicking supports team editing as requested.
- Animation IDs and sound IDs are empty until your permitted assets are supplied. Music setting is saved for future audio content; there is no background music track yet. Animation hooks cover locomotion and attacks but not every prepared state slot.
- Ranked has server-authoritative rewards, equal combat HP and equal potion allowances. There are no paid purchases. Live balance, moderation, abuse detection, observability, crash recovery and performance certification remain release gates.
