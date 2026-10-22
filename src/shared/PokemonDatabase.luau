local Kanto = require(script.Parent.Kanto)
local Database = {}
local legendary = {[144]=true,[145]=true,[146]=true,[150]=true}
local epic = {[3]=true,[6]=true,[9]=true,[65]=true,[68]=true,[94]=true,[130]=true,[143]=true,[149]=true}
local rare = {[25]=true,[26]=true,[38]=true,[59]=true,[103]=true,[106]=true,[107]=true,[113]=true,[123]=true,[131]=true,[133]=true,[142]=true}
local roles = {Fire="Brawler",Water="Ranged",Grass="Controller",Electric="Speedster",Psychic="Ranged",Ghost="Assassin",Rock="Tank",Ground="Tank",Fighting="Brawler",Fairy="Support",Ice="Controller",Dragon="Brawler",Flying="Speedster",Bug="Controller",Poison="Controller",Normal="Brawler",Steel="Tank",Dark="Assassin"}
for _, row in ipairs(Kanto) do
 local id, name, type1, type2 = table.unpack(row)
 local rarity = id==151 and "Mythic" or legendary[id] and "Legendary" or epic[id] and "Epic" or rare[id] and "Rare" or id%3==0 and "Uncommon" or "Common"
 local role = roles[type1]
 Database[id] = {
  ID=id,CreatureID=id,Name=name,FolderName=string.format("%03d_%s",id,name),Generation=1,Region="Kanto",
  Type1=type1,Type2=type2,Rarity=rarity,Role=role,Difficulty=rarity=="Common" and 1 or 2,UnlockLevel=1,LevelRequirement=1,
  Price=({Common=350,Uncommon=650,Rare=1500,Epic=3000,Legendary=6000,Mythic=9000})[rarity],
  Description=name.." is a "..type1.." "..string.lower(role)..". Placeholder moves are shared archetypes until custom move sets are authored.",
  Stats={HP=100,WalkSpeed=role=="Speedster" and 22 or 19,JumpPower=50,DashDistance=25},
  BaseHP=100,MovementSpeed=19,DashDistance=25,JumpPower=50,PassiveAbility="Balanced",UltimateChargeModifier=1,
  Model={Folder=string.format("%03d_%s",id,name),ModelSlot="ModelSlot"},ModelName=string.format("%03d_%s",id,name),
  Icon=string.format("%03d_%s",id,name),AnimationSet=id,SoundSet=id,VFXSet=id,
  Abilities={"Pulse","Rush","Ward","Nova"},Ability1="Pulse",Ability2="Rush",Ability3="Ward",Ability4="Nova",
 }
end
return Database
