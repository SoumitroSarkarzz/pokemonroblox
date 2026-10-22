local Service=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local Sound={MoveSlots={},Slots={},Active=0,UI=nil}
local pitches={Hover=1.4,Click=1.1,MenuOpen=.95,MenuClose=.8,MatchFound=1.2,Countdown=1,AbilityReady=1.5,Damage=.7,Switch=1.3,Victory=1.6,Defeat=.75,RankUp=1.8,CrateReveal=1.4}
function Sound:Init(ui) self.UI=ui end
function Sound:Play(name,position,volume,override)
 if self.Active>=10 then return end
 local now=os.clock()
 if name=="Hover" and now-(self.LastHover or 0)<.08 then return end
 if name=="Hover" then self.LastHover=now end
 local id=override or self.Slots[name] or "rbxasset://sounds/electronicpingshort.wav"
 if id=="" then return end
 local sound=Instance.new("Sound"); sound.SoundId=id; sound.Volume=math.clamp(volume or .12,0,.4); sound.PlaybackSpeed=pitches[name] or 1
 sound.SoundGroup=self.Group
 local anchor
 if typeof(position)=="Vector3" then
  anchor=Instance.new("Part"); anchor.Anchored=true; anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false; anchor.CanTouch=false; anchor.Size=Vector3.one; anchor.Position=position; anchor.Parent=workspace
  sound.Parent=anchor; sound.RollOffMaxDistance=85; Debris:AddItem(anchor,3)
 else sound.Parent=Service; Debris:AddItem(sound,3) end
 self.Active+=1
 sound:Play()
 task.delay(3,function() self.Active=math.max(0,self.Active-1) end)
end
function Sound:PlayMove(move,phase,position)
 local layers=self.MoveSlots[move.MoveID] or self.MoveSlots[move.Type] or {}
 local id=layers[phase]
 if id and id~="" then self:Play(phase,position,phase=="Impact" and .15 or .07,id)
 elseif phase=="Cast" then self:Play("Click",position,.045) end
end
return Sound
