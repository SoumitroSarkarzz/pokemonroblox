-- Geometry identities complement the shared color palette; all effects are local.
local Theme=require(game.ReplicatedStorage.Shared.UITheme)
local Library={}
local profiles={
 Fire={Shape="Flame",Word="BOOM!"},Water={Shape="Ring",Word="SPLASH!"},Electric={Shape="Bolt",Word="ZAP!"},Grass={Shape="Leaf",Word="THWACK!"},
 Ice={Shape="Shard",Word="CRACK!"},Fighting={Shape="Streak",Word="BAM!"},Poison={Shape="Bubble",Word="POOF!"},Ground={Shape="Shard",Word="THUD!"},
 Flying={Shape="Ring",Word="SWOOSH!"},Psychic={Shape="Ring",Word="PSH!"},Bug={Shape="Leaf",Word="SNAP!"},Rock={Shape="Shard",Word="CRACK!"},
 Ghost={Shape="Bubble",Word="PHOOM!"},Dragon={Shape="Flame",Word="ROAR!"},Dark={Shape="Streak",Word="WHAM!"},Steel={Shape="Shard",Word="CLANG!"},Fairy={Shape="Star",Word="POP!"},Normal={Shape="Streak",Word="BAM!"},
}
function Library.Get(element)
 local p=profiles[element] or profiles.Normal
 return {Color=Theme.Elements[element] or Theme.Elements.Normal,Shape=p.Shape,Word=p.Word}
end
return Library
