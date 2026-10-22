-- Run from the Studio command bar, outside Play, to persist new missing slots:
-- require(game.ServerStorage.PokemonAssetSetup).Run()
local Setup={}
function Setup.Run()
 assert(game:GetService("RunService"):IsStudio(),"Studio-only utility")
 local assets=require(game.ReplicatedStorage.Shared.AssetSetup)
 assets.Run()
 return assets.Report()
end
return Setup
