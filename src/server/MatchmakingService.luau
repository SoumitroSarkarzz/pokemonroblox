local Config=require(game.ReplicatedStorage.Shared.Config)
local Rules=require(game.ReplicatedStorage.Shared.Rules)
local Queue={Queues={},Membership={},DisplayAt=0}
function Queue:Init(data,matches,world,event)
 self.Data=data; self.Matches=matches; self.World=world; self.Event=event
 for mode in pairs(Config.Modes) do self.Queues[mode]={Players={},Countdown=nil} end
end
function Queue:Leave(player)
 local mode=self.Membership[player]
 if not mode then return end
 self.Membership[player]=nil
 local q=self.Queues[mode]
 for i,entry in ipairs(q.Players) do if entry.Player==player then table.remove(q.Players,i); break end end
 q.Countdown=nil
 if player.Parent then self.Event:FireClient(player,"Queue",{Mode=""}) end
end
function Queue:Join(player,mode,options)
 local config=Config.Modes[mode]; local p=self.Data:Get(player)
 if not config or not p or self.Matches.ByPlayer[player] then return false,"Unavailable while battling" end
 if not Rules.ValidateTeam(p.Team,p.Owned) then return false,"Open your three starter crates first" end
 if self.Membership[player]==mode then return true,"Already queued" end
 if config.Practice then self:Leave(player); return self.Matches:Start({player},mode,options),"Practice started" end
 local q=self.Queues[mode]
 if #q.Players>=config.Size*2 then return false,"Queue full" end
 self:Leave(player)
 table.insert(q.Players,{Player=player,Joined=os.clock(),MMR=p.MMR,Level=p.Level})
 self.Membership[player]=mode
 return true,"Joined "..config.Label
end
function Queue:Compatible(q,ranked)
 if #q.Players==0 then return false end
 local low,high=math.huge,-math.huge
 local minLevel,maxLevel=math.huge,0
 local oldest=os.clock()
 for _,entry in ipairs(q.Players) do
  low=math.min(low,entry.MMR); high=math.max(high,entry.MMR)
  minLevel=math.min(minLevel,entry.Level); maxLevel=math.max(maxLevel,entry.Level); oldest=math.min(oldest,entry.Joined)
 end
 local waited=os.clock()-oldest
 local range=(ranked and 200 or 500)+math.floor(waited/15)*100
 return high-low<=range and (not (minLevel<5 and maxLevel>=15) or waited>=90)
end
function Queue:Step(dt)
 local now=os.clock()
 -- Physical zones are sampled on the server; clients cannot claim a queue location.
 for _,player in ipairs(game.Players:GetPlayers()) do
  if self.Data:Get(player) and not self.Matches.ByPlayer[player] then
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local current=self.Membership[player]
   if root then
    if current then
     local center=self.World.Pads[current]
     if (Vector3.new(root.Position.X,0,root.Position.Z)-center).Magnitude>10 then self:Leave(player) end
    else
     for mode,center in pairs(self.World.Pads) do
      if (Vector3.new(root.Position.X,0,root.Position.Z)-center).Magnitude<=7.5 then self:Join(player,mode); break end
     end
    end
   end
  end
 end
 for mode,q in pairs(self.Queues) do
  local config=Config.Modes[mode]; local needed=config.Practice and 1 or config.Size*2
  if not config.Practice then
   if #q.Players==needed and self:Compatible(q,config.Ranked) then
    q.Countdown=q.Countdown or now+Config.QueueCountdown
    if now>=q.Countdown then
     local players={}; for _,entry in ipairs(q.Players) do table.insert(players,entry.Player) end
     q.Players={}; q.Countdown=nil
     for _,p in ipairs(players) do self.Membership[p]=nil end
     if not self.Matches:Start(players,mode) then for _,p in ipairs(players) do self.Event:FireClient(p,"Notice","Match could not start. Re-enter the queue.") end end
    end
   else q.Countdown=nil end
  end
 end
 self.DisplayAt+=dt
 if self.DisplayAt>=.5 then
  self.DisplayAt=0
  for mode,q in pairs(self.Queues) do
   local config=Config.Modes[mode]; local lines={config.Label,string.format("%d / %d PLAYERS",#q.Players,config.Practice and 1 or config.Size*2)}
   table.insert(lines,q.Countdown and "STARTING IN "..math.max(0,math.ceil(q.Countdown-now)) or (#q.Players>0 and "Waiting for compatible players..." or "Walk into the circle"))
   for _,entry in ipairs(q.Players) do table.insert(lines,entry.Player.Name.." • Lv "..entry.Level.." • "..Rules.Rank(entry.MMR)) end
   self.World.Screens[mode].Text=table.concat(lines,"\n")
   for _,entry in ipairs(q.Players) do self.Event:FireClient(entry.Player,"Queue",{Mode=mode,Count=#q.Players,Needed=config.Size*2,Countdown=q.Countdown and math.max(0,math.ceil(q.Countdown-now))}) end
  end
 end
end
return Queue
