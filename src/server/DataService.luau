local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Shared=game.ReplicatedStorage.Shared
local Rules=require(Shared.Rules)
local Config=require(Shared.Config)
local Data={Profiles={},Records={},Closing=false}
local store
local function getStore()
 if not store then store=DSS:GetDataStore(Config.DataStore) end
 return store
end
local owner=game.JobId~="" and game.JobId or Http:GenerateGUID(false)
local function copy(t)
 if type(t)~="table" then return t end
 local out={}; for k,v in pairs(t) do out[k]=copy(v) end; return out
end
function Data:IsMockMode()
 return Run:IsStudio() and workspace:GetAttribute("UseMockData")~=false
end
function Data:Load(player)
 -- Explicit Studio test mode must not open a DataStore: even GetDataStore can
 -- throw for an unpublished place, before an UpdateAsync pcall is reached.
 if self:IsMockMode() then
  warn("[Data] Studio mock profile; progress will NOT persist (Studio test mode; set UseMockData=false for real API tests).")
  self.Records[player]={Mock=true}; self.Profiles[player]=Rules.NewProfile()
  if not player.Parent then self:Remove(player); return nil end
  return self.Profiles[player]
 end
 local key="u_"..player.UserId
 local record
 local ok,err=pcall(function()
  record=getStore():UpdateAsync(key,function(old)
   old=old or {Profile=Rules.NewProfile()}
   if type(old)~="table" or type(old.Profile)~="table" or old.Profile.Version~=Config.Version then return nil end
   local defaults=Rules.NewProfile()
   for key,value in pairs(defaults) do
    if old.Profile[key]~=nil and type(old.Profile[key])~=type(value) then return nil end
   end
   if old.Lease and old.Lease.Owner~=owner and old.Lease.Expires>os.time() then return nil end
   old.Lease={Owner=owner,Expires=os.time()+Config.LeaseSeconds}
   return old
  end)
 end)
 if not ok or not record or not record.Lease or record.Lease.Owner~=owner then
  warn("[Data] Profile load rejected for "..player.UserId..": "..tostring(err or "lease conflict or unsupported profile schema"))
  player:Kick("Your data could not be loaded safely. Please rejoin shortly."); return nil
 end
 local profile=record.Profile
 local defaults=Rules.NewProfile()
 for k,v in pairs(defaults) do
  if profile[k]==nil then profile[k]=v
  elseif type(v)=="table" then for nested,value in pairs(v) do if profile[k][nested]==nil then profile[k][nested]=value end end end
 end
 self.Records[player]={Key=key,Busy=false,LeaseExpires=record.Lease.Expires}
 self.Profiles[player]=profile
 if not player.Parent then self:Remove(player); return nil end
 return profile
end
function Data:Get(player) return self.Profiles[player] end
function Data:Save(player,release)
 local state=self.Records[player]; local profile=self.Profiles[player]
 if not state or not profile then return false end
 if state.Mock then return true end
 if state.Busy then return false end
 state.Busy=true
 local snapshot=copy(profile); local saved=false
 local ok,err=pcall(function()
  getStore():UpdateAsync(state.Key,function(old)
   saved=false -- UpdateAsync may retry this callback after a concurrent write.
   if not old or not old.Lease or old.Lease.Owner~=owner then return nil end
   old.Profile=snapshot
   old.Lease=not release and {Owner=owner,Expires=os.time()+Config.LeaseSeconds} or nil
   saved=true; return old
  end)
 end)
 state.Busy=false
 if ok and saved then state.LeaseExpires=os.time()+Config.LeaseSeconds; return true end
 warn("[Data] Save failed for "..player.UserId..": "..tostring(err))
 if os.time()>=state.LeaseExpires-20 and not release then player:Kick("Saving is unavailable. Rejoin to protect your progress.") end
 return false
end
function Data:Remove(player)
 local record=self.Records[player]
 if record then
  local deadline=os.clock()+15
  while record.Busy and os.clock()<deadline do task.wait(.1) end
  for attempt=1,3 do if self:Save(player,true) then break end; task.wait(attempt) end
 end
 self.Profiles[player]=nil; self.Records[player]=nil
end
function Data:Public(player)
 local profile=self:Get(player)
 return profile and copy(profile) or nil
end
function Data:Start()
 task.spawn(function()
  while not self.Closing do
   task.wait(Config.SaveInterval)
   for player in pairs(self.Profiles) do task.spawn(function() self:Save(player,false) end) end
  end
 end)
 game:BindToClose(function()
  self.Closing=true
  local pending=0
  for player in pairs(self.Profiles) do pending+=1; task.spawn(function() self:Remove(player); pending-=1 end) end
  local deadline=os.clock()+25
  while pending>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Data
