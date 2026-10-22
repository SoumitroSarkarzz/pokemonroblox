local Shared=game.ReplicatedStorage.Shared
local Loader=require(Shared.PokemonModelLoader)
local Settings=require(Shared.PokemonModelSettings)
local Database=require(Shared.PokemonDatabase)
local Creatures={}
function Creatures:Spawn(actor,id,cf,parent)
 if actor.Character then actor.Character:Destroy() end
 local data=Database[id]; local settings=Settings[id]
 local model=Instance.new("Model"); model.Name="BattlePokemon"
 model:SetAttribute("PokemonID",id); model:SetAttribute("ActorID",actor.ID); model:SetAttribute("Team",actor.Side)
 local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Size=Vector3.new(3,3,3); root.Transparency=1; root.CanCollide=true; root.CFrame=cf; root.Parent=model
 local alias=Instance.new("ObjectValue"); alias.Name="CombatRoot"; alias.Value=root; alias.Parent=model
 local hurtbox=Instance.new("Part"); hurtbox.Name="Hurtbox"; hurtbox.Size=Vector3.new(4,5,4); hurtbox.Transparency=1; hurtbox.CanCollide=false; hurtbox.Massless=true; hurtbox.Parent=model
 hurtbox.CFrame=root.CFrame
 local weld=Instance.new("WeldConstraint"); weld.Part0=root; weld.Part1=hurtbox; weld.Parent=hurtbox
 for _,name in ipairs({"Attachments","Effects","Audio","GroundDetector","HitboxAttachments"}) do local folder=Instance.new("Folder"); folder.Name=name; folder.Parent=model end
 local visual=Loader:ClonePokemon(id); visual.Name="VisualModel"; visual.Parent=model
 local orientation=settings.RotationOffset
 visual:PivotTo(cf*CFrame.new(settings.RootOffset+Vector3.new(0,settings.GroundOffset,0))*CFrame.Angles(math.rad(orientation.X),math.rad(orientation.Y),math.rad(orientation.Z)))
 -- Preserve imported Motor6Ds and bones. Only join disconnected assemblies.
 local parts={}; local edges={}
 for _,node in ipairs(visual:GetDescendants()) do
  if node:IsA("BasePart") then parts[node]=true; edges[node]={}; node.Anchored=false end
 end
 for _,node in ipairs(visual:GetDescendants()) do
  if node:IsA("JointInstance") or node:IsA("WeldConstraint") then
   local a,b=node.Part0,node.Part1
   if parts[a] and parts[b] then table.insert(edges[a],b); table.insert(edges[b],a) end
  end
 end
 local visited={}
 local function visit(part)
  if visited[part] then return end
  visited[part]=true
  for _,neighbor in ipairs(edges[part]) do visit(neighbor) end
 end
 visit(visual.PrimaryPart)
 for part in pairs(parts) do
  if not visited[part] then
   local weld=Instance.new("WeldConstraint"); weld.Part0=visual.PrimaryPart; weld.Part1=part; weld.Parent=part
   visit(part)
  end
 end
 for _,node in ipairs(visual:GetDescendants()) do if node:IsA("Humanoid") then node:Destroy() end end
 local motor=Instance.new("Motor6D"); motor.Name="Procedural"; motor.Part0=root; motor.Part1=visual.PrimaryPart
 motor.C0=root.CFrame:ToObjectSpace(visual.PrimaryPart.CFrame); motor.Parent=visual.PrimaryPart
 local humanoid=Instance.new("Humanoid"); humanoid.Name="Humanoid"; humanoid.RequiresNeck=false; humanoid.MaxHealth=100; humanoid.Health=math.max(1,actor.Health[actor.Active]); humanoid.WalkSpeed=data.Stats.WalkSpeed; humanoid.UseJumpPower=true; humanoid.JumpPower=50; humanoid.HipHeight=1.5; humanoid.BreakJointsOnDeath=false; humanoid.Parent=model
 local animator=Instance.new("Animator"); animator.Parent=humanoid
 local highlight=Instance.new("Highlight"); highlight.Name="TeamOutline"; highlight.FillTransparency=1; highlight.OutlineColor=actor.Side==1 and Color3.fromRGB(70,190,255) or Color3.fromRGB(255,90,120); highlight.Parent=model
 model.PrimaryPart=root; model.Parent=parent
 actor.Character=model; actor.Root=root; actor.Humanoid=humanoid; actor.LastPosition=cf.Position; actor.LastCheck=os.clock()
 -- Server owns combat movement. Clients supply direction intents, never positions.
 root:SetNetworkOwner(nil)
 if actor.Player then actor.Player.Character=model end
 return model
end
return Creatures
