local Shared=game.ReplicatedStorage.Shared
local Abilities=require(Shared.AbilityDatabase)
local Database=require(Shared.PokemonDatabase)
local Rules=require(Shared.Rules)
local Config=require(Shared.Config)
local Combat={Projectiles={}}
local function stats(actor)
 actor.Stats=actor.Stats or {DamageDealt=0,DamageTaken=0,Knockouts=0,Assists=0,Switches=0,PotionsUsed=0,LongestCombo=0,Attacks=0,Hits=0}
 return actor.Stats
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function direction(v)
 if typeof(v)~="Vector3" or not Rules.IsFinite(v.X) or not Rules.IsFinite(v.Y) or not Rules.IsFinite(v.Z) then return nil end
 local d=flat(v); return d.Magnitude>.01 and d.Unit or nil
end
function Combat:Init(matches,event) self.Matches=matches; self.Event=event end
function Combat:Ready(actor)
 local now=os.clock()
 return actor and not actor.Eliminated and actor.Root and actor.Match.Phase=="Battle" and now>=(actor.StunnedUntil or 0) and now>=(actor.LockUntil or 0)
end
function Combat:Move(actor,vector,jump)
 if typeof(vector)~="Vector3" or not Rules.IsFinite(vector.X) or not Rules.IsFinite(vector.Z) then return end
 if not actor or not actor.Humanoid then return end
 local move=flat(vector); if move.Magnitude>1 then move=move.Unit end
 actor.Move=move; actor.LastMove=os.clock()
 if self:Ready(actor) then
  actor.Humanoid:Move(move,false)
  if jump==true and actor.Humanoid.FloorMaterial~=Enum.Material.Air then actor.Humanoid.Jump=true end
 end
end
function Combat:Effect(actor,name,position,extra)
 self.Matches:Broadcast(actor.Match,"Effect",{ActorID=actor.ID,Name=name,Position=position or actor.Root.Position,Extra=extra,PokemonID=actor.Team[actor.Active]})
end
function Combat:Displace(actor,delta)
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={actor.Match.ActorsFolder}
 local origin=actor.Root.Position
 local result=workspace:Raycast(origin,delta,params)
 local target=result and (result.Position-delta.Unit*3) or (origin+delta)
 local center=actor.Match.Center; local half=actor.Match.Radius-4
 target=Vector3.new(math.clamp(target.X,center.X-half,center.X+half),math.clamp(target.Y,center.Y+3,center.Y+20),math.clamp(target.Z,center.Z-half,center.Z+half))
 actor.Character:PivotTo(CFrame.lookAt(target,target+actor.Root.CFrame.LookVector))
 actor.LastPosition=target
end
function Combat:Dash(actor,aim)
 local d=direction(aim)
 if not d or not self:Ready(actor) or os.clock()<(actor.DashUntil or 0) then return false end
 actor.DashUntil=os.clock()+2.2; actor.InvulnerableUntil=os.clock()+.15; actor.LockUntil=os.clock()+.15
 actor.PotionToken=nil
 self:Displace(actor,d*25); self:Effect(actor,"Dash")
 return true
end
function Combat:Damage(attacker,target,ability,point,multiplier)
 local now=os.clock()
 if target.Eliminated or target.Side==attacker.Side or target.Match~=attacker.Match or now<(target.InvulnerableUntil or 0) then return false end
 if not target.Root or target.Health[target.Active]<=0 then return false end
 local damage=ability.Damage*(multiplier or 1)
 if now<(target.ShieldUntil or 0) then damage*=.35 end
 if target.Guarding and target.Stamina>0 then damage*=.4; target.Stamina=math.max(0,target.Stamina-20); if target.Stamina==0 then target.Guarding=false end end
 damage=math.min(target.Health[target.Active],math.round(damage))
 target.Health[target.Active]=math.max(0,target.Health[target.Active]-damage)
 local sourceStats=stats(attacker); local targetStats=stats(target)
 sourceStats.DamageDealt+=damage; targetStats.DamageTaken+=damage
 target.DamageSources=target.DamageSources or {}; target.DamageSources[attacker.ID]=now
 if ability.ActionSerial then
  attacker.HitActions=attacker.HitActions or {}
  if not attacker.HitActions[ability.ActionSerial] then attacker.HitActions[ability.ActionSerial]=true; sourceStats.Hits+=1 end
 end
 target.LastDamage=now; target.PotionToken=nil; target.StunnedUntil=now+ability.Stun
 target.Humanoid.Health=math.max(1,target.Health[target.Active])
 local d=flat(target.Root.Position-point)
 if d.Magnitude>.01 then target.Root.AssemblyLinearVelocity=d.Unit*ability.Knockback+Vector3.new(0,(multiplier or 1)>1 and 27 or ability.VerticalKnockback or ability.Knockback*.2,0) end
 attacker.ComboDamage=(now-(attacker.LastHit or 0)<2 and (attacker.ComboDamage or 0) or 0)+damage
 attacker.ComboCount=(now-(attacker.LastHit or 0)<2 and (attacker.ComboCount or 0) or 0)+1
 stats(attacker).LongestCombo=math.max(stats(attacker).LongestCombo,attacker.ComboCount)
 attacker.LastHit=now; attacker.TotalDamage=(attacker.TotalDamage or 0)+damage
 attacker.FirstHit=attacker.FirstHit or now
 self:Effect(target,"Hit",target.Root.Position,{Damage=damage,AttackerID=attacker.ID,Combo=attacker.ComboCount,ComboDamage=attacker.ComboDamage,DPS=attacker.TotalDamage/math.max(1,now-attacker.FirstHit),MoveID=ability.MoveID,Type=ability.Type or "Normal",Hitstop=(multiplier or 1)>1 and .06 or ability.Hitstop or .03,Heavy=damage>=15 or (multiplier or 1)>1,CameraShake=ability.CameraShake,CameraFOVEffect=ability.CameraFOVEffect})
 if target.Health[target.Active]==0 then
  stats(attacker).Knockouts+=1
  for _,ally in ipairs(attacker.Match.Actors) do
   if ally~=attacker and ally.Side==attacker.Side and now-(target.DamageSources[ally.ID] or -100)<8 then stats(ally).Assists+=1 end
  end
  target.DamageSources={}
  self.Matches:Defeat(target)
 end
 return true
end
function Combat:InSight(actor,target)
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={actor.Match.ActorsFolder}
 return not workspace:Raycast(actor.Root.Position,target.Root.Position-actor.Root.Position,params)
end
function Combat:HitArea(actor,ability,origin,aim,multiplier,hit)
 for _,target in ipairs(actor.Match.Actors) do
  if target.Root and target~=actor and target.Side~=actor.Side and not target.Eliminated and not hit[target] then
   local localPoint=CFrame.lookAt(origin,origin+aim):PointToObjectSpace(target.Root.Position)
   local inside
   if ability.Kind=="AOE" then inside=(target.Root.Position-origin).Magnitude<=ability.Range+2
   else inside=math.abs(localPoint.X)<=ability.HitboxSize.X/2+2 and math.abs(localPoint.Y)<=ability.HitboxSize.Y/2+2.5 and localPoint.Z<=2 and localPoint.Z>=-ability.Range-2 end
   if inside and self:InSight(actor,target) then hit[target]=true; self:Damage(actor,target,ability,origin,multiplier) end
  end
 end
end
function Combat:Attack(actor,slot,aim)
 local d=direction(aim)
 if not d or not self:Ready(actor) or actor.Guarding then return false end
 if type(slot)~="number" or slot%1~=0 or slot<0 or slot>4 then return false end
 local key=slot==0 and "Basic" or Database[actor.Team[actor.Active]].Abilities[slot]
 local ability=table.clone(Abilities[key])
 if not ability.CanUseInAir and actor.Humanoid.FloorMaterial==Enum.Material.Air then return false end
 if slot==0 and actor.Humanoid.FloorMaterial==Enum.Material.Air then
  ability=table.clone(ability); ability.Kind="AOE"; ability.Range=8; ability.GroundSlam=true; ability.Knockback=20; ability.Stun=.4
 end
 local now=os.clock(); local cooldowns=actor.Cooldowns[actor.Active]
 if now<(cooldowns[key] or 0) then return false end
 stats(actor).Attacks+=1; actor.AttackSerial=(actor.AttackSerial or 0)+1; ability.ActionSerial=actor.AttackSerial
 cooldowns[key]=now+ability.Cooldown
 actor.LockUntil=now+ability.Startup+ability.Endlag; actor.PotionToken=nil
 actor.Root.CFrame=CFrame.lookAt(actor.Root.Position,actor.Root.Position+d)
 local active=actor.Active; local generation=actor.Generation
 local combo=1
 if slot==0 then
  actor.BasicCombo=now-(actor.LastBasic or 0)<1.2 and (actor.BasicCombo or 0)%4+1 or 1
  actor.LastBasic=now; combo=actor.BasicCombo==4 and 1.6 or 1
 end
 self:Effect(actor,key,actor.Root.Position,{Aim=d,Startup=ability.Startup,Combo=actor.BasicCombo or 1,Kind=ability.Kind,MoveID=key,Type=ability.Type,Slot=slot,DisplayName=ability.DisplayName,Hitstop=ability.Hitstop})
 task.delay(ability.Startup,function()
  if actor.Eliminated or actor.Generation~=generation or actor.Active~=active or actor.Match.Phase~="Battle" or not actor.Root or os.clock()<(actor.StunnedUntil or 0) then return end
  if ability.Kind=="Shield" then actor.ShieldUntil=os.clock()+ability.Active; return end
  if ability.GroundSlam then self:Displace(actor,Vector3.new(0,-12,0)); self:Effect(actor,"GroundSlam") end
  if ability.Kind=="Dash" then self:Displace(actor,d*ability.Range) end
  if ability.Kind=="Projectile" then
   table.insert(self.Projectiles,{Actor=actor,Ability=ability,Position=actor.Root.Position,Direction=d,Remaining=ability.Range,Generation=generation,Hit={}})
  else
   local hit={}; local ending=os.clock()+ability.Active
   repeat
    if actor.Eliminated or actor.Generation~=generation or actor.Match.Phase~="Battle" then break end
    self:HitArea(actor,ability,actor.Root.Position,d,combo,hit)
    task.wait(.03)
   until os.clock()>=ending
  end
 end)
 return true
end
function Combat:Switch(actor,index,forced)
 if not actor or actor.Eliminated or actor.Switching or actor.Match.Phase~="Battle" then return false end
 if not forced and (not self:Ready(actor) or actor.Switches<=0) then return false end
 if type(index)~="number" or index%1~=0 or index<1 or index>3 or index==actor.Active or actor.Health[index]<=0 then return false end
 if not forced then actor.Switches-=1; stats(actor).Switches+=1 end
 actor.Switching=true; actor.PotionToken=nil; actor.LockUntil=os.clock()+Config.SwitchSeconds; actor.InvulnerableUntil=actor.LockUntil
 actor.Generation+=1; local generation=actor.Generation; local cf=actor.Root.CFrame
 self:Effect(actor,"Switch")
 task.delay(Config.SwitchSeconds,function()
  if actor.Eliminated or actor.Generation~=generation or actor.Match.Phase~="Battle" then return end
  actor.Switching=false; actor.Active=index
  self.Matches.Creatures:Spawn(actor,actor.Team[index],cf,actor.Match.ActorsFolder)
  self.Matches:SendState(actor.Match)
 end)
 return true
end
function Combat:Potion(actor)
 if not self:Ready(actor) or actor.Potions<=0 or actor.Health[actor.Active]>=100 then return false end
 actor.Potions-=1; stats(actor).PotionsUsed+=1; actor.LockUntil=os.clock()+Config.PotionSeconds
 local token={}; actor.PotionToken=token; local generation=actor.Generation
 self:Effect(actor,"Potion")
 task.delay(Config.PotionSeconds,function()
  if actor.PotionToken~=token or actor.Eliminated or actor.Generation~=generation or actor.Match.Phase~="Battle" then return end
  actor.Health[actor.Active]=math.min(100,actor.Health[actor.Active]+Config.PotionHeal)
  actor.Humanoid.Health=actor.Health[actor.Active]; actor.PotionToken=nil
  self:Effect(actor,"Heal")
 end)
 return true
end
function Combat:Guard(actor,value)
 if actor and value~=true then actor.Guarding=false; return end
 if self:Ready(actor) and actor.Stamina>0 then actor.Guarding=value==true end
end
function Combat:Step(dt)
 local now=os.clock()
 for i=#self.Projectiles,1,-1 do
  local p=self.Projectiles[i]; local travel=math.min(p.Remaining,p.Ability.ProjectileSpeed*dt)
  if p.Actor.Match.Phase~="Battle" or p.Actor.Generation~=p.Generation then table.remove(self.Projectiles,i); continue end
  local from=p.Position; local delta=p.Direction*travel
  local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={p.Actor.Match.ActorsFolder}
  local wall=workspace:Raycast(from,delta,params); local blocked=wall~=nil
  local best,bestT=nil,wall and (wall.Position-from).Magnitude or math.huge
  for _,target in ipairs(p.Actor.Match.Actors) do
   if not target.Eliminated and target.Side~=p.Actor.Side and target.Root then
    local along=math.clamp((target.Root.Position-from):Dot(p.Direction),0,travel)
    local distance=(target.Root.Position-(from+p.Direction*along)).Magnitude
    if distance<=4 and along<bestT then best=target; bestT=along end
   end
  end
  if best then self:Damage(p.Actor,best,p.Ability,from); blocked=true end
  p.Position+=delta; p.Remaining-=travel
  if blocked or p.Remaining<=0 then table.remove(self.Projectiles,i) end
 end
 for _,match in pairs(self.Matches.Active) do
  if match.Phase=="Battle" then
   for _,actor in ipairs(match.Actors) do
    if not actor.Eliminated and actor.Root then
     actor.Stamina=math.min(100,actor.Stamina+dt*(actor.Guarding and -18 or 15))
     if actor.Stamina<=0 then actor.Guarding=false end
     if actor.Stamina<0 then actor.Stamina=0 end
     local canMove=self:Ready(actor) and now-(actor.LastMove or 0)<(actor.Bot and 2 or .5)
     actor.Humanoid.WalkSpeed=actor.Guarding and 8 or Database[actor.Team[actor.Active]].Stats.WalkSpeed
     actor.Humanoid:Move(canMove and (actor.Move or Vector3.zero) or Vector3.zero,false)
     local pos=actor.Root.Position; local center=match.Center
     if math.abs(pos.X-center.X)>match.Radius-2 or math.abs(pos.Z-center.Z)>match.Radius-2 or pos.Y<center.Y-15 then
      local target=Vector3.new(math.clamp(pos.X,center.X-match.Radius+5,center.X+match.Radius-5),center.Y+6,math.clamp(pos.Z,center.Z-match.Radius+5,center.Z+match.Radius-5))
      actor.Character:PivotTo(CFrame.new(target))
     end
    end
   end
  end
 end
end
return Combat
