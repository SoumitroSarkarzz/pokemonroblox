local Database=require(script.Parent.PokemonDatabase)
local Config=require(script.Parent.Config)
local Loader=require(script.Parent.PokemonModelLoader)
local Setup={Watching=setmetatable({},{__mode="k"})}
local function ensure(parent,class,name)
 local found=parent:FindFirstChild(name)
 if found then return found end
 local obj=Instance.new(class); obj.Name=name; obj.Parent=parent; return obj
end
function Setup.Run()
 local root=ensure(game:GetService("ReplicatedStorage"),"Folder","Pokemon")
 for _,name in ipairs({"Models","Icons","Data","Animations","VFX","Sounds"}) do ensure(root,"Folder",name) end
 for id,data in ipairs(Database) do
  local folder=ensure(root.Models,"Folder",data.FolderName)
  local slot=ensure(folder,"Folder","ModelSlot")
  if not slot:FindFirstChildWhichIsA("Model") then Loader:GetPlaceholder(id).Parent=slot end
  local animations=ensure(folder,"Folder","Animations")
  for _,name in ipairs(Config.AnimationNames) do ensure(animations,"Animation",name) end
  local vfx=ensure(folder,"Folder","VFX")
  for i=1,4 do ensure(vfx,"Folder","Ability"..i) end
  local sounds=ensure(folder,"Folder","Sounds")
  for _,name in ipairs(Config.SoundNames) do ensure(sounds,"Sound",name) end
  local ui=ensure(folder,"Folder","UI")
  local icons=ensure(root.Icons,"Folder",data.FolderName)
  for _,name in ipairs({"Icon","Portrait"}) do ensure(ui,"StringValue",name); ensure(icons,"StringValue",name) end
  folder:SetAttribute("PokemonID",id); folder:SetAttribute("PokemonName",data.Name)
  folder:SetAttribute("Region","Kanto"); folder:SetAttribute("Generation",1)
  game:GetService("CollectionService"):AddTag(folder,"PokemonAssetSlot")
  if not Setup.Watching[folder] then
   Setup.Watching[folder]=true
   local queued=false
   local function refresh()
    if queued then return end; queued=true
    task.defer(function()
     queued=false
     if not folder.Parent then return end
     folder:SetAttribute("ModelInstalled",Loader:HasCustomModel(id))
     folder:SetAttribute("IconInstalled",icons.Icon.Value~="")
     local complete=true
     for _,name in ipairs(Config.AnimationNames) do if animations[name].AnimationId=="" then complete=false; break end end
     folder:SetAttribute("AnimationsInstalled",complete)
     folder:SetAttribute("ReadyForBattle",Loader:GetModel(id)~=nil)
    end)
   end
   slot.DescendantAdded:Connect(refresh); slot.DescendantRemoving:Connect(refresh)
   icons.Icon.Changed:Connect(refresh)
   for _,animation in ipairs(animations:GetChildren()) do if animation:IsA("Animation") then animation.Changed:Connect(refresh) end end
   refresh()
  end
 end
 return root
end
function Setup.Report()
 local counts={Models=0,Icons=0,Animations=0,Ready=0}; local missing={}; local broken={}
 for id,data in ipairs(Database) do
  local folder=Loader:GetPokemonFolder(id)
  if folder then
   local custom=Loader:HasCustomModel(id)
   local icon=game.ReplicatedStorage.Pokemon.Icons[data.FolderName].Icon.Value~=""
   local complete=true
   for _,name in ipairs(Config.AnimationNames) do if folder.Animations[name].AnimationId=="" then complete=false; break end end
   if custom then counts.Models+=1 else table.insert(missing,data.FolderName) end
   if icon then counts.Icons+=1 end
   if complete then counts.Animations+=1 end
   local ready=Loader:GetModel(id)~=nil
   if ready then counts.Ready+=1 end
   for _,model in ipairs(folder.ModelSlot:GetChildren()) do
    if model:IsA("Model") and model.Name~="PlaceholderModel" then
     local ok,reason=Loader:ValidateModel(id,model)
     if not ok then table.insert(broken,data.FolderName.." - "..tostring(reason)) end
    end
   end
   folder:SetAttribute("ModelInstalled",custom); folder:SetAttribute("IconInstalled",icon)
   folder:SetAttribute("AnimationsInstalled",complete); folder:SetAttribute("ReadyForBattle",ready)
  end
 end
 print(string.format("POKEMON ASSET STATUS\nModels Installed: %d / 151\nIcons Installed: %d / 151\nAnimations Complete: %d / 151\nBattle Ready (including placeholders): %d / 151",counts.Models,counts.Icons,counts.Animations,counts.Ready))
 print("Missing Models: "..table.concat(missing,", ")); print("Broken Models: "..table.concat(broken,", "))
 return counts,missing,broken
end
return Setup
