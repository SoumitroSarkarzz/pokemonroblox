local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Camera={}
function Camera:Init(ui)
 local player=Players.LocalPlayer
 local function follow(character)
  local humanoid=character:WaitForChild("Humanoid",5)
  if humanoid then workspace.CurrentCamera.CameraSubject=humanoid; workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end
 end
 player.CharacterAdded:Connect(follow)
 if player.Character then task.spawn(follow,player.Character) end
 player.CameraMinZoomDistance=7; player.CameraMaxZoomDistance=22
 Run.RenderStepped:Connect(function()
  if ui.Match and ui.Profile and ui.Profile.Settings.ShiftLock and not UIS:GetFocusedTextBox() then UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
  elseif UIS.MouseBehavior==Enum.MouseBehavior.LockCenter then UIS.MouseBehavior=Enum.MouseBehavior.Default end
 end)
end
return Camera
