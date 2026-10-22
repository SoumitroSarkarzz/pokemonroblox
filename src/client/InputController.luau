local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Input={Connections={}}
function Input:Destroy()
 for _,connection in ipairs(self.Connections) do connection:Disconnect() end
 table.clear(self.Connections)
end
function Input:Init(ui,intent)
 self:Destroy()
 self.UI=ui; self.Intent=intent
 local player=Players.LocalPlayer
 local playerModule=player.PlayerScripts:WaitForChild("PlayerModule",10)
 assert(playerModule,"Roblox PlayerModule did not load; profile UI remains available")
 if not ui.Gui.Parent then return end
 local controls=require(playerModule):GetControls()
 local function connect(signal,callback) local c=signal:Connect(callback); table.insert(self.Connections,c) end
 connect(ui.Gui.Destroying,function() self:Destroy() end)
 local lastMove=0; local jump=false
 local function aim()
  local cam=workspace.CurrentCamera
  local v=cam.CFrame.LookVector; local flat=Vector3.new(v.X,0,v.Z)
  return flat.Magnitude>.01 and flat.Unit or Vector3.new(0,0,-1)
 end
 local function send(action,payload) if ui.Match then intent:FireServer(action,payload or {}) end end
 local function action(name,value)
  if UIS:GetFocusedTextBox() then return end
  if name=="Attack" then send("Attack",{Slot=value or 0,Aim=aim()})
  elseif name=="Dash" then send("Dash",{Aim=aim()})
  elseif name=="Switch" and ui.Me then ui:ShowSwitchSelector()
  elseif name=="Potion" then send("Potion")
  elseif name=="Guard" then send("Guard",{Enabled=true}) end
 end
 ui.OnAction=action
 connect(UIS.InputBegan,function(input,processed)
  if processed then return end
  if input.KeyCode==Enum.KeyCode.Escape and ui.Presentation.Switch then ui.Presentation:CloseSwitch(); return end
  local keys={[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,[Enum.KeyCode.Four]=4}
  if input.UserInputType==Enum.UserInputType.MouseButton1 then action("Attack",0)
  elseif keys[input.KeyCode] then
   if ui.Presentation.Switch and keys[input.KeyCode]<=3 then ui.Presentation:SelectSwitch(keys[input.KeyCode])
   else action("Attack",keys[input.KeyCode]) end
  elseif input.KeyCode==Enum.KeyCode.Q then action("Dash")
  elseif input.KeyCode==Enum.KeyCode.R then action("Switch")
  elseif input.KeyCode==Enum.KeyCode.G then action("Potion")
  elseif input.KeyCode==Enum.KeyCode.F then action("Guard")
  elseif input.KeyCode==Enum.KeyCode.Space then jump=true end
 end)
 connect(UIS.JumpRequest,function() jump=true end)
 connect(UIS.InputEnded,function(input) if input.KeyCode==Enum.KeyCode.F then send("Guard",{Enabled=false}) end end)
 connect(Run.RenderStepped,function()
  if not ui.Match then return end
  local now=os.clock()
  if now-lastMove<.05 then return end; lastMove=now
  local vector=controls:GetMoveVector()
  local cam=workspace.CurrentCamera
  local forward=aim(); local right=Vector3.new(-forward.Z,0,forward.X)
  local world=right*vector.X+forward*(-vector.Z)
  send("Move",{Direction=world,Jump=jump}); jump=false
 end)
end
return Input
