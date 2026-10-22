-- Presentation-only extension of UIController. No authority over match state.
local Tween=game:GetService("TweenService")
local Players=game:GetService("Players")
local Theme=require(game.ReplicatedStorage.Shared.UITheme)
local DB=require(game.ReplicatedStorage.Shared.PokemonDatabase)
local Moves=require(game.ReplicatedStorage.Shared.MoveDatabase)
local Viewport=require(game.ReplicatedStorage.Shared.PokemonViewport)
local Comic=require(script.Parent.ComicUI)
local Audio=require(script.Parent.SoundController)
local Camera=require(script.Parent.CameraEffects)
local P={}; P.__index=P
local make,text,button=Comic.Make,Comic.Text,Comic.Button
local function panel(parent,pos,size,accent)
 local frame=make("Frame",parent,{Position=pos,Size=size,BackgroundColor3=Theme.Dark,BorderSizePixel=0})
 Comic.Decorate(frame,accent); return frame
end
local function preview(parent,id,size,pos)
 local frame=make("ViewportFrame",parent,{Size=size,Position=pos,BackgroundTransparency=1})
 local view=Viewport.new(frame); view:DisplayPokemon(frame,id)
 return view,frame
end
function P.new(ui)
 local self=setmetatable({UI=ui,Notifications={},TeamCards={},HUDViews={},Cooldowns={},IntroViews={},SwitchViews={},ResultViews={},Token=0},P)
 Audio:Init(ui); Camera:Init(ui)
 ui.Notice.Visible=false
 Comic.Decorate(ui.Top,Theme.Primary); Comic.Decorate(ui.Sidebar,Theme.Secondary); Comic.Decorate(ui.Panel,Theme.Accent)
 ui.Sidebar.Rotation=-.3; ui.Stats.Font=Theme.Fonts.Stats; ui.Stats.TextSize=13
 for row=1,3 do for column=1,11 do
  local dot=make("Frame",ui.Panel,{Position=UDim2.new(1,-160+column*11,0,7+row*10),Size=UDim2.fromOffset(3,3),BackgroundColor3=Theme.Primary,BackgroundTransparency=.7,BorderSizePixel=0})
  make("UICorner",dot,{CornerRadius=UDim.new(1,0)})
 end end
 self.Dim=make("Frame",ui.Root,{Size=UDim2.fromScale(1,1),BackgroundColor3=Theme.Ink,BackgroundTransparency=1,Visible=false,ZIndex=0,BorderSizePixel=0})
 self.Host=make("Frame",ui.Root,{Position=UDim2.new(.5,-190,0,86),Size=UDim2.fromOffset(380,260),BackgroundTransparency=1,ZIndex=30})
 make("UIListLayout",self.Host,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
 self.Health=panel(ui.HUD,UDim2.new(0,18,1,-240),UDim2.fromOffset(298,145),Theme.Success)
 ui.HP.Parent=self.Health; ui.HP.Position=UDim2.fromOffset(104,10); ui.HP.Size=UDim2.fromOffset(184,58); ui.HP.TextSize=18
 ui.HealthTrack.Parent=self.Health; ui.HealthTrack.Position=UDim2.fromOffset(104,80); ui.HealthTrack.Size=UDim2.fromOffset(178,16)
 self.HealthTrail=make("Frame",ui.HealthTrack,{Size=UDim2.fromScale(1,1),BackgroundColor3=Theme.Warning,BorderSizePixel=0,ZIndex=1})
 ui.HealthFill.ZIndex=2; ui.HealthFill.BackgroundColor3=Theme.Success
 self.Status=text(self.Health,"",UDim2.fromOffset(104,103),UDim2.fromOffset(180,28),11,Theme.Warning)
 self.Portrait=make("ViewportFrame",self.Health,{Position=UDim2.fromOffset(-3,-18),Size=UDim2.fromOffset(105,133),BackgroundTransparency=1})
 make("UIAspectRatioConstraint",self.Portrait,{AspectRatio=.8})
 self.PortraitView=Viewport.new(self.Portrait)
 ui.Bench.Position=UDim2.new(0,24,1,-88); ui.Bench.Size=UDim2.fromOffset(285,70); ui.Bench.TextSize=11
 for i=1,3 do
  local card=panel(ui.HUD,UDim2.new(0,18+(i-1)*100,1,-348),UDim2.fromOffset(92,96),Theme.Muted)
  local image=make("ViewportFrame",card,{Position=UDim2.fromOffset(0,-8),Size=UDim2.fromOffset(90,69),BackgroundTransparency=1})
  local label=text(card,"",UDim2.fromOffset(5,61),UDim2.fromOffset(82,30),10)
  local cross=text(card,"×",UDim2.fromOffset(20,0),UDim2.fromOffset(60,70),48,Theme.Danger); cross.Visible=false
  local hit=button(card,"",UDim2.fromScale(0,0),UDim2.fromScale(1,1),function() self:SelectSwitch(i) end); hit.BackgroundTransparency=1
  self.TeamCards[i]={Frame=card,Image=image,Label=label,Cross=cross,View=Viewport.new(image)}
 end
 self.Enemy=panel(ui.HUD,UDim2.new(1,-302,0,118),UDim2.fromOffset(280,90),Theme.Danger)
 self.EnemyText=text(self.Enemy,"",UDim2.fromOffset(82,8),UDim2.fromOffset(185,70),13)
 self.EnemyImage=make("ViewportFrame",self.Enemy,{Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(80,85),BackgroundTransparency=1})
 self.EnemyView=Viewport.new(self.EnemyImage)
 ui.Roster2.Position=UDim2.new(1,-285,0,220); ui.Roster2.TextSize=12
 ui.Roster1.TextSize=12
 self.AbilityBadges={}
 for i,b in ipairs(ui.Buttons) do
  b.Position=UDim2.new(.55,(i-2.5)*108-50,1,-116); b.Size=UDim2.fromOffset(100,80); b.TextSize=12
  self.AbilityBadges[i]=text(b,"",UDim2.new(1,-35,0,2),UDim2.fromOffset(30,12),9,Theme.Primary)
  b.MouseEnter:Connect(function() if ui.Me then self:Tooltip(Moves[DB[ui.Me.Team[ui.Me.Active]].Abilities[i]]) end end)
  b.MouseLeave:Connect(function() self:HideTooltip() end)
 end
 self.ActionButtons={}
 for _,node in ipairs(ui.HUD:GetChildren()) do if node:IsA("TextButton") and (string.find(node.Text,"DASH") or string.find(node.Text,"SWITCH") or string.find(node.Text,"POTION") or string.find(node.Text,"GUARD") or node.Text=="M1") then table.insert(self.ActionButtons,node) end end
 self.Combo=text(ui.HUD,"",UDim2.new(.7,-125,.48,-50),UDim2.fromOffset(250,95),29,Theme.Primary); self.Combo.Rotation=-5; self.Combo.TextXAlignment=Enum.TextXAlignment.Center
 self.Flash=make("Frame",ui.Root,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=22,Visible=false})
 self.FlashStroke=Comic.Stroke(self.Flash,Theme.Danger,7)
 self.Spectator=text(ui.HUD,"",UDim2.new(.35,0,0,110),UDim2.new(.3,0,0,45),15,Theme.Secondary)
 self.SpectateButton=button(ui.HUD,"NEXT TEAMMATE →",UDim2.new(.5,-90,0,160),UDim2.fromOffset(180,30),function() ui.SpectateIndex=(ui.SpectateIndex or 0)+1 end)
 self.SpectateButton.Visible=false
 self.DesktopLayout={}
 for _,node in ipairs(ui.HUD:GetDescendants()) do
  if node:IsA("GuiObject") then self.DesktopLayout[node]={Position=node.Position,Size=node.Size} end
 end
 -- Only text objects expose TextSize.
 for node,layout in pairs(self.DesktopLayout) do if node:IsA("TextLabel") or node:IsA("TextButton") then layout.TextSize=node.TextSize else layout.TextSize=nil end end
 ui.Gui.Destroying:Connect(function()
  self:Clear(self.IntroViews); self:Clear(self.SwitchViews); self:Clear(self.ResultViews)
  self.PortraitView:Clear(); self.EnemyView:Clear()
  for _,card in ipairs(self.TeamCards) do card.View:Clear() end
  Camera:Reset()
 end)
 return self
end
function P:Responsive(viewport)
 local ui=self.UI
 for node,layout in pairs(self.DesktopLayout) do
  if node.Parent then node.Position=layout.Position; node.Size=layout.Size; if layout.TextSize then node.TextSize=layout.TextSize end end
 end
 ui.Bench.Visible=true; ui.Roster1.Visible=true; ui.Roster2.Visible=true
 for _,card in ipairs(self.TeamCards) do card.Frame.Visible=true end
 if not ui.MobileCompact then
  self.Host.Position=UDim2.new(.5,-190,0,86); self.Host.Size=UDim2.fromOffset(380,260)
  return
 end
 local landscape=viewport.Y<560
 ui.Brand.TextSize=15; ui.Brand.Size=UDim2.fromOffset(165,26)
 self.Host.Position=UDim2.new(.5,-math.min(190,(viewport.X-20)/2),0,86); self.Host.Size=UDim2.fromOffset(math.min(380,viewport.X-20),230)
 self.Health.Position=UDim2.new(0,12,1,landscape and -152 or -255); self.Health.Size=UDim2.fromOffset(landscape and 230 or 298,landscape and 85 or 145)
 if landscape then
  ui.HP.Position=UDim2.fromOffset(75,6); ui.HP.Size=UDim2.fromOffset(148,38); ui.HP.TextSize=13
  ui.HealthTrack.Position=UDim2.fromOffset(75,47); ui.HealthTrack.Size=UDim2.fromOffset(145,12)
  self.Status.Position=UDim2.fromOffset(75,60); self.Status.Size=UDim2.fromOffset(145,20)
  self.Portrait.Size=UDim2.fromOffset(75,90)
 end
 ui.Bench.Visible=not landscape
 for i,card in ipairs(self.TeamCards) do card.Frame.Visible=not landscape; card.Frame.Position=UDim2.new(0,12+(i-1)*98,1,-360) end
 for i,b in ipairs(ui.Buttons) do b.Position=UDim2.new(.5,(i-2.5)*84-39,1,-82); b.Size=UDim2.fromOffset(78,68); b.TextSize=11 end
 for i,b in ipairs(self.ActionButtons) do b.Position=UDim2.new(1,-68,1,-140-(i-1)*48); b.Size=UDim2.fromOffset(56,44); b.TextSize=10 end
 self.Enemy.Position=UDim2.fromOffset(12,88); self.Enemy.Size=UDim2.fromOffset(230,85); self.EnemyText.Size=UDim2.fromOffset(145,68); self.EnemyText.TextSize=11
 ui.Roster1.Visible=false; ui.Roster2.Visible=false
 ui.Timer.Position=UDim2.new(1,-128,0,85); ui.Timer.Size=UDim2.fromOffset(115,65); ui.Timer.TextSize=15
 ui.TrainingStats.Position=UDim2.new(.5,-110,0,180); ui.TrainingStats.Size=UDim2.fromOffset(220,60); ui.TrainingStats.TextSize=12
 ui.Reset.Position=UDim2.new(.5,-80,0,235); ui.Reset.Size=UDim2.fromOffset(160,36)
 self.Combo.Position=UDim2.new(.5,-110,.38,0); self.Combo.Size=UDim2.fromOffset(220,80); self.Combo.TextSize=24
end
function P:FitOverlay(frame,width,height)
 local available=self.UI.Root.AbsoluteSize
 local scale=math.min(1,(available.X-24)/width,(available.Y-100)/height)
 frame.AnchorPoint=Vector2.new(.5,.5); frame.Position=UDim2.fromScale(.5,.5)
 local scaler=frame:FindFirstChild("ComicScale") or make("UIScale",frame,{Name="ComicScale"})
 scaler.Scale=scale; frame:SetAttribute("BaseScale",scale)
end
function P:Clear(list)
 for _,view in ipairs(list) do view:Clear() end
 table.clear(list)
end
function P:Menu(open)
 self.Token+=1; local token=self.Token; local ui=self.UI
 self:HideTooltip()
 self.Target=self.Target or ui.Panel.Position
 if open then
  self.Dim.Visible=true
  Tween:Create(self.Dim,TweenInfo.new(.2),{BackgroundTransparency=.42}):Play()
  ui.Panel.Position=self.Target+UDim2.fromOffset(55,8); ui.Panel.Rotation=1.2
  Tween:Create(ui.Panel,TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=self.Target,Rotation=0}):Play()
  Comic.Stagger(ui.Content)
  Audio:Play("MenuOpen")
 else
  Tween:Create(self.Dim,TweenInfo.new(.16),{BackgroundTransparency=1}):Play()
  Tween:Create(ui.Panel,TweenInfo.new(.16),{Position=self.Target+UDim2.fromOffset(70,0),Rotation=1}):Play()
  Audio:Play("MenuClose")
  task.delay(.17,function() if self.Token==token then ui:_CloseInstant(); self.Dim.Visible=false; ui.Panel.Position=self.Target end end)
 end
end
function P:Toast(value)
 if #self.Notifications>=4 then self.Notifications[1]:Destroy(); table.remove(self.Notifications,1) end
 self.NoticeSerial=(self.NoticeSerial or 0)+1
 local box=panel(self.Host,UDim2.new(),UDim2.new(1,-10,0,49),Theme.Primary); box.Rotation=-1; box.LayoutOrder=self.NoticeSerial
 local label=text(box,string.upper(tostring(value)),UDim2.fromOffset(15,5),UDim2.new(1,-30,1,-10),13); label.TextXAlignment=Enum.TextXAlignment.Center
 table.insert(self.Notifications,box); Comic.Pop(box,.85)
 task.delay(3.3,function()
  if not box.Parent then return end
  local i=table.find(self.Notifications,box); if i then table.remove(self.Notifications,i) end
  Tween:Create(box,TweenInfo.new(.15),{BackgroundTransparency=1}):Play(); task.delay(.16,function() box:Destroy() end)
 end)
end
function P:HideTooltip() if self.Tip then self.Tip:Destroy(); self.Tip=nil end end
function P:Tooltip(move)
 if not move then return end
 self:HideTooltip()
 self.Tip=panel(self.UI.Root,UDim2.new(.55,-175,.38,-90),UDim2.fromOffset(350,265),Theme.Elements[move.Type]); self.Tip.ZIndex=25; self:FitOverlay(self.Tip,350,265)
 local body=string.format("%s\n%s / %s • %s\n\n%d DAMAGE • %.1fs COOLDOWN\n%d RANGE • %.2fs STARTUP\n\n%s\n\nCOMBO TIP\n%s",move.DisplayName,move.Type,move.Category,move.Difficulty,move.Damage,move.Cooldown,move.Range,move.StartupTime,move.Description,move.ComboTip)
 text(self.Tip,body,UDim2.fromOffset(14,10),UDim2.new(1,-28,1,-20),14)
end
function P:SelectSwitch(index)
 local me=self.UI.Me
 if not me or me.Eliminated then return end
 if index==me.Active or me.Health[index]<=0 or me.Switches<=0 then self:Toast("CANNOT SWITCH • CHECK TEAM AND SWAPS"); return end
 self.UI:Send("Switch",{Index=index}); self:CloseSwitch(); Audio:Play("Switch")
end
function P:CloseSwitch()
 if self.Switch then self.Switch:Destroy(); self.Switch=nil end; self:Clear(self.SwitchViews)
end
function P:SwitchSelector()
 if self.Switch then self:CloseSwitch(); return end
 local me=self.UI.Me; if not me or me.Eliminated then return end
 self.Switch=panel(self.UI.Root,UDim2.new(.5,-335,.5,-130),UDim2.fromOffset(670,240),Theme.Secondary); self.Switch.ZIndex=15
 text(self.Switch,"CHOOSE YOUR NEXT FIGHTER  /  SWAPS LEFT: "..me.Switches,UDim2.fromOffset(18,5),UDim2.fromOffset(630,40),18,Theme.Primary)
 for i,id in ipairs(me.Team) do
  local x=15+(i-1)*218
  local card=button(self.Switch,"["..i.."] "..DB[id].Name.."\n"..me.Health[i].." HP"..(i==me.Active and " / ACTIVE" or me.Health[i]<=0 and " / DEFEATED" or ""),UDim2.fromOffset(x,55),UDim2.fromOffset(200,165),function() self:SelectSwitch(i) end)
  local view=preview(card,id,UDim2.fromOffset(110,85),UDim2.fromOffset(45,2)); table.insert(self.SwitchViews,view)
  card.TextYAlignment=Enum.TextYAlignment.Bottom; card.TextColor3=me.Health[i]>0 and Theme.Light or Theme.Muted
 end
 self:FitOverlay(self.Switch,670,240)
 Comic.Pop(self.Switch,.9)
end
function P:Match(state,me,first)
 if not me then return end
 local ui=self.UI; local id=me.Team[me.Active]
 if self.PortraitID~=id then self.PortraitID=id; self.Cooldowns={}; self.PortraitView:DisplayPokemon(self.Portrait,id); Comic.Pop(self.Health) end
 if self.LastHP and self.LastHP>me.Health[me.Active] and self.LastActive==me.Active then
  local hp=me.Health[me.Active]/100; self.HealthTrail.Size=UDim2.fromScale(self.LastHP/100,1)
  Tween:Create(self.HealthTrail,TweenInfo.new(.7,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(hp,1)}):Play(); Comic.Pop(self.Health,1.035)
 else self.HealthTrail.Size=UDim2.fromScale(me.Health[me.Active]/100,1) end
 self.LastHP=me.Health[me.Active]; self.LastActive=me.Active
 self.Status.Text="LV "..(me.Level or 1).."  "..table.concat(me.Statuses or {}," / ")
 local border=self.Health:FindFirstChild("ComicBorder")
 if border then border.Color=me.Health[me.Active]<=25 and Theme.Danger:Lerp(Theme.Warning,(math.sin(os.clock()*3)+1)/2) or Theme.Success end
 for i,card in ipairs(self.TeamCards) do
  local creature=me.Team[i]
  if card.ID~=creature then card.ID=creature; card.View:DisplayPokemon(card.Image,creature) end
  card.Label.Text=DB[creature].Name.."\n"..me.Health[i].." HP"; card.Cross.Visible=me.Health[i]<=0
  card.Image.ImageColor3=me.Health[i]>0 and Theme.Light or Theme.Muted
  local stroke=card.Frame:FindFirstChild("ComicBorder"); if stroke then stroke.Color=i==me.Active and Theme.Primary or Theme.Muted end
 end
 for i,key in ipairs(DB[id].Abilities) do
  local cd=me.Cooldowns[key] or 0
  self.AbilityBadges[i].Text=string.upper(string.sub(Moves[key].Type,1,3)); self.AbilityBadges[i].TextColor3=Theme.Elements[Moves[key].Type]
  if self.Cooldowns[i] and self.Cooldowns[i]>.05 and cd<=.05 then Comic.Pop(ui.Buttons[i],1.12); Audio:Play("AbilityReady") end
  self.Cooldowns[i]=cd
 end
 local enemy
 for _,actor in ipairs(state.Actors) do if actor.Side~=me.Side and not actor.Eliminated then enemy=actor; break end end
 self.Enemy.Visible=enemy~=nil
 if enemy then
  local eid=enemy.Team[enemy.Active]
  if self.EnemyID~=eid then self.EnemyID=eid; self.EnemyView:DisplayPokemon(self.EnemyImage,eid) end
  self.EnemyText.Text=enemy.Name.."\n"..DB[eid].Name.."  "..enemy.Health[enemy.Active].."%\n"..table.concat(enemy.Statuses or {}," / ")
 end
 self.SpectateButton.Visible=me.Eliminated
 if first then self:Intro(state); Audio:Play("MatchFound") end
 if state.Phase=="Preview" and self.IntroLabel then
  self.IntroLabel.Text="MATCH FOUND  /  "..state.Remaining
  if self.LastCount~=state.Remaining then Audio:Play("Countdown"); self.LastCount=state.Remaining end
 elseif self.Intro then self.Intro:Destroy(); self.Intro=nil; self.IntroLabel=nil; self:Clear(self.IntroViews); if state.Phase=="Battle" then self:Banner("BATTLE!",Theme.Primary,.7) end end
end
function P:Banner(value,color,duration)
 local b=panel(self.UI.Root,UDim2.new(.5,-290,.35,0),UDim2.fromOffset(580,85),color); b.ZIndex=24; b.Rotation=-4
 local label=text(b,value,UDim2.fromOffset(15,5),UDim2.new(1,-30,1,-10),38,color); label.TextXAlignment=Enum.TextXAlignment.Center
 self:FitOverlay(b,580,85); Comic.Pop(b,.8); task.delay(duration or .8,function() b:Destroy() end)
end
function P:Intro(state)
 if self.Intro then self.Intro:Destroy() end; self:Clear(self.IntroViews)
 self.Intro=panel(self.UI.Root,UDim2.new(.5,-370,.3,-30),UDim2.fromOffset(740,270),Theme.Primary); self.Intro.ZIndex=16
 self.IntroLabel=text(self.Intro,"MATCH FOUND",UDim2.fromOffset(20,5),UDim2.fromOffset(700,42),28,Theme.Primary); self.IntroLabel.TextXAlignment=Enum.TextXAlignment.Center
 text(self.Intro,"VS",UDim2.fromOffset(330,95),UDim2.fromOffset(80,50),34,Theme.Accent)
 local offsets={0,0}
 for _,actor in ipairs(state.Actors) do
  local side=actor.Side
  local ids=#state.Actors<=2 and actor.Team or {actor.Team[actor.Active]}
  for _,id in ipairs(ids) do
   local n=offsets[side]; offsets[side]+=1
   if n<3 then
    local x=(side==1 and 18 or 420)+n*100
    local v=preview(self.Intro,id,UDim2.fromOffset(90,105),UDim2.fromOffset(x,75)); table.insert(self.IntroViews,v)
    text(self.Intro,DB[id].Name,UDim2.fromOffset(x,180),UDim2.fromOffset(95,30),12)
   end
  end
 end
 self:FitOverlay(self.Intro,740,270)
 Comic.Pop(self.Intro,.88)
end
function P:Results(result)
 if self.Result then self.Result:Destroy() end; self:Clear(self.ResultViews)
 self:CloseSwitch(); self:HideTooltip(); Camera:Reset()
 local color=result.Won and Theme.Primary or Theme.Secondary
 self.Result=panel(self.UI.Root,UDim2.new(.5,-370,.5,-245),UDim2.fromOffset(740,490),color); self.Result.ZIndex=20; self.Result.Rotation=-.5
 text(self.Result,result.Draw and "HONORS EVEN" or result.Won and "VICTORY / WELL PLAYED" or "DEFEAT / NEXT ROUND",UDim2.fromOffset(25,10),UDim2.fromOffset(690,60),32,color)
 text(self.Result,"RANK PROGRESS  "..math.floor((result.MMR or 0)%300/3).."%",UDim2.fromOffset(25,300),UDim2.fromOffset(180,30),12,Theme.Muted)
 local progress=make("Frame",self.Result,{Position=UDim2.fromOffset(25,335),Size=UDim2.fromOffset(175,12),BackgroundColor3=Theme.Card,BorderSizePixel=0})
 make("Frame",progress,{Size=UDim2.fromScale(((result.MMR or 0)%300)/300,1),BackgroundColor3=color,BorderSizePixel=0})
 if (result.Rating or 0)>0 and math.floor((result.MMR or 0)/300)>math.floor(((result.MMR or 0)-result.Rating)/300) then Audio:Play("RankUp"); self:Toast("RANK UP / "..(result.Rank or "")) end
 local view=preview(self.Result,result.PokemonID or 1,UDim2.fromOffset(200,205),UDim2.fromOffset(10,80)); table.insert(self.ResultViews,view)
 text(self.Result,string.format("%+d COINS    %+d XP    %+d MMR\n%s  /  %d RATING",result.Coins or 0,result.XP or 0,result.Rating or 0,result.Rank or "",result.MMR or 0),UDim2.fromOffset(225,85),UDim2.fromOffset(485,90),20,Theme.Primary)
 local stats=result.Stats or {}; local lines={}
 for _,entry in ipairs({{"Damage Dealt","DamageDealt"},{"Damage Taken","DamageTaken"},{"Knockouts","Knockouts"},{"Assists","Assists"},{"Switches","Switches"},{"Potions Used","PotionsUsed"},{"Longest Combo","LongestCombo"}}) do table.insert(lines,entry[1].."   "..math.floor(stats[entry[2]] or 0)) end
 table.insert(lines,"Accuracy   "..math.floor((stats.Hits or 0)/math.max(1,stats.Attacks or 0)*100).."%")
 table.insert(lines,"Duration   "..(result.Duration or 0).." sec")
 text(self.Result,table.concat(lines,"\n"),UDim2.fromOffset(230,180),UDim2.fromOffset(460,260),16)
 text(self.Result,"RETURNING TO THE PLAZA SHORTLY",UDim2.fromOffset(25,440),UDim2.fromOffset(690,30),14,Theme.Muted)
 self:FitOverlay(self.Result,740,490)
 Audio:Play(result.Won and "Victory" or "Defeat"); Comic.Pop(self.Result,.85)
end
function P:Hit(data)
 local extra=data.Extra or {}; local localID=tostring(Players.LocalPlayer.UserId)
 if data.ActorID==localID then
  self.Flash.Visible=true; self.FlashStroke.Transparency=.1
  Tween:Create(self.FlashStroke,TweenInfo.new(.25),{Transparency=1}):Play()
  Camera:Shake(extra.Heavy and .28 or .1,.18); Camera:ImpactZoom(); Audio:Play("Damage",nil,.08)
 end
 if extra.AttackerID==localID then
  self.Combo.Text=tostring(extra.Combo or 1).." HIT COMBO!\n"..tostring(extra.ComboDamage or 0).." DAMAGE"
  Comic.Pop(self.Combo,1.18); Camera:Hitstop(extra.Hitstop)
  self.ComboToken=(self.ComboToken or 0)+1; local token=self.ComboToken
  task.delay(2,function() if self.ComboToken==token then self.Combo.Text="" end end)
 end
end
function P:Ultimate(data)
 if data.ActorID~=tostring(Players.LocalPlayer.UserId) then return end
 local cutin=panel(self.UI.Root,UDim2.new(.5,-320,.3,0),UDim2.fromOffset(640,115),Theme.Elements[data.Extra.Type]); cutin.Rotation=-4; cutin.ZIndex=24
 text(cutin,(DB[data.PokemonID] and string.upper(DB[data.PokemonID].Name) or "").."\n"..tostring(data.Extra.DisplayName),UDim2.fromOffset(130,10),UDim2.fromOffset(490,95),25,Theme.Primary)
 self:FitOverlay(cutin,640,115)
 local view=preview(cutin,data.PokemonID,UDim2.fromOffset(120,115),UDim2.fromOffset(0,0)); Comic.Pop(cutin,.9)
 task.delay(.7,function() view:Clear(); cutin:Destroy() end)
 Camera:UltimateCamera(); Audio:Play("AbilityReady")
end
function P:Lobby()
 self:CloseSwitch(); self:HideTooltip(); Camera:Reset()
 for _,name in ipairs({"Intro","Result"}) do if self[name] then self[name]:Destroy(); self[name]=nil end end
 self.IntroLabel=nil; self.LastHP=nil; self.Combo.Text=""; self.UI.SpectateIndex=0; self.Spectator.Text=""
 self:Clear(self.IntroViews); self:Clear(self.ResultViews)
 self.PortraitView:Clear(); self.EnemyView:Clear(); self.PortraitID=nil; self.EnemyID=nil
 for _,card in ipairs(self.TeamCards) do card.View:Clear(); card.ID=nil end
 self.Dim.Visible=false
end
return P
