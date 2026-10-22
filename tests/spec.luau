local Rules=modules.Rules
local DB=modules.PokemonDatabase
local Config=modules.Config
check(#DB==151,"All Kanto slots exist")
local names={}
for id,entry in ipairs(DB) do
 check(entry.ID==id and not names[entry.Name],"Unique sequential catalogue ID")
 names[entry.Name]=true
 check(entry.Stats.HP==100,"Rarity cannot increase HP")
 check(#entry.Abilities==4,"Four abilities per entry")
 for _,key in ipairs(entry.Abilities) do check(modules.AbilityDatabase[key]~=nil,"Ability is implemented") end
 check(modules.PokemonModelSettings[id]~=nil,"Model settings exist")
end
check(DB[25].Type1=="Electric" and DB[81].Type2=="Steel" and DB[122].Type2=="Fairy","Modern typings")
check(Rules.Search(DB[25],"025") and Rules.Search(DB[25],"electric") and not Rules.Search(DB[25],"water"),"Search by number and type")
check(Rules.ValidateTeam({1,4,7},{['1']={},['4']={},['7']={}}),"Valid owned team")
check(not Rules.ValidateTeam({1,1,4},{['1']={},['4']={}}),"Duplicate rejected")
check(not Rules.ValidateTeam({1,4,151},{['1']={},['4']={},['7']={}}),"Unowned rejected")
check(not Rules.ValidateTeam({1,4},{['1']={},['4']={}}),"Short team rejected")
check(not Rules.ValidateTeam("bad",{}),"Malformed team rejected")
check(not Rules.IsFinite(0/0) and not Rules.IsFinite(math.huge),"Nonfinite input rejected")
check(Rules.RatingDelta(600,600,true)==12 and Rules.RatingDelta(600,600,false)==-12,"Symmetric MMR")
check(Rules.Rank(0)=="Bronze" and Rules.Rank(1800)=="Champion","Rank thresholds")
check(Rules.Winner({Living=2,Health=.2},{Living=1,Health=1})==1,"Living creatures tiebreak first")
check(Rules.Winner({Living=2,Health=.7},{Living=2,Health=.9})==2,"HP tiebreak second")
check(Rules.Winner({Living=1,Health=.5},{Living=1,Health=.5})==nil,"Exact tie triggers sudden death")
local profile=Rules.NewProfile()
local player={UserId=123,Parent=true,Kick=function(self,message) self.Kicked=message end}
local data={Get=function() return profile end}
local economy=modules.EconomyService; economy:Init(data)
local unlocked={}
for _=1,3 do
 local ok,reward=economy:OpenCrate(player,"Starter")
 check(ok and reward.New and not unlocked[reward.ID],"Starter guarantees distinct creature")
 unlocked[reward.ID]=true
end
check(#profile.Team==3 and Rules.ValidateTeam(profile.Team,profile.Owned),"Crates auto-fill valid initial team")
check(not economy:OpenCrate(player,"Starter"),"Cannot open unowned crate")
check(not economy:Purchase(player,"Crate","Starter"),"Starter crates cannot be purchased")
check(not economy:Purchase(player,"Creature",150),"Purchase rejects insufficient funds")
profile.Coins=100000
check(economy:Purchase(player,"Creature",150),"Server-priced purchase")
local coins=profile.Coins
check(not economy:Purchase(player,"Creature",150) and profile.Coins==coins,"Owned purchase doesn't charge")
check(not economy:SetTeam(player,{150,150,150}),"Invalid team mutation rejected")
check(economy:Daily(player),"Daily claim")
coins=profile.Coins
check(not economy:Daily(player) and coins==profile.Coins,"Daily replay rejected")
for id in ipairs(DB) do profile.Owned[tostring(id)]={Mastery=0,Level=1} end
profile.Crates.Basic=1; coins=profile.Coins
local ok,duplicate=economy:OpenCrate(player,"Basic")
check(ok and not duplicate.New and profile.Coins==coins+100 and profile.Owned[tostring(duplicate.ID)].Mastery==10,"Duplicate compensation")
local seen={}
profile.Crates.Basic=2000
for _=1,2000 do
 local opened,reward=economy:OpenCrate(player,"Basic")
 check(opened and Config.Crates.Basic.Weights[DB[reward.ID].Rarity]~=nil,"Crate pool never leaks disallowed rarity")
 seen[DB[reward.ID].Rarity]=true
end
check(seen.Common and seen.Uncommon and seen.Rare and seen.Epic,"Crate sampling exercises every weighted rarity")
local casual={ID="casual",Ranked=false}
local mmr=profile.MMR
local before=profile.MatchesPlayed
economy:Reward(player,casual,true,600)
check(profile.MMR==mmr and profile.MatchesPlayed==before+1,"Casual rewards leave MMR alone")
coins=profile.Coins
economy:Reward(player,casual,true,600)
check(profile.Coins==coins and profile.MatchesPlayed==before+1,"Result reward idempotency")
economy:Reward(player,{ID="ranked",Ranked=true},false,600)
check(profile.MMR<mmr and profile.Losses==1,"Ranked loss changes rating")
coins=profile.Coins
economy:Reward(player,{ID="practice",Practice=true},true,600)
check(profile.Coins==coins,"Practice grants no currency")
local queue=modules.MatchmakingService
check(queue:Compatible({Players={{MMR=600,Level=1,Joined=os.clock()},{MMR=650,Level=2,Joined=os.clock()}}},true),"Nearby ranked candidates allowed")
check(not queue:Compatible({Players={{MMR=600,Level=1,Joined=os.clock()},{MMR=1600,Level=30,Joined=os.clock()}}},true),"Beginner protection and MMR filtering")
local combat=modules.CombatService
check(not combat:Attack(nil,1,{}),"Malformed aim rejected")
check(not combat:Switch(nil,1,false),"Missing actor rejected")
local persistence=modules.DataService
local loaded=persistence:Load(player)
check(loaded~=nil and records.u_123.Lease.Owner=="test-job","Data lease acquired")
loaded.Coins=42
check(persistence:Save(player,false) and records.u_123.Profile.Coins==42,"Save persists authoritative state")
records.u_124={Profile=Rules.NewProfile(),Lease={Owner="other-job",Expires=os.time()+180}}
local other={UserId=124,Kick=player.Kick}
check(persistence:Load(other)==nil and other.Kicked~=nil,"Active foreign session cannot be loaded")
mockFailure=true
local offline={UserId=125,Kick=player.Kick}
check(persistence:Load(offline)==nil and records.u_125==nil,"Load failure never overwrites with default data")
mockFailure=false
records.u_123.Lease.Owner="another-server"
check(not persistence:Save(player,false),"Lost lease blocks writes")
records.u_123.Lease.Owner="test-job"
check(persistence:Save(player,true) and records.u_123.Lease==nil,"Release clears session lease")
-- Execute actual combat decisions against deterministic engine primitives.
local effects={}
local battle={Phase="Battle",Center=Vector3.zero,Radius=55,ActorsFolder={},Actors={}}
local function actor(id,side,pos)
 local a={ID=id,Side=side,Team={1,4,7},Health={100,100,100},Active=1,Cooldowns={{},{},{}},Switches=2,Potions=1,Stamina=100,Generation=1,Match=battle,
 Root={Position=pos,CFrame=CFrame.new(pos)},Humanoid={Health=100,Move=function() end},Character={PivotTo=function() end}}
 table.insert(battle.Actors,a); return a
end
local a=actor("a",1,Vector3.zero)
local b=actor("b",2,Vector3.new(0,0,-5))
local friend=actor("friend",1,Vector3.new(0,0,-4))
local harnessMatches={Active={battle},Broadcast=function(_,_,kind,payload) table.insert(effects,{kind,payload}) end,
 Defeat=function(_,target) target.Eliminated=true end,SendState=function() end,
 Creatures={Spawn=function(_,target) target.Spawned=true end}}
combat:Init(harnessMatches,{})
check(combat:Attack(a,0,Vector3.new(0,0,-1)),"Valid server attack accepted")
check(b.Health[1]==100,"Startup delays hit confirmation")
check(not combat:Attack(a,0,Vector3.new(0,0,-1)),"Attack spam rejected during recovery")
flush()
check(b.Health[1]==93 and friend.Health[1]==100,"Server hitbox damages enemy once and excludes friendly fire")
clock+=1
wall=true
combat:Attack(a,0,Vector3.new(0,0,-1)); flush()
check(b.Health[1]==93,"Occluded melee cannot damage through cover")
wall=false; clock+=1
b.InvulnerableUntil=clock+1
check(not combat:Damage(a,b,modules.AbilityDatabase.Basic,a.Root.Position),"Dash invulnerability prevents hit")
clock+=2; b.Guarding=true
combat:Damage(a,b,modules.AbilityDatabase.Basic,a.Root.Position)
check(b.Health[1]==90 and b.Stamina==80,"Guard reduction and server stamina charge")
b.StunnedUntil=clock+2
combat:Guard(b,false)
check(not b.Guarding,"Guard release works while stunned")
b.StunnedUntil=0; b.ShieldUntil=clock+1
combat:Damage(a,b,modules.AbilityDatabase.Basic,a.Root.Position)
check(b.Health[1]==88,"Ward damage reduction")
b.ShieldUntil=0; b.StunnedUntil=0; b.Health[1]=50
check(combat:Potion(b) and b.Potions==0,"Single potion consumed server-side")
flush()
check(b.Health[1]==75 and not combat:Potion(b),"Potion heals 25, cannot be reused")
b.Potions=1; b.Health[1]=40; clock+=2
check(combat:Potion(b),"Potion begins channel")
combat:Damage(a,b,modules.AbilityDatabase.Basic,a.Root.Position); flush()
check(b.Health[1]==33,"Damage cancels potion channel")
clock+=2; b.StunnedUntil=0
b.Cooldowns[1].Pulse=clock+10
check(combat:Switch(b,2,false) and b.Switches==1,"Voluntary switch charges one budget")
check(not combat:Switch(b,3,true),"Cannot restart a switch during its transition")
flush()
check(b.Active==2 and b.Spawned and b.Health[1]==33 and b.Cooldowns[1].Pulse==clock+10,"Switch preserves bench HP and cooldown state")
clock+=2
check(combat:Switch(b,1,false),"Second voluntary switch available"); flush(); clock+=2
check(not combat:Switch(b,2,false),"Third voluntary switch forbidden")
b.Health[1]=0
check(combat:Switch(b,3,true),"Forced replacement ignores voluntary budget"); flush()
check(b.Active==3 and b.Switches==0,"Forced replacement does not spend extra budget")
check(not combat:Attack(a,9,Vector3.new(0,0,-1)),"Invalid ability slot rejected")
battle.Phase="Results"; clock+=100
check(not combat:Attack(a,1,Vector3.new(0,0,-1)),"No attacks after result")
battle.Phase="Battle"; clock+=100
b.Health[3]=100; b.Guarding=false; b.Root.Position=Vector3.new(0,0,-20); b.Root.CFrame=CFrame.new(b.Root.Position)
check(combat:Attack(a,1,Vector3.new(0,0,-1)),"Projectile accepted after cooldown")
flush()
check(b.Health[3]==100,"Projectile does not instantly claim target damage")
combat:Step(.1); combat:Step(.1); combat:Step(.1)
check(b.Health[3]==88 and #combat.Projectiles==0,"Server swept projectile hits once at authoritative position")
clock+=10; wall=true
combat:Attack(a,1,Vector3.new(0,0,-1)); flush(); combat:Step(.1)
check(b.Health[3]==88 and #combat.Projectiles==0,"Wall terminates projectile before enemy")
wall=false
clock+=10
b.Root.Position=Vector3.new(0,0,-5); b.Health[3]=100
local hp=b.Health[3]
a.Humanoid.FloorMaterial=Enum.Material.Air
check(combat:Attack(a,0,Vector3.new(0,0,-1)),"Airborne strike starts a ground slam")
flush()
check(b.Health[3]<hp,"Ground slam applies authoritative area damage")
a.Humanoid.FloorMaterial=nil; clock+=1; a.BasicCombo=3; a.LastBasic=clock
combat:Attack(a,0,Vector3.new(0,0,-1)); flush()
check(b.Root.AssemblyLinearVelocity.Y==27,"Fourth basic hit launches target")
print("PASS: "..passed.." domain assertions (catalogue, economy, queue policy, persistence, input rejection)")
