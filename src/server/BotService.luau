local Config=require(game.ReplicatedStorage.Shared.Config)
local Bots={}
function Bots:Init(matches,combat) self.Matches=matches; self.Combat=combat end
function Bots:Step(dt)
 local now=os.clock()
 for _,match in pairs(self.Matches.Active) do
  if match.Phase~="Battle" then continue end
  for _,bot in ipairs(match.Actors) do
   if not bot.Bot or bot.Dummy or bot.Eliminated then continue end
   local cfg=Config.BotDifficulties[match.Difficulty] or Config.BotDifficulties.Normal
   if now<(bot.NextThink or 0) then continue end
   bot.NextThink=now+cfg.Interval
   local target,distance=nil,math.huge
   for _,other in ipairs(match.Actors) do
    if other.Side~=bot.Side and not other.Eliminated and other.Root then
     local dist=(other.Root.Position-bot.Root.Position).Magnitude
     if dist<distance then target=other; distance=dist end
    end
   end
   if target then
    local delta=target.Root.Position-bot.Root.Position; local aim=Vector3.new(delta.X,0,delta.Z)
    if aim.Magnitude<.01 then aim=Vector3.new(1,0,0) else aim=aim.Unit end
    local hp=bot.Health[bot.Active]
    if hp<35 and bot.Potions>0 then self.Combat:Potion(bot) end
    if hp<25 and bot.Switches>0 then
     for i,health in ipairs(bot.Health) do if i~=bot.Active and health>hp+30 then self.Combat:Switch(bot,i,false); break end end
    end
    local retreat=hp<30 and bot.Potions>0
    local move=retreat and -aim or distance>cfg.Range and aim or Vector3.new(-aim.Z,0,aim.X)*.5
    self.Combat:Move(bot,move,false)
    if match.Difficulty=="Hard" or match.Difficulty=="Expert" then
     if now-(target.LastBasic or 0)<.5 and distance<10 then self.Combat:Dash(bot,Vector3.new(-aim.Z,0,aim.X)) end
     if hp<45 then self.Combat:Attack(bot,3,aim) end
    end
    if distance<8 then self.Combat:Attack(bot,0,aim)
    elseif distance<18 then self.Combat:Attack(bot,2,aim)
    else self.Combat:Attack(bot,1,aim) end
    if distance<14 and (match.Difficulty=="Hard" or match.Difficulty=="Expert") then self.Combat:Attack(bot,4,aim) end
   end
  end
 end
end
return Bots
