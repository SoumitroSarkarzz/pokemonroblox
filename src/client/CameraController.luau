local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Effects=require(script.Parent.CameraEffects)
local Camera={Connections={}}
function Camera:Destroy()
 Run:UnbindFromRenderStep("KantoCameraFeedback")
 for _,connection in ipairs(self.Connections) do connection:Disconnect() end
 table.clear(self.Connections); Effects:Reset()
 if self.Locked then UIS.MouseBehavior=Enum.MouseBehavior.Default; self.Locked=false end
end
function Camera:Init(ui)
 self:Destroy(); Effects:Init(ui)
 table.insert(self.Connections,ui.Gui.Destroying:Connect(function() self:Destroy() end))
 local player=Players.LocalPlayer
 local function follow(character)
  local humanoid=character:WaitForChild("Humanoid",5)
  if humanoid and character.Parent then workspace.CurrentCamera.CameraSubject=humanoid; workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end
 end
 table.insert(self.Connections,player.CharacterAdded:Connect(follow))
 if player.Character then task.spawn(follow,player.Character) end
 player.CameraMinZoomDistance=7; player.CameraMaxZoomDistance=22
 Run:BindToRenderStep("KantoCameraFeedback",Enum.RenderPriority.Camera.Value+1,function()
  local state=ui.Match
  if state and ui.Me and ui.Me.Eliminated and state.Phase=="Battle" then
   local allies={}
   for _,actor in ipairs(state.Actors) do if actor.Side==ui.Me.Side and not actor.Eliminated then table.insert(allies,actor) end end
   local actor=allies[(ui.SpectateIndex or 0)%math.max(#allies,1)+1]
   if actor then
    local teammate=Players:GetPlayerByUserId(tonumber(actor.ID) or 0)
    local humanoid=teammate and teammate.Character and teammate.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then workspace.CurrentCamera.CameraSubject=humanoid end
    ui.Presentation.Spectator.Text="SPECTATING / "..actor.Name
   else ui.Presentation.Spectator.Text="TEAM ELIMINATED" end
  elseif player.Character then
   local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
   if humanoid and workspace.CurrentCamera.CameraSubject~=humanoid then workspace.CurrentCamera.CameraSubject=humanoid end
  end
  local lock=state and ui.Profile and ui.Profile.Settings.ShiftLock and not UIS:GetFocusedTextBox()
  if lock then UIS.MouseBehavior=Enum.MouseBehavior.LockCenter; self.Locked=true
  elseif self.Locked then UIS.MouseBehavior=Enum.MouseBehavior.Default; self.Locked=false end
  Effects:Step()
 end)
end
return Camera
