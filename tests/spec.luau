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
check(storeOpens==0,"Importing DataService must not open a DataStore")
studio=true; mockMode=true
local localPlayer={UserId=126,Parent=true,Kick=player.Kick}
local mockProfile=persistence:Load(localPlayer)
check(mockProfile~=nil and persistence.Records[localPlayer].Mock,"Unpublished Studio opens a temporary profile")
check(storeOpens==0 and persistence:Save(localPlayer,false),"Studio mock loading/saving never contacts DataStore")
local boards=modules.LeaderboardService; boards:Init(persistence); boards:Publish(localPlayer); boards:Refresh()
check(orderedStoreOpens==0,"Studio mock leaderboards never contact live API")
persistence:Remove(localPlayer)
check(persistence:Get(localPlayer)==nil,"Studio mock session cleans up")
studio=false
local deniedPlayer={UserId=127,Parent=true,Kick=player.Kick}
check(persistence:Load(deniedPlayer)==nil and deniedPlayer.Kicked~=nil,"Production never uses mock profiles even when flag is enabled")
check(records.u_127==nil,"Store-open failure never creates replacement data")
mockMode=false; storeOpenFailure=false
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
check(b.Health[3]==90 and #combat.Projectiles==0,"Server swept projectile hits once at authoritative position")
clock+=10; wall=true
combat:Attack(a,1,Vector3.new(0,0,-1)); flush(); combat:Step(.1)
check(b.Health[3]==90 and #combat.Projectiles==0,"Wall terminates projectile before enemy")
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
-- Detailed move metadata and backward compatibility.
local fields={"MoveID","Name","DisplayName","Description","Type","Category","Damage","Cooldown","StartupTime","ActiveTime","EndLag","Range","ProjectileSpeed","AOERadius","Knockback","VerticalKnockback","StunTime","Hitstop","HitboxType","HitboxSize","MovementLock","CanUseInAir","CanCancel","ComboStarter","ComboExtender","ComboFinisher","ArmorFrames","InvulnerabilityFrames","StatusEffect","StatusDuration","VFX","Sound","Animation","CameraShake","CameraFOVEffect"}
for key,move in pairs(modules.MoveDatabase) do
 for _,field in ipairs(fields) do check(move[field]~=nil,key.." missing "..field) end
 check(move.Startup==move.StartupTime and move.Endlag==move.EndLag and move.Stun==move.StunTime,"Legacy timing adapter stays consistent")
 check(move.Hitstop<=.08 and move.Hitstop>=0,"Visual hitstop stays bounded")
end
check(modules.AbilityDatabase.Pulse==modules.MoveDatabase.Pulse,"Legacy move keys preserved")
for _,entry in ipairs(DB) do check(modules.MoveDatabase[entry.Abilities[1]].Type==entry.Type1,"Elemental catalogue binding") end
-- Missing Workspace attribute must not break local unpublished Studio testing.
studio=true; mockMode=nil
local missingFlag={UserId=180,Parent=true,Kick=player.Kick}
local opensBefore=storeOpens
check(persistence:Load(missingFlag)~=nil and storeOpens==opensBefore,"Missing Studio attribute defaults to temporary profiles")
persistence:Remove(missingFlag); studio=false; mockMode=false
-- Actual queue/match services through each mode: countdown cancellation, battle,
-- elimination, rewards, results and lobby return. Engine physics is not mocked as passing.
local matches=modules.MatchService
local matchEconomy=modules.EconomyService
for _,mode in ipairs({"Casual1","Ranked1","Casual2","Ranked2","Casual3","Ranked3","Practice"}) do
 local cfg=Config.Modes[mode]; local profiles={}; local players={}; local sent={}
 local dataService={Get=function(_,p) return profiles[p] end,Public=function(_,p) return profiles[p] end,Save=function() return true end}
 local world={Arenas={FindFirstChild=function() return nil end},Screens={},Pads={},CreateArena=function()
  return {Destroy=function(self) self.Destroyed=true end},{},Vector3.zero,55
 end}
 for key in pairs(Config.Modes) do world.Screens[key]={}; world.Pads[key]=Vector3.zero end
 local creatures={Spawn=function(_,actor,_,cf)
  actor.Character={Destroy=function() end,GetDescendants=function() return {} end}; actor.Root={Position=cf.Position,CFrame=cf,AssemblyLinearVelocity=Vector3.zero}; actor.Humanoid={Health=100,Move=function() end}; return actor.Character
 end}
 for i=1,(cfg.Practice and 1 or cfg.Size*2) do
  local p={UserId=1000+i,Name="Player"..i,DisplayName="Player"..i,Parent=true,LoadCharacter=function(self) self.Respawns=(self.Respawns or 0)+1 end}
  local profile=Rules.NewProfile(); profile.Team={1,4,7}; profile.Owned={['1']={Level=1,Mastery=0},['4']={Level=1,Mastery=0},['7']={Level=1,Mastery=0}}; profiles[p]=profile; table.insert(players,p)
 end
 local event={FireClient=function(_,p,kind,payload) table.insert(sent,{Player=p,Kind=kind,Data=payload}) end}
 matches.Active={}; matches.ByPlayer={}; matches:Init(dataService,matchEconomy,creatures,world,event); matchEconomy:Init(dataService)
 combat:Init(matches,event); matches.Combat=combat
 queue.Membership={}; queue:Init(dataService,matches,world,event)
 for _,p in ipairs(players) do check(queue:Join(p,mode,{Difficulty="Hard"}),"Queue accepts valid team for "..mode) end
 if not cfg.Practice then
  queue:Step(.2); check(queue.Queues[mode].Countdown~=nil,"Full mode starts countdown")
  clock+=5; queue:Leave(players[1]); check(queue.Queues[mode].Countdown==nil,"Leaving cancels countdown")
  queue:Join(players[1],mode); queue:Step(.2); clock+=10; queue:Step(.2)
 end
 local match=next(matches.Active) and select(2,next(matches.Active))
 check(match~=nil and match.Phase=="Preview","Mode creates preview: "..mode)
 local count={0,0}; for _,a in ipairs(match.Actors) do count[a.Side]+=1 end
 check(count[1]==cfg.Size and count[2]==cfg.Size,"Balanced team sizes for "..mode)
 clock+=3; matches:Step(3); check(match.Phase=="Battle","Preview becomes battle")
 local viewer=players[1]; local own=matches.ByPlayer[viewer]; own.Cooldowns[1].GrassPulse=clock+3
 local snapshot=matches:Snapshot(match,viewer)
 for _,a in ipairs(snapshot.Actors) do
  check(a.ID==own.ID or next(a.Cooldowns)==nil,"Snapshot does not expose another player's cooldowns")
 end
 if mode=="Casual1" then
  players[2].Parent=false; matches:Leave(players[2],true)
  check(profiles[players[2]].Losses==1,"Disconnect applies one forfeit loss")
 elseif mode=="Ranked1" then
  matches:Leave(players[2],false)
  check(profiles[players[2]].Losses==1,"Leave Match applies one forfeit loss")
 elseif mode=="Practice" then
  local bots=modules.BotService; bots:Init(matches,combat); bots:Step(.1)
  check(match.Actors[2].NextThink~=nil,"Practice bot executes its decision path")
 end
 for _,a in ipairs(match.Actors) do
  if a.Side==2 then a.Health={0,0,0}; matches:Defeat(a) end
 end
 check(match.Phase=="Results","Team elimination finishes "..mode)
 for _,p in ipairs(players) do
  if cfg.Practice then check(profiles[p].MatchesPlayed==0,"Practice cannot farm results")
  else
   check(profiles[p].MatchesPlayed==1,"Match counted exactly once")
   check(cfg.Ranked and profiles[p].MMR~=600 or not cfg.Ranked and profiles[p].MMR==600,"Rating respects mode")
  end
 end
 check(#sent>0,"Mode sends authoritative presentation events")
 clock+=11; matches:Step(11); flush()
 check(next(matches.Active)==nil and next(matches.ByPlayer)==nil,"Match cleans up and returns players")
 for _,p in ipairs(players) do check(p.Parent and p.Respawns==1 or not p.Parent and p.Respawns==nil,"One lobby respawn per connected player; no respawn on disconnect") end
end
local originalFinish=matches.Finish
matches.Finish=function(self,m,w) m.TestWinner=w; originalFinish(self,m,w) end
local function timerMatch(healthA,healthB)
 local m={Phase="Battle",EndsAt=clock,StartedAt=clock-60,Actors={},Training=false}
 for i,health in ipairs({healthA,healthB}) do table.insert(m.Actors,{ID=tostring(i),Name="Timer"..i,Side=i,Team={1,4,7},Active=1,Health=health,Root={Position=Vector3.zero},Humanoid={Health=100},Match=m}) end
 return m
end
local tied=timerMatch({100,100,100},{100,100,100}); matches:CheckWinner(tied,true)
check(tied.SuddenDeath and tied.Phase=="Battle","Exact timer tie starts sudden death without finishing")
local living=timerMatch({100,0,0},{1,1,0}); matches:CheckWinner(living,true)
check(living.TestWinner==2,"Actual match timer prioritizes living creatures")
local percentage=timerMatch({80,100,100},{100,100,100}); matches:CheckWinner(percentage,true)
check(percentage.TestWinner==2,"Actual match timer resolves remaining HP percentage")
local draw=timerMatch({0,0,0},{0,0,0}); matches:CheckWinner(draw,true)
check(draw.TestWinner==0,"Simultaneous team elimination is an impartial draw")
matches.Finish=originalFinish
print("PASS: "..passed.." domain assertions (catalogue, economy, queue policy, persistence, input rejection)")
