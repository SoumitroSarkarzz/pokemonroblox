local Config=require(game.ReplicatedStorage.Shared.Config)
local Rules=require(game.ReplicatedStorage.Shared.Rules)
local Http=game:GetService("HttpService")
local Matches={Active={},ByPlayer={},Serial=0}
function Matches:Init(data,economy,creatures,world,event)
 self.Data=data; self.Economy=economy; self.Creatures=creatures; self.World=world; self.Event=event
end
function Matches:Broadcast(match,kind,payload)
 for _,actor in ipairs(match.Actors) do if actor.Player and actor.Player.Parent then self.Event:FireClient(actor.Player,kind,payload) end end
end
function Matches:Snapshot(match)
 local payload={ID=match.ID,Phase=match.Phase,Mode=match.Mode,Remaining=math.max(0,math.ceil(match.EndsAt-os.clock())),Actors={},SuddenDeath=match.SuddenDeath,Training=match.Training}
 for _,actor in ipairs(match.Actors) do
  local cooldowns={}
  for key,ending in pairs(actor.Cooldowns[actor.Active]) do cooldowns[key]=math.max(0,ending-os.clock()) end
  table.insert(payload.Actors,{ID=actor.ID,Name=actor.Name,Side=actor.Side,Team=actor.Team,Health=actor.Health,Active=actor.Active,Switches=actor.Switches,Potions=actor.Potions,Eliminated=actor.Eliminated,Cooldowns=cooldowns,Stamina=actor.Stamina})
 end
 return payload
end
function Matches:SendState(match) self:Broadcast(match,"Match",self:Snapshot(match)) end
function Matches:Start(players,mode,options)
 local config=Config.Modes[mode]; if not config then return false end
 for _,player in ipairs(players) do
  local p=self.Data:Get(player)
  if not p or not Rules.ValidateTeam(p.Team,p.Owned) or self.ByPlayer[player] then return false end
 end
 self.Serial=1
 while self.World.Arenas:FindFirstChild("Arena_"..self.Serial) do self.Serial+=1 end
 local folder,actorsFolder,center,radius=self.World:CreateArena(self.Serial,config.Size)
 local match={ID=Http:GenerateGUID(false),Mode=mode,Ranked=config.Ranked,Practice=config.Practice,Training=options and options.Training,Actors={},Folder=folder,ActorsFolder=actorsFolder,Center=center,Radius=radius,Phase="Preview",EndsAt=os.clock()+Config.PreviewSeconds,Duration=config.Duration,Difficulty=options and options.Difficulty or "Normal"}
 self.Active[match.ID]=match
 local sorted=table.clone(players)
 table.sort(sorted,function(a,b) return self.Data:Get(a).MMR>self.Data:Get(b).MMR end)
 local sides={0,0}
 for i,player in ipairs(sorted) do
  local side=(i%4==1 or i%4==0) and 1 or 2
  if config.Practice then side=1 end
  sides[side]+=1
  local p=self.Data:Get(player)
  local actor={ID=tostring(player.UserId),Name=player.DisplayName,Player=player,Side=side,Team=table.clone(p.Team),Health={100,100,100},Active=1,Cooldowns={{},{},{}},Switches=Config.MaxSwitches,Potions=1,Stamina=100,Generation=1,MMR=p.MMR,Match=match}
  table.insert(match.Actors,actor); self.ByPlayer[player]=actor
 end
 if config.Practice then
  local bot={ID="bot_"..match.ID,Name=match.Training and "Training Dummy" or match.Difficulty.." Bot",Side=2,Team={1,4,7},Health={100,100,100},Active=1,Cooldowns={{},{},{}},Switches=2,Potions=1,Stamina=100,Generation=1,MMR=600,Match=match,Bot=true,Dummy=match.Training}
  table.insert(match.Actors,bot)
 end
 local offsets={0,0}
 for _,actor in ipairs(match.Actors) do
  offsets[actor.Side]+=1
  local offset=(offsets[actor.Side]-(config.Size+1)/2)*12
  local point=center+Vector3.new(actor.Side==1 and -radius*.55 or radius*.55,6,offset)
  self.Creatures:Spawn(actor,actor.Team[1],CFrame.lookAt(point,center+Vector3.new(0,6,0)),actorsFolder)
 end
 self:SendState(match)
 return true
end
function Matches:Defeat(actor,deferWinner)
 if actor.Eliminated then return end
 local replacement
 for i,hp in ipairs(actor.Health) do if hp>0 then replacement=i; break end end
 if actor.Dummy then
  actor.Health={100,100,100}; actor.Humanoid.Health=100; return
 end
 self:Broadcast(actor.Match,"Announcement",actor.Name.."'s creature was defeated")
 if replacement then
  self.Combat:Switch(actor,replacement,true)
 else
  actor.Eliminated=true; actor.Generation+=1; actor.Humanoid.WalkSpeed=0; actor.Root.Anchored=true
  if actor.Character then for _,p in ipairs(actor.Character:GetDescendants()) do if p:IsA("BasePart") then p.Transparency=math.max(.65,p.Transparency) end end end
  if not deferWinner then self:CheckWinner(actor.Match,false) end
 end
end
function Matches:CheckWinner(match,timer)
 if match.Phase~="Battle" or match.Training then return end
 local summaries={{Living=0,Health=0},{Living=0,Health=0}}
 for _,actor in ipairs(match.Actors) do
  if not actor.Eliminated then
   for _,hp in ipairs(actor.Health) do if hp>0 then summaries[actor.Side].Living+=1; summaries[actor.Side].Health+=hp/100 end end
  end
 end
 local winner
 if summaries[1].Living==0 and summaries[2].Living==0 then
  -- A perfectly simultaneous elimination is a draw; never award by iteration order.
  self:Finish(match,0); return
 elseif summaries[1].Living==0 then winner=2 elseif summaries[2].Living==0 then winner=1
 elseif timer then winner=Rules.Winner(summaries[1],summaries[2]) end
 if winner then self:Finish(match,winner)
 elseif timer then
  match.SuddenDeath=true; match.EndsAt=os.clock()+60
  self:Broadcast(match,"Announcement","SUDDEN DEATH • health drains until one team leads")
 end
end
function Matches:Finish(match,winner)
 if match.Phase=="Results" then return end
 match.Phase="Results"; match.EndsAt=os.clock()+7
 for _,actor in ipairs(match.Actors) do
  if actor.Root then actor.Root.Anchored=true end
  if actor.Player then
   local total,count=0,0
   for _,other in ipairs(match.Actors) do if other.Side~=actor.Side then total+=other.MMR; count+=1 end end
   if winner~=0 then self.Economy:Reward(actor.Player,match,actor.Side==winner,total/math.max(count,1)) end
   self.Event:FireClient(actor.Player,"Result",{Won=actor.Side==winner,Draw=winner==0,Practice=match.Practice})
   self.Event:FireClient(actor.Player,"Profile",self.Data:Public(actor.Player))
   task.spawn(function() self.Data:Save(actor.Player,false) end)
  end
 end
 self:SendState(match)
end
function Matches:Return(player,respawn)
 local actor=self.ByPlayer[player]
 if actor then
  self.ByPlayer[player]=nil; actor.Player=nil; actor.Eliminated=true; actor.Generation+=1
  if actor.Character then actor.Character:Destroy(); actor.Root=nil end
 end
 if respawn~=false and player.Parent then
  task.spawn(function() if player.Parent then local ok,err=pcall(function() player:LoadCharacter() end); if not ok then warn("[Match] Respawn failed: "..tostring(err)) end end end)
  self.Event:FireClient(player,"Lobby",{})
 end
end
function Matches:Leave(player,disconnected)
 local actor=self.ByPlayer[player]
 if not actor then return end
 if actor.Match.Phase=="Battle" or actor.Match.Phase=="Preview" then
  -- A forfeit receives the loss once and never earns a later win.
  local total,count=0,0
  for _,other in ipairs(actor.Match.Actors) do if other.Side~=actor.Side then total+=other.MMR; count+=1 end end
  self.Economy:Reward(player,actor.Match,false,total/math.max(1,count))
 end
 local match=actor.Match
 self:Return(player,not disconnected)
 self:CheckWinner(match,false)
end
function Matches:Step(dt)
 local now=os.clock()
 for id,match in pairs(self.Active) do
  if match.Phase=="Preview" and now>=match.EndsAt then
   match.Phase="Battle"; match.EndsAt=now+match.Duration; self:Broadcast(match,"Announcement","FIGHT")
   self:CheckWinner(match,false)
  elseif match.Phase=="Battle" then
   if match.SuddenDeath then
    match.Drain=(match.Drain or 0)+dt
    if match.Drain>=1 then
     match.Drain=0
     for _,actor in ipairs(match.Actors) do
      if not actor.Eliminated and not actor.Switching then actor.Health[actor.Active]=math.max(0,actor.Health[actor.Active]-3); actor.Humanoid.Health=math.max(1,actor.Health[actor.Active]); end
     end
     for _,actor in ipairs(match.Actors) do if not actor.Eliminated and not actor.Switching and actor.Health[actor.Active]==0 then self:Defeat(actor,true) end end
     self:CheckWinner(match,true)
    end
   elseif now>=match.EndsAt then self:CheckWinner(match,true) end
  elseif match.Phase=="Results" and now>=match.EndsAt then
   for _,actor in ipairs(match.Actors) do if actor.Player then self:Return(actor.Player) end end
   match.Folder:Destroy(); self.Active[id]=nil
  end
  match.StateTimer=(match.StateTimer or 0)+dt
  if match.StateTimer>=.15 then match.StateTimer=0; self:SendState(match) end
  local hasPlayers=false
  for _,actor in ipairs(match.Actors) do if actor.Player then hasPlayers=true; break end end
  if not hasPlayers then match.Folder:Destroy(); self.Active[id]=nil end
 end
end
return Matches
