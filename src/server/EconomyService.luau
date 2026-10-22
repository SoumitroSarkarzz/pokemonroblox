local Shared=game.ReplicatedStorage.Shared
local Database=require(Shared.PokemonDatabase)
local Rules=require(Shared.Rules)
local Config=require(Shared.Config)
local Economy={}
local rng=Random.new()
function Economy:Init(data) self.Data=data end
function Economy:OpenCrate(player,kind)
 local profile=self.Data:Get(player); local config=Config.Crates[kind]
 if not profile or not config or (profile.Crates[kind] or 0)<1 then return false,"No crate available" end
 local pool={}
 if kind=="Starter" then
  for _,id in ipairs(Config.StarterPool) do if not profile.Owned[tostring(id)] then table.insert(pool,id) end end
 else
  local sum=0; for _,weight in pairs(config.Weights) do sum+=weight end
  local roll=rng:NextNumber(0,sum); local rarity
  -- Stable order avoids platform-dependent RNG traversal.
  for _,name in ipairs(Config.Rarities) do roll-=config.Weights[name] or 0; if roll<=0 then rarity=name; break end end
  for id,entry in ipairs(Database) do if entry.Rarity==rarity then table.insert(pool,id) end end
 end
 if #pool==0 then return false,"No eligible reward" end
 local id=pool[rng:NextInteger(1,#pool)]; local key=tostring(id)
 local new=profile.Owned[key]==nil
 profile.Crates[kind]-=1
 if new then
  profile.Owned[key]={Level=1,Mastery=0}
  if #profile.Team<3 then table.insert(profile.Team,id) end
 else profile.Coins+=100; profile.Owned[key].Mastery+=10 end
 return true,{ID=id,New=new,DuplicateCoins=new and 0 or 100}
end
function Economy:Purchase(player,kind,id)
 local profile=self.Data:Get(player)
 if not profile then return false,"Data unavailable" end
 if kind=="Creature" then
  local entry=Database[id]
  if not entry or profile.Owned[tostring(id)] then return false,"Unavailable or already owned" end
  if profile.Level<entry.UnlockLevel or profile.Coins<entry.Price then return false,"Insufficient coins or level" end
  profile.Coins-=entry.Price; profile.Owned[tostring(id)]={Level=1,Mastery=0}
  return true,"Creature unlocked"
 elseif kind=="Crate" and Config.Crates[id] and id~="Starter" then
  local price=Config.Crates[id].Price
  if profile.Coins<price then return false,"Insufficient coins" end
  profile.Coins-=price; profile.Crates[id]=(profile.Crates[id] or 0)+1
  return true,"Crate purchased"
 end
 return false,"Unknown purchase"
end
function Economy:SetTeam(player,team)
 local p=self.Data:Get(player)
 if not p or not Rules.ValidateTeam(team,p.Owned) then return false,"Choose three different owned creatures" end
 p.Team=table.clone(team); return true,"Team saved"
end
function Economy:Daily(player)
 local p=self.Data:Get(player); if not p then return false,"Data unavailable" end
 local today=math.floor(os.time()/86400)
 if p.Daily.Day>=today then return false,"Already claimed today" end
 p.Daily.Streak=p.Daily.Day==today-1 and (p.Daily.Streak%7)+1 or 1
 p.Daily.Day=today; local amount=100+25*p.Daily.Streak; p.Coins+=amount
 return true,"Daily reward: "..amount.." coins"
end
function Economy:Reward(player,match,won,opponentMMR)
 local p=self.Data:Get(player)
 if not p or match.Practice or p.AppliedMatches[match.ID] then return end
 p.AppliedMatches[match.ID]=os.time()
 -- Keep receipts bounded; match IDs are generated only by the server.
 for id,time in pairs(p.AppliedMatches) do if time<os.time()-86400 then p.AppliedMatches[id]=nil end end
 p.MatchesPlayed+=1
 if won then p.Wins+=1; p.WinStreak+=1; p.BestWinStreak=math.max(p.BestWinStreak or 0,p.WinStreak) else p.Losses+=1; p.WinStreak=0 end
 p.Coins+=match.Ranked and (won and 160 or 65) or (won and 60 or 25)
 p.XP+=match.Ranked and (won and 140 or 70) or (won and 70 or 35)
 p.Level=Rules.Level(p.XP)
 if match.Ranked then p.MMR=math.max(0,p.MMR+Rules.RatingDelta(p.MMR,opponentMMR,won)); p.RankTier=Rules.Rank(p.MMR) end
 for _,id in ipairs(p.Team) do local creature=p.Owned[tostring(id)]; creature.Mastery+=won and 10 or 4; creature.Level=1+math.floor(creature.Mastery/100) end
 -- Mastery and levels are progression only; competitive stats remain standardized.
end
return Economy
