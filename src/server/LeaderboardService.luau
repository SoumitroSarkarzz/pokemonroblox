local DSS=game:GetService("DataStoreService")
local Boards={Cache={},Last=0}
function Boards:Init(data) self.Data=data end
function Boards:Publish(player)
 local p=self.Data:Get(player); if not p then return end
 for _,name in ipairs({"MMR","Wins","BestWinStreak"}) do
  local value=p[name]
  task.spawn(function() local ok,err=pcall(function() DSS:GetOrderedDataStore("KantoArena_"..name):SetAsync(tostring(player.UserId),value) end); if not ok then warn("[Leaderboard] "..tostring(err)) end end)
 end
end
function Boards:Refresh()
 local result={}
 for _,name in ipairs({"MMR","Wins","BestWinStreak"}) do
  local ok,pages=pcall(function() return DSS:GetOrderedDataStore("KantoArena_"..name):GetSortedAsync(false,10) end)
  result[name]={}
  if ok then
   for _,item in ipairs(pages:GetCurrentPage()) do
    local username="Player "..item.key
    local got,user=pcall(function() return game.Players:GetNameFromUserIdAsync(tonumber(item.key)) end)
    if got then username=user end
    table.insert(result[name],{Name=username,Value=item.value})
   end
  end
 end
 self.Cache=result
end
return Boards
