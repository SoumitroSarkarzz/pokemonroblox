local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local replicated=game:GetService("ReplicatedStorage")
Players.CharacterAutoLoads=false
replicated:SetAttribute("ServerStartupStatus","Starting")
replicated:SetAttribute("ServerStartupError",nil)
local remotes=replicated:FindFirstChild("Remotes") or Instance.new("Folder",replicated); remotes.Name="Remotes"
local intent=remotes:FindFirstChild("Intent") or Instance.new("RemoteEvent",remotes); intent.Name="Intent"
local event=remotes:FindFirstChild("State") or Instance.new("RemoteEvent",remotes); event.Name="State"
local function start()
local Shared=replicated.Shared
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local assets=require(Shared.AssetSetup); assets.Run()
local Data=require(script.Parent.DataService)
local Economy=require(script.Parent.EconomyService)
local Creatures=require(script.Parent.CreatureService)
local World=require(script.Parent.WorldService)
local Matches=require(script.Parent.MatchService)
local Combat=require(script.Parent.CombatService)
local Queue=require(script.Parent.MatchmakingService)
local Bots=require(script.Parent.BotService)
local Boards=require(script.Parent.LeaderboardService)
World:Init(); Economy:Init(Data); Matches:Init(Data,Economy,Creatures,World,event)
Combat:Init(Matches,event); Matches.Combat=Combat; Queue:Init(Data,Matches,World,event); Bots:Init(Matches,Combat); Boards:Init(Data)
Data:Start()
local rates={}; local actionAt={}
local function notify(p,text) event:FireClient(p,"Notice",tostring(text)) end
local function profile(p) event:FireClient(p,"Profile",Data:Public(p)) end
World.OnStation=function(player,name)
 if Data:Get(player) and not Matches.ByPlayer[player] then event:FireClient(player,"Open",name) end
end
local function join(player)
 local p=Data:Load(player); if not p or not player.Parent then return end
 event:FireClient(player,"Profile",Data:Public(player))
 player.CharacterAdded:Connect(function(character)
  local hum=character:FindFirstChildOfClass("Humanoid")
  if hum then hum.Died:Connect(function() task.delay(2,function() if player.Parent and not Matches.ByPlayer[player] then player:LoadCharacter() end end) end) end
 end)
 local function nametag(character)
  local head=character:FindFirstChild("Head")
  if head then
   local gui=Instance.new("BillboardGui"); gui.Name="PlayerRank"; gui.Size=UDim2.fromOffset(220,50); gui.StudsOffset=Vector3.new(0,2.8,0); gui.Parent=head
   local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.TextColor3=Color3.new(1,1,1); label.TextStrokeTransparency=.3; label.TextSize=13; label.Font=Enum.Font.GothamBold; label.Text=player.DisplayName.." • Lv "..p.Level.." • "..Rules.Rank(p.MMR); label.Parent=gui
  end
 end
 if player.Character then nametag(player.Character) end
 player.CharacterAdded:Connect(nametag)
 player:LoadCharacter()
end
local function safeJoin(player)
 local ok,err=xpcall(function() join(player) end,debug.traceback)
 if not ok then
  warn("[Startup] Player load failed: "..tostring(err))
  if player.Parent then player:Kick("Player initialization failed. Check the Server Output in Studio.") end
 end
end
Players.PlayerAdded:Connect(safeJoin)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(safeJoin,p) end
Players.PlayerRemoving:Connect(function(player)
 Queue:Leave(player); Matches:Leave(player,true); Boards:Publish(player); Data:Remove(player); rates[player]=nil; actionAt[player]=nil
end)
intent.OnServerEvent:Connect(function(player,action,payload)
 if type(action)~="string" or #action>24 then return end
 local now=os.clock(); local bucket=rates[player]
 if not bucket then bucket={Tokens=80,At=now}; rates[player]=bucket end
 bucket.Tokens=math.min(80,bucket.Tokens+(now-bucket.At)*50); bucket.At=now
 if bucket.Tokens<1 then return end; bucket.Tokens-=1
 if not Data:Get(player) then
  if action=="Ready" then event:FireClient(player,"ProfileStatus","Loading your profile…") end
  return
 end
 if type(payload)~="table" then payload={} end
 local actor=Matches.ByPlayer[player]
 if action=="Move" then if actor then Combat:Move(actor,payload.Direction,payload.Jump) end; return end
 if action=="Attack" then if actor then Combat:Attack(actor,payload.Slot,payload.Aim) end; return end
 if action=="Dash" then if actor then Combat:Dash(actor,payload.Aim) end; return end
 if action=="Guard" then if actor then Combat:Guard(actor,payload.Enabled) end; return end
 if action=="Switch" then if actor then Combat:Switch(actor,payload.Index,false) end; return end
 if action=="Potion" then if actor then Combat:Potion(actor) end; return end
 local throttle=actionAt[player] or {}; actionAt[player]=throttle
 if now-(throttle[action] or -10)<.3 then return end; throttle[action]=now
 if action=="Ready" then
  profile(player); event:FireClient(player,"Leaderboards",Boards.Cache)
  if actor then event:FireClient(player,"Match",Matches:Snapshot(actor.Match)) end
  return
 elseif action=="LeaveMatch" then Matches:Leave(player); profile(player); return
 elseif action=="TrainingReset" and actor and actor.Match.Training then
  for _,a in ipairs(actor.Match.Actors) do a.Health={100,100,100}; a.Cooldowns={{},{},{}}; a.Potions=1; a.Switches=2; a.Humanoid.Health=100 end
  actor.TotalDamage=0; actor.FirstHit=nil; actor.ComboCount=0; actor.ComboDamage=0
  return
 end
 if actor then return end
 if action=="LeaveQueue" then
  Queue:Leave(player)
  if player.Character then player.Character:PivotTo(CFrame.new(0,5,25)) end
  return
 end
 -- Editing loadout/economy while queued invalidates the selection; leave first.
 if Queue.Membership[player] and action~="Queue" then Queue:Leave(player) end
 local ok,result=false,"Unknown action"
 if action=="Queue" and type(payload.Mode)=="string" then
  -- Lobby UI queue buttons move the player to the pad; physical presence is still required.
  local center=World.Pads[payload.Mode]; local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if center and root then
   player.Character:PivotTo(CFrame.new(center+Vector3.new(0,4,0)))
   local difficulty=Config.BotDifficulties[payload.Difficulty] and payload.Difficulty or "Normal"
   ok,result=Queue:Join(player,payload.Mode,{Difficulty=difficulty,Training=payload.Training==true})
  end
 elseif action=="OpenCrate" and type(payload.Kind)=="string" then
  ok,result=Economy:OpenCrate(player,payload.Kind)
  if ok then event:FireClient(player,"Crate",result) end
 elseif action=="Purchase" and (type(payload.ID)=="number" or type(payload.ID)=="string") then ok,result=Economy:Purchase(player,payload.Kind,payload.ID)
 elseif action=="Team" then ok,result=Economy:SetTeam(player,payload.Team)
 elseif action=="Daily" then ok,result=Economy:Daily(player)
 elseif action=="Tutorial" then Data:Get(player).Tutorial=true; ok=true; result="Welcome to Kanto Arena"
 elseif action=="Favorite" and type(payload.ID)=="number" and payload.ID>=1 and payload.ID<=151 and payload.ID%1==0 then
  local favorites=Data:Get(player).Favorites; local key=tostring(payload.ID); favorites[key]=not favorites[key] or nil; ok=true; result="Favorites updated"
 elseif action=="Setting" and ({Music=true,Effects=true,ShiftLock=true})[payload.Key] and type(payload.Value)=="boolean" then
  Data:Get(player).Settings[payload.Key]=payload.Value; ok=true; result="Setting saved"
 end
 if type(result)=="string" then notify(player,result) end
 profile(player)
end)
local queueTimer=0; local boardTimer=0
Run.Heartbeat:Connect(function(dt)
 Combat:Step(math.min(dt,.1)); Matches:Step(dt); Bots:Step(dt)
 queueTimer+=dt; boardTimer+=dt
 if queueTimer>=.2 then Queue:Step(queueTimer); queueTimer=0 end
 if boardTimer>=120 then boardTimer=0; for player in pairs(Data.Profiles) do Boards:Publish(player) end; task.spawn(function() Boards:Refresh() end) end
end)
task.spawn(function() Boards:Refresh() end)

replicated:SetAttribute("ServerStartupStatus","Ready")
end
local ok,err=xpcall(start,debug.traceback)
if not ok then
 replicated:SetAttribute("ServerStartupStatus","Failed")
 replicated:SetAttribute("ServerStartupError",tostring(err))
 warn("[Startup] Server initialization failed:\n"..tostring(err))
end
