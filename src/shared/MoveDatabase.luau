-- Detailed moves adapt to the original AbilityDatabase contract; old IDs remain valid.
local Moves={}
local function move(id,display,kind,damage,cd,startup,active,lag,range,size,knock,stun)
 local category=({Projectile="Ranged",Dash="Mobility",Shield="Defense",AOE="Finisher",Melee="Combo"})[kind]
 return {MoveID=id,Name=display,DisplayName=string.upper(display),Description="",Type="Normal",Category=category,Kind=kind,
 Damage=damage,Cooldown=cd,StartupTime=startup,ActiveTime=active,EndLag=lag,Range=range,ProjectileSpeed=85,AOERadius=kind=="AOE" and range or 0,
 Knockback=knock,VerticalKnockback=knock*.2,StunTime=stun,Hitstop=damage>=20 and .065 or .03,HitboxType=kind,HitboxSize=size,
 MovementLock=true,CanUseInAir=true,CanCancel=false,ComboStarter=kind=="Melee" or kind=="Dash",ComboExtender=kind=="Projectile",ComboFinisher=kind=="AOE",
 ArmorFrames=0,InvulnerabilityFrames=0,StatusEffect="None",StatusDuration=0,VFX=id,Sound=id,Animation=id,CameraShake=damage>=20 and "Medium" or "Low",
 CameraFOVEffect=damage>=20 and 5 or 1,Difficulty=kind=="Dash" and "Medium" or "Easy",Tags={category},ComboTip="M1 → M1 → mobility → pulse → signature",
 Startup=startup,Active=active,Endlag=lag,Stun=stun,EnergyRequirement=0}
end
Moves.Basic=move("Basic","Strike","Melee",7,.34,.09,.1,.2,7,Vector3.new(6,6,7),10,.18)
Moves.Pulse=move("Pulse","Type Pulse","Projectile",12,3,.2,.1,.25,65,Vector3.new(4,4,4),12,.25)
Moves.Rush=move("Rush","Rush","Dash",9,6,.12,.18,.3,17,Vector3.new(6,6,12),25,.4)
Moves.Ward=move("Ward","Guard Field","Shield",0,10,.15,2,.2,0,Vector3.one,0,0)
Moves.Nova=move("Nova","Signature Nova","AOE",24,18,.65,.15,.7,14,Vector3.new(28,12,28),35,.7)
Moves.Ward.StatusEffects={Shield=2}
local names={
 Fire={"Ember Lance","Flare Rush","Cinder Guard","Inferno Ring"},Water={"Aqua Lance","Riptide Rush","Tidal Guard","Ocean Break"},
 Electric={"Thunder Jolt","Volt Dash","Static Field","Thunderstorm"},Grass={"Seed Lance","Vine Rush","Leaf Guard","Bloom Burst"},
 Ice={"Frost Shard","Glacier Step","Crystal Guard","Polar Break"},Fighting={"Force Wave","Meteor Step","Iron Guard","Arena Breaker"},
 Poison={"Venom Bolt","Toxic Rush","Antidote Veil","Venom Bloom"},Ground={"Sand Lance","Dune Rush","Stone Guard","Fault Line"},
 Flying={"Gale Lance","Jetstream","Wind Guard","Sky Break"},Psychic={"Mind Lance","Phase Step","Thought Barrier","Psychic Surge"},
 Bug={"Silk Shot","Swarm Rush","Cocoon Guard","Hive Burst"},Rock={"Shard Lance","Boulder Rush","Granite Guard","Stone Quake"},
 Ghost={"Shadow Bolt","Phantom Step","Spirit Veil","Spectral Night"},Dragon={"Dragon Pulse","Drake Rush","Scale Guard","Dragon Roar"},
 Dark={"Night Lance","Eclipse Step","Dark Veil","Midnight Fall"},Steel={"Metal Shot","Chrome Rush","Alloy Guard","Steel Tempest"},
 Fairy={"Glimmer Bolt","Pixie Step","Wish Guard","Starlight Bloom"},Normal={"Power Pulse","Quick Rush","Focus Guard","Impact Burst"},
}
local descriptions={
 "Launch a swept projectile. Cover blocks it; confirm a combo before casting.",
 "Rush forward into a close-range strike. Walls stop movement; use it to extend a grounded combo.",
 "Create a two-second ward that reduces incoming damage. Bait a signature move before committing.",
 "Telegraph a close-range signature burst. Enemies can escape during startup; use after a confirmed stun.",
}
for element,labels in pairs(names) do
 for i,base in ipairs({"Pulse","Rush","Ward","Nova"}) do
  local id=element..base; local m=table.clone(Moves[base]); m.MoveID=id; m.Name=labels[i]; m.DisplayName=string.upper(labels[i]); m.Type=element
  m.Description=descriptions[i]; m.VFX=element; m.Animation="Ability"..i; m.Sound="Ability"..i
  m.Tags={m.Category,element,i==4 and "Signature" or "Combo"}; m.StatusEffect=i==3 and "Shield" or "None"; m.StatusDuration=i==3 and 2 or 0
  Moves[id]=m
 end
end
Moves.ElectricRush.VerticalKnockback=6
Moves.ElectricRush.ComboExtender=true
Moves.GrassNova.Description="Bloom in a telegraphed ring. The standardized burst is best used after Vine Rush confirms a hit."
-- Authored launch roster. These vary timing, reach and combo purpose while
-- retaining the same validated handlers and standardized survivability.
local function authored(id,base,name,description,changes,tip)
 local m=table.clone(Moves[base]); m.MoveID=id; m.Name=name; m.DisplayName=string.upper(name); m.Description=description
 for key,value in pairs(changes or {}) do m[key]=value end
 m.Startup=m.StartupTime; m.Active=m.ActiveTime; m.Endlag=m.EndLag; m.Stun=m.StunTime; m.HitboxType=m.Kind
 m.AOERadius=m.Kind=="AOE" and m.Range or 0; m.ComboTip=tip or m.ComboTip
 m.Tags={m.Category,m.Type}
 if m.ComboStarter then table.insert(m.Tags,"Combo Starter") end
 if m.ComboExtender then table.insert(m.Tags,"Combo Extender") end
 if m.ComboFinisher then table.insert(m.Tags,"Finisher") end
 Moves[id]=m
end
authored("RazorLeaf","GrassPulse","Razor Leaf","A fast leaf projectile with moderate reach. Use after Vine Whip confirms a hit.",{Damage=10,Cooldown=2.8,Range=52,ProjectileSpeed=90},"M1 → M1 → Vine Whip → Razor Leaf")
authored("VineWhip","GrassRush","Vine Whip","Strike a narrow forward lane without moving. Short knockback keeps the opponent close for a follow-up.",{Kind="Melee",Category="Control",Damage=10,Cooldown=5.3,Range=13,Knockback=5,VerticalKnockback=3,StunTime=.35,HitboxSize=Vector3.new(5,6,13)},"Vine Whip → M1 → Razor Leaf")
authored("LeafGuard","GrassWard","Leaf Guard","A two-second leaf ward reduces incoming damage. Its long cooldown leaves an opening after it fades.",{})
authored("SolarBloom","GrassNova","Solar Bloom","Telegraph a wide bloom around the creature. The long startup rewards a confirmed combo instead of blind activation.",{Damage=22,Range=15,StartupTime=.75},"Vine Whip → M1 finisher → Solar Bloom")
authored("EmberBolt","FirePulse","Ember Bolt","Release a compact ember with a quick startup. Terrain blocks its travel.",{Damage=11,StartupTime=.18,Range=60})
authored("FlameWheel","FireRush","Flame Wheel","Rush through a short forward lane and strike at the destination. A missed rush can be punished during recovery.",{Damage=11,Cooldown=7,Range=15})
authored("SmokeVeil","FireWard","Smoke Veil","A brief cinder veil reduces incoming damage. It does not make the creature invisible or untargetable.",{ActiveTime=1.7,StatusDuration=1.7,Cooldown=9.5})
authored("FlareBurst","FireNova","Flare Burst","Release a close fire burst after a visible charge. The short radius rewards precise spacing.",{Damage=25,Range=12,StartupTime=.6,Cooldown=19})
authored("WaterJet","WaterPulse","Water Jet","A fast, long-reaching water projectile. The deliberate startup gives opponents a chance to dodge.",{Damage=12,Cooldown=3.4,Range=70,ProjectileSpeed=100,StartupTime=.24})
authored("AquaRush","WaterRush","Aqua Rush","Slide forward into a light impact. Lower damage is exchanged for extra reach and a shorter cooldown.",{Damage=8,Cooldown=5.5,Range=19,Knockback=20})
authored("BubbleShield","WaterWard","Bubble Shield","A longer bubble ward reduces damage. It shares the same fair hitbox as every other creature.",{ActiveTime=2.3,StatusDuration=2.3,Cooldown=11})
authored("HydroBurst","WaterNova","Hydro Burst","A telegraphed ring of water pushes opponents away and creates breathing room.",{Damage=22,Range=14,Knockback=40,VerticalKnockback=6})
authored("ThunderJolt","ElectricPulse","Thunder Jolt","A bright electrical projectile. Confirm the hit before committing to a close-range signature.",{Damage=12,Cooldown=3,ProjectileSpeed=95})
authored("ThunderDash","ElectricRush","Thunder Dash","Dash forward in electricity. Enemies struck at the destination launch slightly upward for a basic-attack follow-up.",{Damage=14,Cooldown=8,Range=18,Knockback=8,VerticalKnockback=6,StunTime=.35,ComboStarter=true,ComboExtender=true},"M1 → M1 → Thunder Dash → M1 → Thunder Jolt")
authored("StaticGuard","ElectricWard","Static Field","Charge a protective static ward. Damage is reduced for two seconds; it is not an invulnerability effect.",{})
authored("Thunderstorm","ElectricNova","Thunderstorm","Announce a short electrical storm around the creature. Opponents can escape the clearly telegraphed startup.",{Damage=24,Cooldown=20,Range=13,StartupTime=.75})
authored("ShadowBall","GhostPulse","Shadow Ball","A slower shadow projectile with slightly higher impact. Cover and dodging remain reliable counters.",{Damage=13,ProjectileSpeed=65,StartupTime=.3,Range=60})
authored("PhantomRush","GhostRush","Phantom Step","A shadow-lined rush that stops at walls. It cannot phase through cover or ignore arena boundaries.",{Damage=8,Range=20,Cooldown=7})
authored("SpiritWard","GhostWard","Spirit Veil","A spectral ward reduces incoming damage while preserving the standardized hurtbox.",{})
authored("NightBloom","GhostNova","Spectral Night","A deliberately slow spectral blast. Confirm a stun before its long cast.",{Damage=25,StartupTime=.85,Range=14})
authored("DragonPulse","DragonPulse","Dragon Pulse","A balanced dragon-energy projectile with clear travel and impact phases.",{})
authored("DragonRush","DragonRush","Drake Rush","Commit to a heavy rush with slightly longer recovery. Missing creates an opening.",{Damage=12,EndLag=.4,Cooldown=7.5,Range=16})
authored("ScaleWard","DragonWard","Scale Guard","Protective dragon energy reduces incoming damage for a fixed duration.",{})
authored("DragonTempest","DragonNova","Dragon Tempest","A wide dragon-energy finisher with a long telegraph and cooldown.",{Damage=23,Range=15,StartupTime=.8,Cooldown=20})
authored("PsyBolt","PsychicPulse","Mind Lance","A focused psychic projectile. Its damage and hitbox remain comparable to other ranged moves.",{})
authored("PhaseRush","PsychicRush","Phase Rush","A fast psychic rush. Despite its visual flash it still respects physical cover.",{Damage=8,Range=19,Cooldown=7})
authored("ThoughtWard","PsychicWard","Thought Barrier","A thought barrier reduces incoming damage; attacks are never reflected or countered automatically.",{})
authored("PsychicBreak","PsychicNova","Psychic Break","Charge an expanding psychic burst. Opponents can dodge out before the active window.",{Damage=23,Range=15,StartupTime=.8})
return Moves
