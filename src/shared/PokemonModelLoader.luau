local Database = require(script.Parent.PokemonDatabase)
local Settings = require(script.Parent.PokemonModelSettings)
local Loader = {}
function Loader:GetPokemonFolder(id)
 local data=Database[id]
 local pokemon=game:GetService("ReplicatedStorage"):FindFirstChild("Pokemon")
 return data and pokemon and pokemon.Models:FindFirstChild(data.FolderName)
end
function Loader:GetPlaceholder(id)
 local data=Database[id]
 if not data then return nil end
 local model=Instance.new("Model"); model.Name="PlaceholderModel"
 local root=Instance.new("Part"); root.Name="Body"; root.Size=Vector3.new(3,4,3); root.Shape=Enum.PartType.Ball
 root.Color=Color3.fromHSV(id/151,.65,.95); root.Material=Enum.Material.SmoothPlastic
 root.Anchored=true; root.CanCollide=false; root.Parent=model; model.PrimaryPart=root
 local gui=Instance.new("BillboardGui"); gui.Name="Identity"; gui.Size=UDim2.fromOffset(180,75); gui.StudsOffset=Vector3.new(0,3,0); gui.Parent=root
 local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.TextColor3=Color3.new(1,1,1); label.TextStrokeTransparency=.3; label.TextSize=14; label.Font=Enum.Font.GothamBold
 label.Text=string.format("[%03d] %s\n%s • %s",id,string.upper(data.Name),data.Type1,data.Rarity); label.Parent=gui
 return model
end
function Loader:ValidateModel(id,model)
 if not model then
  local folder=self:GetPokemonFolder(id)
  local slot=folder and folder:FindFirstChild("ModelSlot")
  if slot then
   for _,child in ipairs(slot:GetChildren()) do
    if child:IsA("Model") and child.Name~="PlaceholderModel" then model=child; break end
   end
  end
 end
 if not model or not model:IsA("Model") then return false,"No model" end
 local parts={}
 for _,child in ipairs(model:GetDescendants()) do if child:IsA("BasePart") then table.insert(parts,child) end end
 if #parts==0 then return false,"No BasePart or MeshPart" end
 if not model.PrimaryPart or not model.PrimaryPart:IsDescendantOf(model) then
  for _,name in ipairs({"HumanoidRootPart","Root","RootPart","Torso","Body"}) do
   local candidate=model:FindFirstChild(name,true)
   if candidate and candidate:IsA("BasePart") then model.PrimaryPart=candidate; break end
  end
  if not model.PrimaryPart then
   table.sort(parts,function(a,b) return a.Size.X*a.Size.Y*a.Size.Z>b.Size.X*b.Size.Y*b.Size.Z end)
   model.PrimaryPart=parts[1]
  end
 end
 return true,model.PrimaryPart
end
function Loader:HasCustomModel(id)
 local folder=self:GetPokemonFolder(id)
 local slot=folder and folder:FindFirstChild("ModelSlot")
 if slot then for _,model in ipairs(slot:GetChildren()) do if model:IsA("Model") and model.Name~="PlaceholderModel" and self:ValidateModel(id,model) then return true end end end
 return false
end
function Loader:GetModel(id)
 local folder=self:GetPokemonFolder(id)
 local slot=folder and folder:FindFirstChild("ModelSlot")
 if slot then
  for _,model in ipairs(slot:GetChildren()) do
   if model:IsA("Model") and model.Name~="PlaceholderModel" then
    local ok,reason=self:ValidateModel(id,model)
    if ok then return model end
    warn("[Pokemon Loader] "..folder.Name.." - "..tostring(reason)..". Using placeholder.")
   end
  end
  local placeholder=slot:FindFirstChild("PlaceholderModel")
  if placeholder and self:ValidateModel(id,placeholder) then return placeholder end
 end
 return nil
end
function Loader:ClonePokemon(id)
 local source=self:GetModel(id)
 local model=source and source:Clone() or self:GetPlaceholder(id)
 if not model then return nil end
 -- Imported scripts never execute, regardless of their source.
 for _,child in ipairs(model:GetDescendants()) do
  if child:IsA("LuaSourceContainer") then child:Destroy()
  elseif child:IsA("BasePart") then child.CanCollide=false; child.CanTouch=false; child.CanQuery=false; child.Massless=true; child.Anchored=true end
 end
 self:ValidateModel(id,model)
 local settings=Settings[id]
 local _,size=model:GetBoundingBox()
 if size.Y>0 then model:ScaleTo(model:GetScale()*settings.TargetHeight/size.Y*settings.Scale) end
 return model
end
return Loader
