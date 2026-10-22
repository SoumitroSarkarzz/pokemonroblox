local Run=game:GetService("RunService")
local Shared=game.ReplicatedStorage.Shared
local Rig=require(Shared.PokemonRigAdapter)
local Loader=require(Shared.PokemonModelLoader)
local Effects=require(script.Parent.CameraEffects)
local Moves=require(Shared.MoveDatabase)
local Theme=require(Shared.UITheme)
local Controller={Actors={},Connections={}}
function Controller:Destroy()
 for _,connection in ipairs(self.Connections) do connection:Disconnect() end; table.clear(self.Connections)
 for _,actor in pairs(self.Actors) do actor.Rig:Destroy() end; table.clear(self.Actors)
end
function Controller:Init(ui)
 self:Destroy(); self.UI=ui
 table.insert(self.Connections,ui.Gui.Destroying:Connect(function() self:Destroy() end))
 local function inspect(model)
  if not model:IsA("Model") or model.Name~="BattlePokemon" then return end
  task.defer(function()
   local visual=model:WaitForChild("VisualModel",5)
   if visual and self.UI.Gui.Parent then self.Actors[model]={Rig=Rig.new(visual),Tracks={},Last="",Offset=0} end
  end)
 end
 table.insert(self.Connections,workspace.DescendantAdded:Connect(inspect))
 for _,model in ipairs(workspace:GetDescendants()) do inspect(model) end
 table.insert(self.Connections,Run.RenderStepped:Connect(function()
  for model,actor in pairs(self.Actors) do
   if not model.Parent then actor.Rig:Destroy(); self.Actors[model]=nil; continue end
   local root=model.PrimaryPart
   if not root then continue end
   local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
   local state=speed>1 and "Run" or "Idle"
   local humanoid=model:FindFirstChildOfClass("Humanoid")
   if humanoid and humanoid.FloorMaterial==Enum.Material.Air then state=root.AssemblyLinearVelocity.Y>0 and "Jump" or "Fall" end
   for _,track in pairs(actor.Rig.Tracks) do track:AdjustSpeed(os.clock()<Effects.PausedUntil and 0 or 1) end
   if state~=actor.Last then
    actor.Last=state
    for _,track in pairs(actor.Tracks) do track:Stop(.15) end
    local folder=Loader:GetPokemonFolder(model:GetAttribute("PokemonID"))
    local animation=folder and folder.Animations:FindFirstChild(state)
    if animation and animation.AnimationId~="" then
     local track=actor.Rig:PlayAnimation(animation)
     if track then actor.Tracks[state]=track end
    end
   end
   -- Unanimated rigid assets remain functional, without altering combat roots.
   local visual=actor.Rig.Model
   local rootPart=visual.PrimaryPart
   if rootPart then
    local joint=rootPart:FindFirstChild("Procedural")
    if joint and joint:IsA("Motor6D") and os.clock()>=Effects.PausedUntil then joint.Transform=CFrame.new(0,math.sin(os.clock()*9)*math.min(speed/20,1)*.12,0)*CFrame.Angles(os.clock()<(actor.MotionUntil or 0) and -.18 or 0,0,math.sin(os.clock()*4)*.015) end
   end
  end
 end))
end
function Controller:Effect(data)
 for model,actor in pairs(self.Actors) do
  if model:GetAttribute("ActorID")==data.ActorID then
   local folder=Loader:GetPokemonFolder(model:GetAttribute("PokemonID")); if not folder then return end
   local mapping={Basic="M1_"..tostring(data.Extra and data.Extra.Combo or 1),Pulse="Ability1",Rush="Ability2",Ward="Ability3",Nova="Ability4",Hit="Hit",Switch="SwitchOut",Dash="Dash",Defeat="Defeat"}
   local move=Moves[data.Name]
   local name=data.Name=="Basic" and mapping.Basic or move and move.Animation or mapping[data.Name]
   actor.MotionUntil=os.clock()+.18
   if data.Name=="Defeat" then
    for _,part in ipairs(actor.Rig.Model:GetDescendants()) do
     if part:IsA("BasePart") then game:GetService("TweenService"):Create(part,TweenInfo.new(.3),{LocalTransparencyModifier=.8,Color=part.Color:Lerp(Theme.Muted,.7)}):Play() end
    end
   end
   if name then actor.Rig:PlayAnimation(folder.Animations:FindFirstChild(name)) end
   local sound=folder.Sounds:FindFirstChild(data.Name=="Basic" and "Attack" or name or "Spawn")
   if sound and sound.SoundId~="" then
    local clone=sound:Clone(); clone.Parent=model.PrimaryPart; clone:Play(); game:GetService("Debris"):AddItem(clone,10)
   end
   local vfx=folder.VFX:FindFirstChild(name or "")
   if vfx and (not self.UI.Profile or self.UI.Profile.Settings.Effects) then
    for _,source in ipairs(vfx:GetChildren()) do
     local clone=source:Clone(); clone.Parent=model.PrimaryPart
     if clone:IsA("ParticleEmitter") then clone:Emit(math.min((Theme.Graphics[self.UI.Profile and self.UI.Profile.Settings.Graphics or "Medium"] or Theme.Graphics.Medium).Particles,clone:GetAttribute("EmitCount") or 12)) end
     game:GetService("Debris"):AddItem(clone,3)
    end
   end
  end
 end
end
return Controller
