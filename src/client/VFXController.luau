local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local VFX={Pool={},Active=0,Limit=32}
function VFX:Init(ui) self.UI=ui end
function VFX:Acquire()
 if self.Active>=self.Limit then return nil end
 local p=table.remove(self.Pool) or Instance.new("Part")
 p.Name="LocalEffect"; p.Shape=Enum.PartType.Ball; p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.Material=Enum.Material.Neon; p.Transparency=.25; p.Parent=workspace
 self.Active+=1; return p
end
function VFX:Release(p)
 p.Parent=nil; self.Active-=1; table.insert(self.Pool,p)
end
function VFX:Play(data)
 local ui=self.UI
 if ui.Profile and not ui.Profile.Settings.Effects then return end
 if typeof(data.Position)~="Vector3" then return end
 local name=data.Name
 local color=(name=="Hit" and Color3.fromRGB(255,110,100)) or ((name=="Heal" or name=="Potion") and Color3.fromRGB(80,255,150)) or Color3.fromRGB(80,210,255)
 local p=self:Acquire()
 if p then
  p.Color=color; p.Size=Vector3.new(1,1,1); p.CFrame=CFrame.new(data.Position)
  local size=name=="Nova" and 28 or name=="GroundSlam" and 16 or name=="Ward" and 8 or 5
  local tween=Tween:Create(p,TweenInfo.new(.4),{Size=Vector3.new(size,size,size),Transparency=1}); tween:Play(); tween.Completed:Once(function() self:Release(p) end)
 end
 if name=="Pulse" and data.Extra and typeof(data.Extra.Aim)=="Vector3" then
  local bolt=self:Acquire()
  if bolt then bolt.Size=Vector3.new(1.2,1.2,3); bolt.Color=color; bolt.CFrame=CFrame.lookAt(data.Position,data.Position+data.Extra.Aim)
   local tween=Tween:Create(bolt,TweenInfo.new(65/85,Enum.EasingStyle.Linear),{Position=data.Position+data.Extra.Aim*65,Transparency=.9}); tween:Play(); tween.Completed:Once(function() self:Release(bolt) end)
  end
 end
 if name=="Hit" and data.Extra then
  local anchor=Instance.new("Part"); anchor.Anchored=true; anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false; anchor.Size=Vector3.one; anchor.Position=data.Position+Vector3.new(0,3,0); anchor.Parent=workspace
  local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(100,45); gui.AlwaysOnTop=true; gui.Parent=anchor
  local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=tostring(data.Extra.Damage); label.TextColor3=color; label.TextStrokeTransparency=.2; label.TextSize=25; label.Font=Enum.Font.GothamBold; label.Parent=gui
  Tween:Create(anchor,TweenInfo.new(.7),{Position=anchor.Position+Vector3.new(0,3,0)}):Play(); Debris:AddItem(anchor,.75)
  if data.Extra.AttackerID==tostring(game.Players.LocalPlayer.UserId) then
   ui.TrainingStats.Text=string.format("%d HIT COMBO • %d DAMAGE\n%.1f DPS",data.Extra.Combo,data.Extra.ComboDamage,data.Extra.DPS)
   task.delay(2,function() if ui.TrainingStats.Parent and not (ui.Match and ui.Match.Training) then ui.TrainingStats.Text="" end end)
  end
 end
end
return VFX
