local Rules = {}
function Rules.IsFinite(n) return type(n)=="number" and n==n and math.abs(n)<1e9 end
function Rules.Rank(mmr)
 local names={"Bronze","Silver","Gold","Platinum","Diamond","Master","Champion"}
 return names[math.clamp(math.floor(mmr/300)+1,1,#names)]
end
function Rules.RatingDelta(a,b,won) return math.round(24*((won and 1 or 0)-1/(1+10^((b-a)/400)))) end
function Rules.Level(xp) return 1+math.floor(math.sqrt(math.max(0,xp)/100)) end
function Rules.ValidateTeam(team,owned)
 if type(team)~="table" or #team~=3 then return false end
 local seen={}
 for _,id in ipairs(team) do
  if not Rules.IsFinite(id) or id%1~=0 or not owned[tostring(id)] or seen[id] then return false end
  seen[id]=true
 end
 return true
end
function Rules.Winner(a,b)
 if a.Living~=b.Living then return a.Living>b.Living and 1 or 2 end
 if math.abs(a.Health-b.Health)>.0001 then return a.Health>b.Health and 1 or 2 end
 return nil
end
function Rules.NewProfile()
 return {Version=1,Level=1,XP=0,Coins=0,MMR=600,RankTier="Gold",Wins=0,Losses=0,WinStreak=0,BestWinStreak=0,MatchesPlayed=0,
  Owned={},Team={},Crates={Starter=3,Basic=0,Rare=0,Event=0},Potions=0,Cosmetics={},Settings={Music=true,Effects=true,ShiftLock=false},Daily={Day=0,Streak=0},Tutorial=false,Favorites={},AppliedMatches={}}
end
function Rules.Search(entry,query)
 local hay=string.lower(table.concat({tostring(entry.ID),string.format("%03d",entry.ID),entry.Name,entry.Type1,entry.Type2 or "",entry.Rarity,entry.Role}," "))
 return string.find(hay,string.lower(query),1,true)~=nil
end
return Rules
