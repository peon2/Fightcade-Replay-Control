local SAVESTATE_INTERVAL = 60 -- frames between each state being saved
local REWIND_KEY = "V"
local FORWARD_KEY = "B"
local PAUSE_KEY = "N"
local P1_CONTROL_KEY = "M"


local fc -- framecount according to game
local relfc = emu.framecount() -- relative fc according to inputs table, what frame the game SHOULD be at

local earliestfc = relfc -- the earliest frame we've seen
local latestfc = relfc -- the latest frame we've seen

local sstable = {} -- savestate table

local kb = {}
local kbprev = {}
local inputs = {}

local clearinputs = {} -- table of dud inputs
for i,_ in pairs(joypad.get()) do clearinputs[i] = false end

local pausetoggle = false
local pause = savestate.create("pause")

local p1toggle = false -- if p1 is taking control
local p1inputsset = false -- if p1 is already set up
local p1inputs = joypad.get() -- table of player one's inputs

for i, _ in pairs(p1inputs) do
	if (i:sub(1,2)~="P1") then 
		p1inputs[i] = nil 
	else
		p1inputs[i] = false
	end
end

local readInputs = function() -- gets the inputs supplied this frame
	
	inputs[relfc] = {}
	for i,v in pairs(joypad.get()) do
		inputs[relfc][i] = v
	end

	kb = input.get()
end

local nextinput -- next input to be set for p1

local isBound = function(t, k)
	for _, v in pairs(t) do
		if (v==k) then return true end
	end
	return false
end

local setP1Inputs = function()

	if (p1inputsset==true) then return end -- nothing to do here

	p1inputsset=true
	for _, v in pairs(p1inputs) do -- check if p1 is done
		if (v==false) then p1inputsset = false end
	end

	gui.text(1,40,"Set P1 inputs:")

	if (nextinput == nil) then
		for i, v in pairs(p1inputs) do
			if v==false then
				nextinput = i
			end
		end
	else
		local ycount = 50
		for i, v in pairs(p1inputs) do
			if v~=false then
				gui.text(1,ycount,"Input for "..i..": "..v)
				ycount=ycount+8
			end
		end
		gui.text(1,ycount+2,"Input for "..nextinput.."?","yellow")
		for i, _ in pairs(kb) do
			if (i~="xmouse" and i~="ymouse" and i~="leftclick" and i~="rightclick" and i~="middleclick") then -- some inputs we dont want
				if (i~=REWIND_KEY and i~=FORWARD_KEY and i~=PAUSE_KEY and i~=P1_CONTROL_KEY and not isBound(p1inputs, i)) then -- these can't be bound
					p1inputs[nextinput] = i
					nextinput = nil
				else
					gui.text(1,60,i.." is already bound.")
				end
			end
		end
	end
end

local inputParse = function()
	
	joypad.set(clearinputs) -- common case
	
	if (fc%SAVESTATE_INTERVAL==0 and sstable[fc]==nil) then -- we've reached another multiple of the interval, save a state
		sstable[fc] = savestate.create(fc)
		savestate.save(sstable[fc])
	end
	
	if (fc>latestfc) then latestfc=fc end -- update latestfc
	
	gui.text(1,10,"Current frame: ".. fc)
	gui.text(1,20,"Distance from replay: ".. relfc-fc)
	gui.text(1,30,"Savestate slot \("..math.floor((fc-earliestfc)/SAVESTATE_INTERVAL).."/"..math.floor((latestfc-earliestfc)/SAVESTATE_INTERVAL).."\)")
	
	if (kb[REWIND_KEY] and not kbprev[REWIND_KEY]) then -- don't run this again until the user has lifted their finger
		--load the last savestate saved
		local newfc = fc-(fc%SAVESTATE_INTERVAL)
		if (fc-newfc <= 10) then -- if theres a small difference we should load the state before this, otherwise we're locked to one state
			newfc=newfc-SAVESTATE_INTERVAL
		end
		if (sstable[newfc]) then -- if this savestate exists
			savestate.load(sstable[newfc]) -- load
			if (pausetoggle==true) then savestate.save(pause) end
		else
			gui.text(50,50,"Can't go any further backwards", "red")
			kb[REWIND_KEY]=nil -- allows the button to be held
		end
	end
	
	if (kb[FORWARD_KEY] and not kbprev[FORWARD_KEY]) then -- don't run this again until the user has lifted their finger
		--load the next savestate saved
		local newfc = fc+SAVESTATE_INTERVAL-(fc%SAVESTATE_INTERVAL)
		
		if (sstable[newfc]) then -- if this savestate exists
			savestate.load(sstable[newfc]) -- load
			if (pausetoggle==true) then savestate.save(pause) end
		else
			gui.text(50,50,"Can't go any farther forwards", "red")
			kb[FORWARD_KEY]=nil -- allows the button to be held
		end
	end
	
	if (kb[PAUSE_KEY] and not kbprev[PAUSE_KEY]) then
		pausetoggle = not pausetoggle
		if (pausetoggle==true) then savestate.save(pause) end
	end
	
	if (kb[P1_CONTROL_KEY] and not kbprev[P1_CONTROL_KEY]) then
		p1toggle = not p1toggle
	end
	
	if (pausetoggle==true) then savestate.load(pause) end
	
	joypad.set(inputs[fc])
end

local setInputs = function()
	if (not p1inputsset or not p1toggle) then return end -- nothing to do here
	local newinputs = {}
	
	for i, v in pairs(inputs[fc]) do
		newinputs[i] = v
	end
	
	for i, v in pairs(p1inputs) do
		if (kb[v]) then 
			newinputs[i] = true
		else
			newinputs[i] = false
		end
	end
	
	joypad.set(newinputs)
end

emu.registerbefore(function ()
		fc = emu.framecount()
		relfc = relfc+1
		readInputs()
		setP1Inputs()
		inputParse()
		setInputs()
	end)
	
emu.registerafter(function ()
		kbprev = {}
		for i, v in pairs(kb) do
			kbprev[i] = v
		end
	end)
	
emu.registerexit(function() -- remove all the savestates
		for i,_ in pairs(sstable) do
			os.remove(i)
		end
		os.remove("pause")
	end)
