-- Run on the SERVER during a Studio Play session:
-- require(game.ServerStorage.StudioChecks).Run()
local Checks={}
function Checks.Run()
 local run=game:GetService("RunService")
 assert(run:IsStudio() and run:IsRunning() and run:IsServer(),"Run on the server during Studio Play")
 local shared=game.ReplicatedStorage.Shared
 local db=require(shared.PokemonDatabase)
 local loader=require(shared.PokemonModelLoader)
 local setup=require(shared.AssetSetup)
 local count=#game.ReplicatedStorage.Pokemon.Models:GetChildren()
 setup.Run(); setup.Run()
 assert(#game.ReplicatedStorage.Pokemon.Models:GetChildren()==count,"Setup duplicated slots")
 for id,entry in ipairs(db) do
  local clone=loader:ClonePokemon(id)
  assert(clone and clone.PrimaryPart,"No usable model for "..entry.FolderName)
  for _,node in ipairs(clone:GetDescendants()) do assert(not node:IsA("LuaSourceContainer"),"Imported code survived sanitization") end
  clone:Destroy()
 end
 local valid=Instance.new("Model")
 local part=Instance.new("Part"); part.Name="RootPart"; part.Parent=valid
 assert(loader:ValidateModel(25,valid),"Cannot infer imported root")
 assert(valid.PrimaryPart==part,"Inferred wrong root")
 valid:Destroy()
 local broken=Instance.new("Model")
 assert(not loader:ValidateModel(25,broken),"Accepted empty model")
 broken:Destroy()
 print("STUDIO CHECKS PASS: 151 model clones, sanitization, root inference, malformed model rejection, idempotent setup")
 return true
end
return Checks
