local Players=game:GetService("Players")
local Shared=game.ReplicatedStorage.Shared
local DB=require(Shared.PokemonDatabase)
local Config=require(Shared.Config)
local Rules=require(Shared.Rules)
local Abilities=require(Shared.AbilityDatabase)
local Viewport=require(Shared.PokemonViewport)
local UI={Profile=nil,Match=nil,Page=nil,SelectedTeam={},Buttons={},Views={},Boards={}}
local colors={Background=Color3.fromRGB(10,17,30),Panel=Color3.fromRGB(20,32,51),Card=Color3.fromRGB(29,45,65),Text=Color3.fromRGB(229,241,251),Muted=Color3.fromRGB(147,171,194),Accent=Color3.fromRGB(69,220,213),Gold=Color3.fromRGB(255,201,99)}
local function make(class,parent,props)
 local obj=Instance.new(class)
 for k,v in pairs(props or {}) do obj[k]=v end
 obj.Parent=parent; return obj
end
local function corner(parent,r) make("UICorner",parent,{CornerRadius=UDim.new(0,r or 10)}) end
local function text(parent,value,pos,size,fontSize,color)
 return make("TextLabel",parent,{Text=value,Position=pos,Size=size,BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=fontSize or 15,TextColor3=color or colors.Text,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local function button(parent,value,pos,size,callback,color)
 local b=make("TextButton",parent,{Text=value,Position=pos,Size=size,BackgroundColor3=color or colors.Card,TextColor3=colors.Text,Font=Enum.Font.GothamBold,TextSize=14,AutoButtonColor=true,BorderSizePixel=0})
 corner(b,8); b.Activated:Connect(callback); return b
end
function UI:Send(action,payload) self.Intent:FireServer(action,payload or {}) end
function UI:ClearViews()
 for _,view in ipairs(self.Views) do view:Clear() end; self.Views={}
end
function UI:Preview(parent,id,pos,size,locked)
 local frame=make("ViewportFrame",parent,{Position=pos,Size=size,BackgroundTransparency=1,ImageColor3=locked and Color3.new(0,0,0) or Color3.new(1,1,1)})
 local view=Viewport.new(frame); view:DisplayPokemon(frame,id); table.insert(self.Views,view)
 return frame
end
function UI:Toast(value)
 self.Notice.Text=value; self.Notice.Visible=true; self.NoticeToken=(self.NoticeToken or 0)+1
 local token=self.NoticeToken
 task.delay(4,function() if token==self.NoticeToken then self.Notice.Visible=false end end)
end
function UI:Init(intent)
 self.Intent=intent
 self.Gui=make("ScreenGui",Players.LocalPlayer.PlayerGui,{Name="KantoArenaUI",ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
 self.Root=make("Frame",self.Gui,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
 local scale=make("UIScale",self.Root,{Scale=1})
 local function resize()
  local viewport=workspace.CurrentCamera.ViewportSize
  local s=math.min(1,viewport.X/1100,viewport.Y/700)
  scale.Scale=math.max(.4,s); self.Root.Size=UDim2.fromScale(1/scale.Scale,1/scale.Scale)
 end
 resize(); workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
 self.Top=make("Frame",self.Root,{Position=UDim2.fromOffset(16,10),Size=UDim2.new(1,-32,0,62),BackgroundColor3=colors.Background,BackgroundTransparency=.08,BorderSizePixel=0}); corner(self.Top)
 text(self.Top,"KANTO / ARENA",UDim2.fromOffset(18,5),UDim2.fromOffset(260,30),22,colors.Accent)
 text(self.Top,"REAL-TIME CREATURE COMBAT",UDim2.fromOffset(18,34),UDim2.fromOffset(300,18),11,colors.Muted)
 self.Stats=text(self.Top,"Connecting…",UDim2.new(.4,0,0,4),UDim2.new(.6,-15,1,-8),15)
 self.Sidebar=make("Frame",self.Root,{Position=UDim2.fromOffset(16,84),Size=UDim2.fromOffset(176,514),BackgroundColor3=colors.Background,BackgroundTransparency=.08,BorderSizePixel=0}); corner(self.Sidebar)
 local pages={"Play","Collection","Team Builder","Shop","Crates","Daily Rewards","Player Stats","Leaderboards","Training","Settings"}
 for i,page in ipairs(pages) do button(self.Sidebar,page,UDim2.fromOffset(10,10+(i-1)*48),UDim2.fromOffset(156,40),function() self:Open(page) end) end
 self.Panel=make("Frame",self.Root,{Position=UDim2.fromOffset(206,84),Size=UDim2.new(1,-222,1,-164),BackgroundColor3=colors.Background,BackgroundTransparency=.04,BorderSizePixel=0,Visible=false}); corner(self.Panel,14)
 self.Title=text(self.Panel,"",UDim2.fromOffset(22,10),UDim2.new(1,-90,0,40),25,colors.Accent)
 button(self.Panel,"×",UDim2.new(1,-50,0,10),UDim2.fromOffset(36,36),function() self:Close() end)
 self.Content=make("Frame",self.Panel,{Position=UDim2.fromOffset(20,60),Size=UDim2.new(1,-40,1,-76),BackgroundTransparency=1})
 self.Notice=text(self.Root,"",UDim2.new(.2,0,1,-72),UDim2.new(.6,0,0,50),16,colors.Gold); self.Notice.BackgroundColor3=colors.Panel; self.Notice.BackgroundTransparency=.08; self.Notice.Visible=false; self.Notice.ZIndex=20; corner(self.Notice)
 self.Notice.TextXAlignment=Enum.TextXAlignment.Center
 self.QueueLabel=text(self.Root,"Explore the plaza or choose PLAY to join a queue.",UDim2.new(.25,0,1,-38),UDim2.new(.65,0,0,25),13,colors.Muted)
 self.HUD=make("Frame",self.Root,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
 self.Timer=text(self.HUD,"",UDim2.new(.35,0,0,82),UDim2.new(.3,0,0,38),25,colors.Gold); self.Timer.TextXAlignment=Enum.TextXAlignment.Center
 self.Roster1=text(self.HUD,"",UDim2.fromOffset(18,130),UDim2.fromOffset(255,200),14)
 self.Roster2=text(self.HUD,"",UDim2.new(1,-273,0,130),UDim2.fromOffset(255,200),14); self.Roster2.TextXAlignment=Enum.TextXAlignment.Right
 self.HP=text(self.HUD,"",UDim2.new(0,20,1,-175),UDim2.fromOffset(280,35),20)
 self.HealthTrack=make("Frame",self.HUD,{Position=UDim2.new(0,20,1,-137),Size=UDim2.fromOffset(260,16),BackgroundColor3=colors.Card,BorderSizePixel=0}); corner(self.HealthTrack,5)
 self.HealthFill=make("Frame",self.HealthTrack,{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.Accent,BorderSizePixel=0}); corner(self.HealthFill,5)
 self.Bench=text(self.HUD,"",UDim2.new(0,20,1,-113),UDim2.fromOffset(280,76),13,colors.Muted)
 for i=1,4 do
  self.Buttons[i]=button(self.HUD,"["..i.."]",UDim2.new(.5,(i-2.5)*100-45,1,-100),UDim2.fromOffset(92,65),function() if self.OnAction then self.OnAction("Attack",i) end end)
  local segments={}
  for j=1,20 do
   local angle=(j-1)/20*math.pi*2
   local segment=make("Frame",self.Buttons[i],{Size=UDim2.fromOffset(3,7),Position=UDim2.new(.5,math.sin(angle)*39-1.5,.5,-math.cos(angle)*27-3.5),Rotation=math.deg(angle),BackgroundColor3=colors.Accent,BorderSizePixel=0,Visible=false})
   segments[j]=segment
  end
  self.Buttons[i]:SetAttribute("AbilityIndex",i)
  self.CooldownSegments=self.CooldownSegments or {}; self.CooldownSegments[i]=segments
 end
 local actions={{"M1", "Attack",0},{"Q Dash","Dash"},{"R Switch","Switch"},{"G Potion","Potion"},{"F Guard","Guard"}}
 for i,entry in ipairs(actions) do
  local b=button(self.HUD,entry[1],UDim2.new(1,-140,1,-110-(i-1)*48),UDim2.fromOffset(120,40),function() if self.OnAction then self.OnAction(entry[2],entry[3]) end end)
  if entry[2]=="Guard" then b.MouseButton1Up:Connect(function() self:Send("Guard",{Enabled=false}) end) end
 end
 button(self.HUD,"LEAVE MATCH",UDim2.new(1,-142,0,90),UDim2.fromOffset(122,30),function() self:Send("LeaveMatch") end)
 self.TrainingStats=text(self.HUD,"",UDim2.new(.35,0,0,125),UDim2.new(.3,0,0,80),15,colors.Accent)
 self.Reset=button(self.HUD,"RESET TRAINING",UDim2.new(.5,-85,0,205),UDim2.fromOffset(170,34),function() self:Send("TrainingReset") end); self.Reset.Visible=false
end
function UI:Close() self.Page=nil; self.Panel.Visible=false; self:ClearViews() end
function UI:ProfileChanged(p)
 self.Profile=p
 self.Stats.Text=string.format("LEVEL %d   •   %d XP   •   %s / %d MMR\n%d COINS   •   %d WINS / %d LOSSES",p.Level,p.XP,Rules.Rank(p.MMR),p.MMR,p.Coins,p.Wins,p.Losses)
 if self.Page~="Team Builder" or #self.SelectedTeam==0 then self.SelectedTeam=table.clone(p.Team) end
 if not p.Tutorial and not self.TutorialShown then self.TutorialShown=true; self:Open("Tutorial")
 elseif self.Page then self:Open(self.Page) end
end
function UI:Open(page)
 if not self.Profile then self:Toast("Waiting for your profile…"); return end
 if self.Match then return end
 self:ClearViews(); self.Content:ClearAllChildren(); self.Panel.Visible=true; self.Page=page; self.Title.Text=string.upper(page)
 local c=self.Content
 if page=="Collection" or page=="Shop" or page=="Team Builder" then self:Catalogue(page); return end
 if page=="Tutorial" then
  text(c,"WELCOME TO THE ARENA",UDim2.fromOffset(0,0),UDim2.new(1,0,0,36),22,colors.Gold)
  text(c,"1. Walk with WASD / joystick. Jump with Space.\n2. Open your 3 STARTER CRATES. Each gives a different creature.\n3. Build a team of three in TEAM BUILDER.\n4. Walk into a glowing queue circle; stay for the 10-second countdown.\n5. Aim with the camera. Click for combos; use 1–4 for abilities.\n6. Q dodges. F guards. R switches (two voluntary switches).\n7. G uses your single match potion. Damage cancels healing.\n8. Defeat all opposing creatures. Practice before Ranked!",UDim2.fromOffset(0,45),UDim2.new(1,0,0,290),17)
  button(c,"OPEN MY STARTER CRATES",UDim2.fromOffset(0,350),UDim2.fromOffset(290,46),function() self:Send("Tutorial"); self:Open("Crates") end,colors.Panel)
 elseif page=="Play" then
  text(c,"Choose a mode • walk out of a circle to cancel",UDim2.fromOffset(0,0),UDim2.new(1,0,0,30),16,colors.Muted)
  local modes={"Casual1","Ranked1","Casual2","Ranked2","Casual3","Ranked3","Practice"}
  for i,mode in ipairs(modes) do
   local cfg=Config.Modes[mode]
   button(c,cfg.Label..(cfg.Practice and "" or "  /  "..(cfg.Duration/60).." MIN"),UDim2.new((i-1)%2*.5,0,0,44+math.floor((i-1)/2)*65),UDim2.new(.48,0,0,54),function() self:Send("Queue",{Mode=mode}); self:Close() end)
  end
  button(c,"LEAVE QUEUE",UDim2.fromOffset(0,320),UDim2.fromOffset(220,44),function() self:Send("LeaveQueue") end)
 elseif page=="Training" then
  text(c,"Practice uses the same combat rules and grants no ranked rewards.",UDim2.fromOffset(0,0),UDim2.new(1,0,0,45),16,colors.Muted)
  for i,difficulty in ipairs({"Easy","Normal","Hard","Expert"}) do button(c,difficulty.." BOT",UDim2.fromOffset(0,60+(i-1)*60),UDim2.fromOffset(260,48),function() self:Send("Queue",{Mode="Practice",Difficulty=difficulty}); self:Close() end) end
  button(c,"TRAINING DUMMY + DPS HUD",UDim2.fromOffset(290,60),UDim2.fromOffset(290,48),function() self:Send("Queue",{Mode="Practice",Training=true}); self:Close() end)
 elseif page=="Crates" then
  for i,kind in ipairs({"Starter","Basic","Rare","Event"}) do
   local y=(i-1)*88
   text(c,kind.." CRATE  ×"..(self.Profile.Crates[kind] or 0),UDim2.fromOffset(0,y),UDim2.fromOffset(270,36),20)
   button(c,"OPEN",UDim2.fromOffset(280,y),UDim2.fromOffset(110,40),function() self:Send("OpenCrate",{Kind=kind}) end)
   if kind~="Starter" then button(c,"BUY • "..Config.Crates[kind].Price,UDim2.fromOffset(410,y),UDim2.fromOffset(140,40),function() self:Send("Purchase",{Kind="Crate",ID=kind}) end) end
  end
  text(c,"Starter crates never duplicate. Other duplicates award 100 coins + 10 mastery.\nBasic: 65% Common / 25% Uncommon / 9% Rare / 1% Epic\nRare: 50% Uncommon / 40% Rare / 9% Epic / 1% Legendary\nEvent: 65% Rare / 28% Epic / 6% Legendary / 1% Mythic",UDim2.fromOffset(0,355),UDim2.new(1,0,0,110),13,colors.Muted)
 elseif page=="Daily Rewards" then
  text(c,"DAILY SUPPLY DROP",UDim2.fromOffset(0,0),UDim2.new(1,0,0,50),26,colors.Gold)
  text(c,"Streak: "..self.Profile.Daily.Streak.." days\n125–275 coins per day. Rewards reset at 00:00 UTC.",UDim2.fromOffset(0,65),UDim2.new(1,0,0,100),20)
  button(c,"CLAIM REWARD",UDim2.fromOffset(0,190),UDim2.fromOffset(250,50),function() self:Send("Daily") end)
 elseif page=="Player Stats" then
  local p=self.Profile
  text(c,string.format("LEVEL %d\nXP  %d\nCOINS  %d\nRANK  %s (%d MMR)\nWINS  %d\nLOSSES  %d\nWIN STREAK  %d\nMATCHES PLAYED  %d",p.Level,p.XP,p.Coins,Rules.Rank(p.MMR),p.MMR,p.Wins,p.Losses,p.WinStreak,p.MatchesPlayed),UDim2.fromOffset(0,0),UDim2.new(1,0,0,350),22)
 elseif page=="Leaderboards" then
  for i,key in ipairs({"MMR","Wins","BestWinStreak"}) do
   local lines={string.upper(key)}
   for rank,entry in ipairs(self.Boards[key] or {}) do table.insert(lines,rank..". "..entry.Name.."  "..entry.Value) end
   if #lines==1 then table.insert(lines,"No published scores yet") end
   text(c,table.concat(lines,"\n"),UDim2.new((i-1)/3,0,0,0),UDim2.new(.32,0,1,0),16)
  end
 elseif page=="Settings" then
  for i,key in ipairs({"Music","Effects","ShiftLock"}) do
   button(c,key..": "..(self.Profile.Settings[key] and "ON" or "OFF"),UDim2.fromOffset(0,(i-1)*65),UDim2.fromOffset(300,48),function() self:Send("Setting",{Key=key,Value=not self.Profile.Settings[key]}) end)
  end
  text(c,"Audio slots are ready for your licensed music and sound assets.\nShift lock keeps the pointer centered while in combat.",UDim2.fromOffset(0,220),UDim2.new(1,0,0,80),15,colors.Muted)
 end
end
function UI:Catalogue(page)
 local c=self.Content; local query=self.Query or ""; local filter=self.Filter or "All"
 local search=make("TextBox",c,{Position=UDim2.fromOffset(0,0),Size=UDim2.new(.62,0,0,36),BackgroundColor3=colors.Card,TextColor3=colors.Text,PlaceholderText="Search name, #, type, role, rarity",Text=query,ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=14,BorderSizePixel=0}); corner(search)
 local filters={"All","Owned","Not Owned","Favorites","Common","Uncommon","Rare","Epic","Legendary","Mythic","Brawler","Speedster","Tank","Controller","Ranged","Support","Assassin"}
 button(c,filter,UDim2.new(.64,0,0,0),UDim2.new(.35,0,0,36),function()
  local index=table.find(filters,filter) or 1; self.Filter=filters[index%#filters+1]; self:Open(page)
 end)
 local top=48
 if page=="Team Builder" then
  local labels={}
  for i=1,3 do labels[i]=self.SelectedTeam[i] and DB[self.SelectedTeam[i]].Name or "Empty" end
  text(c,"YOUR TEAM: "..table.concat(labels," / "),UDim2.fromOffset(0,44),UDim2.new(.7,0,0,36),14,colors.Gold)
  button(c,"SAVE TEAM",UDim2.new(.75,0,0,44),UDim2.new(.24,0,0,36),function() self:Send("Team",{Team=self.SelectedTeam}) end)
  top=92
 end
 local scroll=make("ScrollingFrame",c,{Position=UDim2.fromOffset(0,top),Size=UDim2.new(1,0,1,-top),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
 make("UIGridLayout",scroll,{CellSize=UDim2.fromOffset(160,205),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder})
 local function populate()
  for _,child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
  self:ClearViews()
  for id,entry in ipairs(DB) do
   local owned=self.Profile.Owned[tostring(id)]~=nil
   local visible=Rules.Search(entry,search.Text)
   if filter=="Owned" then visible=visible and owned elseif filter=="Not Owned" then visible=visible and not owned elseif filter=="Favorites" then visible=visible and self.Profile.Favorites[tostring(id)]==true elseif filter~="All" then visible=visible and (entry.Rarity==filter or entry.Role==filter) end
   if page=="Team Builder" then visible=visible and owned end
   if visible then
    local card=make("Frame",scroll,{BackgroundColor3=colors.Card,BorderSizePixel=0,LayoutOrder=id}); corner(card)
    local iconRoot=game.ReplicatedStorage.Pokemon.Icons:FindFirstChild(entry.FolderName)
    local icon=iconRoot and iconRoot:FindFirstChild("Icon")
    if icon and icon.Value~="" then make("ImageLabel",card,{Position=UDim2.fromOffset(10,25),Size=UDim2.fromOffset(140,105),BackgroundTransparency=1,Image=icon.Value,ImageColor3=owned and Color3.new(1,1,1) or Color3.new(0,0,0)})
    else self:Preview(card,id,UDim2.fromOffset(10,25),UDim2.fromOffset(140,105),page~="Shop" and not owned) end
    text(card,string.format("#%03d  %s",id,owned and "OWNED" or "LOCKED"),UDim2.fromOffset(10,4),UDim2.fromOffset(140,20),11,colors.Muted)
    text(card,entry.Name,UDim2.fromOffset(10,128),UDim2.fromOffset(145,24),16)
    text(card,entry.Rarity.." • "..entry.Type1,UDim2.fromOffset(10,152),UDim2.fromOffset(145,22),11,Config.RarityColors[entry.Rarity])
    button(card,page=="Team Builder" and (table.find(self.SelectedTeam,id) and "REMOVE" or "ADD") or "VIEW",UDim2.fromOffset(8,178),UDim2.fromOffset(144,23),function()
     if page=="Team Builder" then
      local found=table.find(self.SelectedTeam,id)
      if found then table.remove(self.SelectedTeam,found) elseif #self.SelectedTeam<3 then table.insert(self.SelectedTeam,id) else self:Toast("Remove a creature before adding another") end
      self:Open(page)
     else self:Detail(id,page) end
    end)
   end
  end
 end
 populate()
 search:GetPropertyChangedSignal("Text"):Connect(function() self.Query=search.Text; populate() end)
end
function UI:Detail(id,back)
 self:ClearViews(); self.Content:ClearAllChildren()
 local data=DB[id]; local c=self.Content; local owned=self.Profile.Owned[tostring(id)]
 self.Title.Text=string.format("#%03d / %s",id,string.upper(data.Name))
 self:Preview(c,id,UDim2.fromOffset(0,0),UDim2.new(.42,0,0,270),false)
 text(c,data.Rarity.." • "..data.Type1..(data.Type2 and " / "..data.Type2 or "").."\n"..data.Role.." • Difficulty "..data.Difficulty.."\n\n"..data.Description.."\n\n100 HP • "..data.Stats.WalkSpeed.." Speed\n"..(owned and "Level "..owned.Level.." • Mastery "..owned.Mastery or "Not owned"),UDim2.new(.45,0,0,0),UDim2.new(.55,0,0,220),16)
 for i,key in ipairs(data.Abilities) do
  local a=Abilities[key]
  text(c,"["..i.."] "..a.Name.." • "..a.Damage.." damage • "..a.Cooldown.."s cooldown • "..a.Kind,UDim2.fromOffset(0,275+(i-1)*30),UDim2.new(1,0,0,27),14,colors.Muted)
 end
 button(c,"BACK",UDim2.fromOffset(0,410),UDim2.fromOffset(120,40),function() self:Open(back) end)
 button(c,self.Profile.Favorites[tostring(id)] and "UNFAVORITE" or "FAVORITE",UDim2.fromOffset(135,410),UDim2.fromOffset(160,40),function() self:Send("Favorite",{ID=id}) end)
 if not owned then button(c,"BUY • "..data.Price,UDim2.fromOffset(310,410),UDim2.fromOffset(170,40),function() self:Send("Purchase",{Kind="Creature",ID=id}) end) end
end
function UI:Reveal(reward)
 self:Open("Crates"); self:ClearViews(); self.Content:ClearAllChildren()
 local entry=DB[reward.ID]; local c=self.Content
 local label=text(c,"DECODING CRATE…",UDim2.fromOffset(0,0),UDim2.new(1,0,0,45),28,Config.RarityColors[entry.Rarity]); label.TextXAlignment=Enum.TextXAlignment.Center
 local preview=self:Preview(c,reward.ID,UDim2.new(.15,0,0,55),UDim2.new(.7,0,0,280),true)
 local token={}; self.RevealToken=token
 task.delay(1.2,function()
  if self.RevealToken~=token or not label.Parent then return end
  preview.ImageColor3=Color3.new(1,1,1)
  label.Text=entry.Name.." • "..entry.Rarity
  text(c,reward.New and "NEW CREATURE UNLOCKED" or "DUPLICATE • +100 COINS / +10 MASTERY",UDim2.fromOffset(0,340),UDim2.new(1,0,0,35),20,colors.Gold)
  button(c,"CONTINUE",UDim2.new(.5,-110,0,395),UDim2.fromOffset(220,45),function() self:Open("Crates") end)
 end)
end
function UI:UpdateMatch(state)
 local first=not self.Match; self.Match=state
 if first then self:Close(); self.Sidebar.Visible=false; self.QueueLabel.Visible=false; self.HUD.Visible=true end
 local me
 local rosters={{},{}}
 for _,actor in ipairs(state.Actors) do
  if actor.ID==tostring(Players.LocalPlayer.UserId) then me=actor end
  local living=0; for _,hp in ipairs(actor.Health) do if hp>0 then living+=1 end end
  table.insert(rosters[actor.Side],actor.Name.." • "..living.."/3 • "..actor.Health[actor.Active].." HP"..(actor.Eliminated and " [OUT]" or ""))
 end
 self.Roster1.Text=table.concat(rosters[1],"\n"); self.Roster2.Text=table.concat(rosters[2],"\n")
 self.Timer.Text=state.Phase.."  "..string.format("%d:%02d",math.floor(state.Remaining/60),state.Remaining%60)..(state.SuddenDeath and " • SUDDEN DEATH" or "")
 self.Reset.Visible=state.Training==true
 if me then
  self.Me=me
  local entry=DB[me.Team[me.Active]]
  self.HP.Text=entry.Name.."  "..me.Health[me.Active].." / 100"
  self.HealthFill.Size=UDim2.fromScale(me.Health[me.Active]/100,1)
  local lines={"Switches: "..me.Switches.." • Potion: "..me.Potions.." • Stamina: "..math.floor(me.Stamina)}
  for i,id in ipairs(me.Team) do if i~=me.Active then table.insert(lines,"[R] "..DB[id].Name.." • "..me.Health[i].." HP"..(me.Health[i]<=0 and " • DEFEATED" or "")) end end
  self.Bench.Text=table.concat(lines,"\n")
  for i,key in ipairs(entry.Abilities) do
   local cd=me.Cooldowns[key] or 0
   self.Buttons[i].Text="["..i.."] "..Abilities[key].Name.."\n"..(cd>.05 and string.format("%.1fs",cd) or "READY")
   self.Buttons[i].BackgroundColor3=cd>.05 and colors.Panel or colors.Card
   for j,segment in ipairs(self.CooldownSegments[i]) do segment.Visible=j/20<=cd/Abilities[key].Cooldown end
  end
 end
end
function UI:Lobby()
 self.Match=nil; self.Me=nil; self.HUD.Visible=false; self.Sidebar.Visible=true; self.QueueLabel.Visible=true
 self.QueueLabel.Text="Explore the plaza or choose PLAY to join a queue."
end
function UI:Queue(state)
 if state.Mode=="" then self.QueueLabel.Text="Queue left. Explore the plaza."; return end
 self.QueueLabel.Text=Config.Modes[state.Mode].Label.." • "..state.Count.."/"..state.Needed..(state.Countdown and " • STARTING IN "..state.Countdown or " • Waiting for players").." • Walk away to leave"
end
return UI
