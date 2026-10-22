local Theme=require(game.ReplicatedStorage.Shared.UITheme)
local Effects={UI=nil,ShakeUntil=0,Strength=0,FOVUntil=0,FOV=0,Previous=CFrame.new(),PausedUntil=0}
function Effects:Init(ui) self.UI=ui end
function Effects:Shake(strength,duration)
 local setting=self.UI and self.UI.Profile and self.UI.Profile.Settings.CameraShake or "Low"
 local multiplier=({Off=0,Low=.3,Medium=.6,High=1})[setting] or .3
 self.Strength=math.clamp(strength or .15,0,.45)*multiplier; self.ShakeUntil=os.clock()+math.min(duration or .15,.45)
end
function Effects:PunchFOV(amount,duration) self.FOV=math.clamp(amount or 3,-6,6); self.FOVUntil=os.clock()+(duration or .18) end
function Effects:ImpactZoom() self:PunchFOV(-3,.12) end
function Effects:UltimateCamera() self:Shake(.3,.3); self:PunchFOV(-5,.4) end
function Effects:Hitstop(duration) self.PausedUntil=os.clock()+math.clamp(duration or .03,0,.08) end
function Effects:CrateCamera()
 local chambers=game:GetService("CollectionService"):GetTagged("CrateChamber")
 local chamber=chambers[1]; local camera=workspace.CurrentCamera
 if not chamber or not camera then self:PunchFOV(-4,.5); return end
 self:Reset()
 self.Saved={Type=camera.CameraType,Subject=camera.CameraSubject,CFrame=camera.CFrame}
 self.CinematicStart=os.clock(); self.CinematicUntil=os.clock()+1.3
 self.CinematicTarget=CFrame.lookAt(chamber.Position+Vector3.new(8,5,12),chamber.Position)
 camera.CameraType=Enum.CameraType.Scriptable
end
function Effects:Reset()
 if self.Saved and workspace.CurrentCamera then
  local camera=workspace.CurrentCamera; camera.CameraType=self.Saved.Type; camera.CameraSubject=self.Saved.Subject; camera.CFrame=self.Saved.CFrame
 end
 self.Saved=nil; self.CinematicUntil=0
 self.ShakeUntil=0; self.FOVUntil=0; self.Strength=0; self.PausedUntil=0
 local camera=workspace.CurrentCamera
 if camera then camera.FieldOfView=self.BaseFOV or 70 end
 self.Previous=CFrame.new()
end
function Effects:Step()
 local camera=workspace.CurrentCamera; if not camera then return end
 self.BaseFOV=self.BaseFOV or camera.FieldOfView
 local now=os.clock()
 if self.Saved then
  if now>=(self.CinematicUntil or 0) then self:Reset()
  else camera.CFrame=self.Saved.CFrame:Lerp(self.CinematicTarget,math.clamp((now-self.CinematicStart)/.5,0,1)) end
 end
 if now<self.ShakeUntil then
  local strength=self.Strength*(self.ShakeUntil-now)/.45
  camera.CFrame*=CFrame.new(math.noise(now*40)*strength,math.noise(now*40,12)*strength,0)
 end
 local target=self.BaseFOV+(now<self.FOVUntil and self.FOV or 0)
 camera.FieldOfView+=(target-camera.FieldOfView)*.25
end
return Effects
