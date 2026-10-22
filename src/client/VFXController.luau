local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Theme=require(game.ReplicatedStorage.Shared.UITheme)
local Moves=require(game.ReplicatedStorage.Shared.MoveDatabase)
local Elements=require(script.Parent.ElementalVFX)
local Audio=require(script.Parent.SoundController)
local VFX={Pool={},Active=0,Limit=24,Numbers=0,Parts={}}
function VFX:Init(ui)
 self.UI=ui; self.Destroyed=false
 ui.Gui.Destroying:Connect(function() self:Destroy() end)
end
function VFX:Destroy()
 self.Destroyed=true
 for p in pairs(self.Parts) do p:Destroy() end
 table.clear(self.Parts); table.clear(self.Pool); self.Active=0
end
function VFX:Acquire()
 if self.Destroyed then return nil end
 local mode=self.UI.Profile and self.UI.Profile.Settings.Graphics or "Medium"
 if self.Active>=(Theme.Graphics[mode] or Theme.Graphics.Medium).Effects then return nil end
 local p=table.remove(self.Pool) or Instance.new("Part")
 p.Name="LocalEffect"; p.Shape=Enum.PartType.Ball; p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false; p.Material=Enum.Material.Neon; p.Transparency=.3; p.Parent=workspace
 self.Parts[p]=true; self.Active+=1; return p
end
function VFX:Release(p)
 if self.Destroyed then p:Destroy(); return end
 p.Parent=nil; self.Active=math.max(0,self.Active-1)
 if #self.Pool<36 then table.insert(self.Pool,p) else p:Destroy() end
end
function VFX:Burst(position,element,phase,heavy)
 local profile=Elements.Get(element)
 local mode=self.UI.Profile and self.UI.Profile.Settings.Graphics or "Medium"
 local count=phase=="Impact" and (heavy and 9 or 5) or 3
 if mode=="Low" then count=math.min(count,3) end
 for i=1,count do
  local p=self:Acquire(); if not p then break end
  local angle=i*math.pi*2/count
  p.Color=profile.Color; p.Size=Vector3.new(.35,.35,.35); p.CFrame=CFrame.new(position)
  local length=heavy and 7 or 3
  if profile.Shape=="Bolt" or profile.Shape=="Streak" then p.Shape=Enum.PartType.Block; p.Size=Vector3.new(.2,.2,2.3)
  elseif profile.Shape=="Shard" or profile.Shape=="Leaf" then p.Shape=Enum.PartType.Block; p.Size=Vector3.new(.3,1.2,.3)
  elseif profile.Shape=="Flame" then p.Size=Vector3.new(.7,1.5,.7) end
  p.CFrame*=CFrame.Angles(angle,.5,angle)
  local duration=phase=="Aftermath" and .65 or .3
  local delta=Vector3.new(math.cos(angle)*length,phase=="Cast" and 2 or .5+math.sin(angle)*2,math.sin(angle)*length)
  local tween=Tween:Create(p,TweenInfo.new(duration,Enum.EasingStyle.Quad),{Position=position+delta,Transparency=1,Size=p.Size*.15}); tween:Play()
  tween.Completed:Once(function() self:Release(p) end)
 end
end
function VFX:DamageNumber(data)
 if self.Numbers>=18 then return end
 self.Numbers+=1
 local extra=data.Extra; local heavy=extra.Heavy
 local anchor=Instance.new("Part"); anchor.Anchored=true; anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false; anchor.CanTouch=false; anchor.Size=Vector3.one; anchor.Position=data.Position+Vector3.new(0,3,0); anchor.Parent=workspace
 local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(180,95); gui.AlwaysOnTop=true; gui.Parent=anchor
 local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=tostring(extra.Damage)..(heavy and "!" or ""); label.TextColor3=Theme.Light; label.TextStrokeColor3=Theme.Ink; label.TextStrokeTransparency=0; label.TextSize=heavy and 39 or 28; label.Font=Theme.Fonts.Header; label.Rotation=heavy and -9 or 6; label.Parent=gui
 if heavy then
  local word=label:Clone(); word.Text=Elements.Get(extra.Type).Word; word.TextSize=17; word.Position=UDim2.fromOffset(0,-30); word.TextColor3=Theme.Elements[extra.Type] or Theme.Primary; word.Parent=gui
 end
 Tween:Create(anchor,TweenInfo.new(.65),{Position=anchor.Position+Vector3.new(heavy and 1.5 or -.7,3.5,0)}):Play()
 Tween:Create(label,TweenInfo.new(.65),{TextTransparency=1,TextStrokeTransparency=1,Rotation=label.Rotation*1.5}):Play()
 Debris:AddItem(anchor,.7); task.delay(.7,function() self.Numbers=math.max(0,self.Numbers-1) end)
end
function VFX:Play(data)
 if typeof(data.Position)~="Vector3" then return end
 local settings=self.UI.Profile and self.UI.Profile.Settings
 if settings and not settings.Effects then return end
 local extra=data.Extra or {}; local move=Moves[data.Name]; local element=extra.Type or move and move.Type or "Normal"
 if data.Name=="Hit" then
  if Moves[extra.MoveID] then Audio:PlayMove(Moves[extra.MoveID],"Impact",data.Position) end
  self:DamageNumber(data); self:Burst(data.Position,element,"Impact",extra.Heavy)
  task.delay(.12,function() self:Burst(data.Position,element,"Aftermath",false) end)
  Audio:Play("Damage",data.Position,.07)
  if extra.AttackerID==tostring(game.Players.LocalPlayer.UserId) then self.UI.TrainingStats.Text=string.format("%d HIT • %d DAMAGE • %.1f DPS",extra.Combo,extra.ComboDamage,extra.DPS) end
 elseif move then
  Audio:PlayMove(move,"Cast",data.Position)
  self:Burst(data.Position,element,"Cast",extra.Slot==4)
  if move.Kind=="Projectile" and typeof(extra.Aim)=="Vector3" then
   task.delay(move.Startup,function()
    Audio:PlayMove(move,"Travel",data.Position)
    local bolt=self:Acquire(); if not bolt then return end
    bolt.Color=Elements.Get(element).Color; bolt.Size=Vector3.new(.9,.9,2); bolt.CFrame=CFrame.lookAt(data.Position,data.Position+extra.Aim)
    local tween=Tween:Create(bolt,TweenInfo.new(move.Range/move.ProjectileSpeed,Enum.EasingStyle.Linear),{Position=data.Position+extra.Aim*move.Range,Transparency=1}); tween:Play(); tween.Completed:Once(function() self:Release(bolt) end)
   end)
  elseif move.Kind=="AOE" then task.delay(move.Startup,function() self:Burst(data.Position,element,"Impact",true) end) end
 elseif data.Name=="Heal" or data.Name=="Potion" then self:Burst(data.Position,"Grass","Cast",false)
 elseif data.Name=="Defeat" then self:Burst(data.Position,"Ghost","Aftermath",true)
 else self:Burst(data.Position,"Normal","Cast",false) end
end
return VFX
