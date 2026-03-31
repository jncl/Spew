
local _, ns = ...
local _G = _G

local TABLEITEMS, TABLEDEPTH = 5, 1

local panel = ns.tekPanelAuction("SpewPanel", "Spew")
local cf = _G.CreateFrame("ScrollingMessageFrame", nil, panel)
cf:SetPoint("TOPLEFT", 25, -75)
cf:SetPoint("BOTTOMRIGHT", -15, 40)
cf:SetMaxLines(1000)
cf:SetFontObject(_G.ChatFontSmall)
cf:SetJustifyH("LEFT")
cf:SetFading(false)
cf:EnableMouseWheel(true)
cf:SetScript("OnHide", cf.ScrollToBottom)
cf:SetScript("OnMouseWheel", function(frame, delta)
	if delta > 0 then
		if _G.IsShiftKeyDown() then frame:ScrollToTop()
		else for _= 1, 4 do frame:ScrollUp() end end
	elseif delta < 0 then
		if _G.IsShiftKeyDown() then frame:ScrollToBottom()
		else for _ = 1, 4 do frame:ScrollDown() end end
	end
end)

local TableToString
local tKb = _G.LibStub("tekKonfig-Button").new(cf, "TOPRIGHT", cf, "BOTTOMRIGHT", -155, -3)
tKb:SetText("Clear")
tKb:SetScript("OnClick", function() cf:Clear() end)

local function Print(text, frame)
	if not text or text:len() == 0 then text = " " end
	(frame or cf):AddMessage(text)
end

local colors = {boolean = "|cffff9100", number = "|cffff7fff", ["nil"] = "|cffff7f7f"}
local noescape = {["\a"] = "a", ["\b"] = "b", ["\f"] = "f", ["\n"] = "n", ["\r"] = "r", ["\t"] = "t", ["\v"] = "v"}
local function escape(c) return "\\".. (noescape[c] or c:byte()) end
local function pretty_tostring(value, depth)
	depth = depth or 0
	local t = _G.type(value)
	if t == "string" then return '|cff00ff00"' .. value:gsub("|", "||"):gsub("([\001-\031\128-\255])", escape) .. '"|r'
	elseif t == "table" then
		if depth > TABLEDEPTH then return "|cff9f9f9f{...}|r"
		elseif _G.type(_G.rawget(value, 0)) == "userdata" and _G.type(value.GetObjectType) == "function" then return "|cffffea00<"..value:GetObjectType() .. ":" .. (value:GetName() or "(anon)") .. ">|r"
		else return "|cff9f9f9f" .. _G.string.join(", ", TableToString(value, nil, nil, depth+1)) .. "|r" end
	elseif colors[t] then return colors[t] .. _G.tostring(value) .. "|r"
	else return _G.tostring(value) end
end

function TableToString(t, lasti, items, depth)
	items = items or 0
	depth = depth or 0
	if items > TABLEITEMS then return "...|cff9f9f9f}|r" end
	local i,v = _G.next(t, lasti)
	if items == 0 then
		if _G.next(t, i) then return "|cff9f9f9f{|cff7fd5ff" .. _G.tostring(i).."|r = "..pretty_tostring(v, depth), TableToString(t, i, 1, depth)
		elseif v == nil then return "|cff9f9f9f{}|r"
		else return "|cff9f9f9f{|cff7fd5ff" .. _G.tostring(i) .. "|r = " .. pretty_tostring(v, depth) .. "|cff9f9f9f}|r" end
	end
	if _G.next(t, i) then return "|cff7fd5ff" .. _G.tostring(i) .. "|r = " .. pretty_tostring(v, depth), TableToString(t, i, items+1, depth) end
	return "|cff7fd5ff" .. _G.tostring(i).."|r = " .. pretty_tostring(v, depth) .. "|cff9f9f9f}|r"
end

local function ArgsToString(a1, ...)
	if _G.select('#', ...) < 1 then return pretty_tostring(a1)
	else return pretty_tostring(a1), ArgsToString(...) end
end

local blist = {GetDisabledFontObject = true, GetHighlightFontObject = true, GetNormalFontObject = true}
local function downcasesort(a,b)
	local ta, tb = _G.type(a), _G.type(b)
	if ta == "number" and tb ~= "number" then return true end
	if ta ~= "number" and tb == "number" then return false end
	if ta == "number" and tb == "number" then return a < b end
	return a and b and _G.tostring(a):lower() < _G.tostring(b):lower()
end
local function pcallhelper(success, ...)
	if success then
		return _G.string.join(", ", ArgsToString(...))
	end
end

local oName
local function SpewIt(input, a1, ...)
	if _G.select('#', ...) == 0 then
		if _G.type(a1) == "table" then
			if _G.type(_G.rawget(a1, 0)) == "userdata" and _G.type(a1.GetObjectType) == "function" then
				-- We've got a frame!
				-- TODO: handle concatenation of table error ?
				Print("|cffffea00<" .. a1:GetObjectType() .. ":" .. (a1:GetName() or input .. "(anon)") .. "|r")
				-- handle concatenation of table error
				oName = a1:GetName()
				if _G.type(oName) == "table" then
					oName = oName:GetText()
				end
				Print("|cffffea00<" .. a1:GetObjectType() .. ":" .. (oName or input .. "(anon)") .. "|r")
				local sorttable = {}
				for i in _G.pairs(a1) do
					_G.table.insert(sorttable, i)
				end
				if _G.type(_G.getmetatable(a1).__index) == "table" then
					for i in _G.pairs(_G.getmetatable(a1).__index) do
						_G.table.insert(sorttable, i)
					end
				end
				_G.table.sort(sorttable, downcasesort)
				for _,i in _G.ipairs(sorttable) do
					local v, output = a1[i]
					if _G.type(v) == "function"
					and _G.type(i) == "string"
					and not blist[i]
					and (i:find("^Is")
					or i:find("^Can")
					or i:find("^Get"))
					then
						output = pcallhelper(_G.pcall(v, a1))
					end
					if output then
						Print("    |cff7fd5ff" .. _G.tostring(i) .. "|r => " .. output)
					else
						Print("    |cff7fd5ff" .. _G.tostring(i) .. "|r = " .. pretty_tostring(v))
					end
				end
				Print("|cffffea00>|r")
				_G.ShowUIPanel(panel)
			else
				-- Normal table
				Print("|cff9f9f9f{  -- " .. input .. "|r")
				local sorttable = {}
				for i in _G.pairs(a1) do
					_G.table.insert(sorttable, i)
				end
				_G.table.sort(sorttable, downcasesort)
				for _,i in _G.ipairs(sorttable) do
					Print("    |cff7fd5ff" .. _G.tostring(i) .. "|r = " .. pretty_tostring(a1[i], 1))
				end
				Print("|cff9f9f9f}  -- " .. input .. "|r")
				_G.ShowUIPanel(panel)
			end
		else Print("|cff999999" .. input .. "|r => " .. pretty_tostring(a1), _G.DEFAULT_CHAT_FRAME) end
	else
		Print("|cff999999" .. input .. "|r => " .. _G.string.join(", ", ArgsToString(a1, ...)), _G.DEFAULT_CHAT_FRAME)
	end
end

_G["Spew"] = SpewIt

_G.SLASH_SPEW1 = "/spew"
function _G.SlashCmdList.SPEW(text)
	local input = text:trim():match("^(.-);*$")
	if input == "" then _G.ShowUIPanel(panel)
	elseif input == "mouse" then
		local t, f = {}, _G.EnumerateFrames()
		local SpewMouse = {}
		while f do
			if f:IsVisible() and _G.MouseIsOver(f) then
				_G.table.insert(SpewMouse, f)
				_G.table.insert(t, f:GetName() or "<Anon>")
			end
			f = _G.EnumerateFrames(f)
		end
		SpewIt("Visible frames under mouse (stored in table `SpewMouse`", t)
	else
		local f, err = _G.loadstring(_G.string.format("Spew(%q, %s)", input, input))
		if f then f() else Print("|cffff0000Error:|r " .. err) end
	end
end


--[[
-- Testing code to help find crashes
TEKX = TEKX or 0
local blist, input = {GetDisabledFontObject = true, GetHighlightFontObject = true, GetNormalFontObject = true}
local function downcasesort(a,b) return a and b and tostring(a):lower() < tostring(b):lower() end
local a1=PlayerFrame
local sorttable = {}
for i in pairs(a1) do table.insert(sorttable, i) end
for i in pairs(getmetatable(a1).__index) do table.insert(sorttable, i) end
table.sort(sorttable, downcasesort)
for j,i in ipairs(sorttable) do
        local v, output = a1[i]
        if j > TEKX and type(v) == "function" and type(i) == "string" and not blist[i] and i:find("^Get") then
TEKX = j
ChatFrame1:AddMessage("Testing "..TEKX.." - "..i)
                output = pcall(v, a1)
return
        end
end
ChatFrame1:AddMessage("Done testing")
]]
