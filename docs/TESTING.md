# Studio and live-service test checklist

These checks have **not been run by the cloud agent**. Record actual pass/fail results in your development copy. Keep API tests in a separate private test universe.

## 1. Startup and assets

- Open the XML or binary place in Studio; verify all 151 folders in Explorer before Play.
- Press Play. Confirm no startup errors. A DataStore warning is expected if mock profiles are in use; it is not proof of persistence.
- On the server command bar, run `require(game.ServerStorage.StudioChecks).Run()` and require its PASS output.
- Run the repair utility twice outside Play; verify imported assets are preserved and no folders duplicate.
- Replace one placeholder with an imported single-part model without PrimaryPart. Start Play and verify root inference, scaling, preview and combat spawning. Repeat with Motor6D and bone rigs using compatible animations.
- Insert an empty custom Model. Confirm warning + placeholder fallback. Remove the test object afterward.

## 2. Solo vertical slice

- New mock profile: receive exactly three Starter crates. Open them and verify three different creatures and automatic team fill.
- Visit Collection: 151 searchable entries; unknown/unowned silhouettes; search `025`, `Electric`, `Speedster`; cycle ownership/rarity/role filters.
- Team Builder: remove/add by clicking; duplicate/unowned/short teams must be rejected. Save three distinct owned creatures.
- Training Dummy: WASD/joystick movement, jump, mouse/touch camera, M1 four-hit combo, all abilities, cooldown feedback, dash and guard.
- Confirm damage, combo damage/count and DPS change. Reset training and verify HP, cooldowns, switch count and potion allowance reset.
- Easy/Normal/Hard/Expert bots: verify pursuit, ranged spacing, attacks, retreat, switching, healing, and advanced dodge behavior; inspect any obstacle stalls.
- Switch twice; third voluntary switch must fail. Forced replacement after defeat must still work. Verify HP/cooldowns persist on returning to a previously used creature.
- Use one potion below 75 HP: heal 25 without exceeding 100. Take damage during channel: no heal. A second potion must be refused.

## 3. Multiplayer

- Start two Studio clients. Queue Casual 1v1 by walking onto the same pad. Read usernames, level/rank and count. At 5 seconds remaining, walk one client out: countdown cancels. Rejoin and remain: enter an arena with a 3-second preview.
- Confirm the opponents' roots, models, cameras, HP and effects replicate. Movement should be consistent on both clients. Test network emulation for jitter and delayed hits.
- Confirm attacks cannot pass through cover and different visual model sizes do not change hurtboxes. Teammates must not damage each other.
- Verify all three defeats cause a loss; winner gets correct casual rewards with unchanged MMR. Both return to the lobby.
- Repeat Ranked and verify rating gain/loss and stronger rewards.
- Repeat with four and six clients for 2v2/3v3. Check roster, outlines, balanced sides, arena size, team elimination and simultaneous arenas being isolated from each other.
- Shorten mode Duration in a separate test copy: exercise living-creature tiebreak, HP tiebreak, exact tie/sudden death and simultaneous elimination.
- Disconnect during countdown, preview, battle and results. Confirm countdown cancellation/forfeit, survivor result, cleanup, and no second reward.

## 4. Security and persistence

- Send malformed remote payloads from a client test script: fake targets/damage/coins must have no effect; NaN movement, invalid slots, unowned teams and rapid ability spam must be rejected. Rate limits must bound requests.
- In a private published test universe, disable mock profiles. Verify that unavailable DataStores deny entry without creating a replacement profile.
- Enable authorized API access. Acquire a real profile, earn coins, save/leave/rejoin, and verify team, crates, coins, settings, daily state, XP, rank and ownership.
- Simulate two server sessions for the same user: a live foreign lease must block the second load. Releasing the first session must allow a later load.
- Confirm daily claims are once per UTC day, duplicate rewards are applied once and ordered leaderboard entries reflect best streak rather than current streak.
- Test process shutdown saving and document the expected last-autosave crash-loss window. Implement a durable match journal if stronger recovery is needed.

## 5. Release gate

Test real devices and latency under a full server. Measure physics/network cost, frame time, memory and effects budget. Profile the 151-entry catalogue and repeated viewport creation on low-end mobile hardware. Validate animation permissions, imported rig physics and every final model. Review economy balance, competitive fairness and data budgets. Keep the experience private until these pass; no live publication was performed here.
