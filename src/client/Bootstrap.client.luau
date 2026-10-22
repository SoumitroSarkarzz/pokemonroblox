local Players=game:GetService("Players")
local remotes=game.ReplicatedStorage:WaitForChild("Remotes")
local intent=remotes:WaitForChild("Intent"); local state=remotes:WaitForChild("State")
local UI=require(script.Parent.UIController)
local Input=require(script.Parent.InputController)
local Camera=require(script.Parent.CameraController)
local VFX=require(script.Parent.VFXController)
local Creatures=require(script.Parent.CreatureController)
UI:Init(intent)
state.OnClientEvent:Connect(function(kind,payload)
 if kind=="Profile" and payload then UI:ProfileChanged(payload)
 elseif kind=="ProfileStatus" and not UI.Profile then UI.Stats.Text=payload
 elseif kind=="Match" then UI:UpdateMatch(payload)
 elseif kind=="Lobby" then UI:Lobby()
 elseif kind=="Open" then UI:Open(payload)
 elseif kind=="Notice" or kind=="Announcement" then UI:Toast(payload)
 elseif kind=="Queue" then UI:Queue(payload)
 elseif kind=="Leaderboards" then UI.Boards=payload
 elseif kind=="Crate" then task.delay(.1,function() UI:Reveal(payload) end)
 elseif kind=="Effect" then VFX:Play(payload); Creatures:Effect(payload)
 elseif kind=="Result" then UI:Toast((payload.Draw and "DRAW" or payload.Won and "VICTORY" or "DEFEAT")..(payload.Draw and " • No rating change" or payload.Practice and " • Practice complete" or " • Rewards added").." • Returning to lobby…") end
end)
task.spawn(function()
 while not UI.Profile do intent:FireServer("Ready"); task.wait(1) end
end)

local function startupStatus()
 local err=game.ReplicatedStorage:GetAttribute("ServerStartupError")
 if err and not UI.Profile then
  UI.Stats.Text="Server startup failed • check Server Output"
  UI:Toast("Server startup failed. Open Studio Output and select Server.")
  warn("[Startup] Server error: "..tostring(err))
 end
end
game.ReplicatedStorage:GetAttributeChangedSignal("ServerStartupError"):Connect(startupStatus)
startupStatus()
-- Input/PlayerModule readiness must never block the profile subscription or handshake.
for _,entry in ipairs({{Input,"Input",true},{Camera,"Camera"},{VFX,"VFX"},{Creatures,"Creatures"}}) do
 task.spawn(function()
  local ok,err=pcall(function() entry[1]:Init(UI,entry[3] and intent or nil) end)
  if not ok then warn("[Startup] "..entry[2].." controller failed: "..tostring(err)) end
 end)
end
task.delay(30,function()
 if not UI.Profile then
  UI.Stats.Text="Profile unavailable • check Server Output"
  UI:Toast("Profile did not load. Open Studio Output and copy the first red server error.")
 end
end)
