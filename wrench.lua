local wnd_wrench = gui.Window("wnd_wrench", "Wrench", 250, 250, 250, 250)
local txt_target = gui.Editbox(wnd_wrench, "txt_target", "Target")

local chk_if = gui.Checkbox(wnd_wrench, "chk_if", 'Break at "If"', 1)
local chk_then = gui.Checkbox(wnd_wrench, "chk_then", 'Break at "Then"', 1)
local chk_else = gui.Checkbox(wnd_wrench, "chk_else", 'Break at "Else"', 1)
local chk_end = gui.Checkbox(wnd_wrench, "chk_end", 'Break at "End"', 1)
local chk_globals = gui.Checkbox(wnd_wrench, "chk_globals", "Dump globals", 1)

chk_if:SetPosX(135)
chk_then:SetPosX(135)
chk_else:SetPosY(73)
chk_else:SetPosX(15)
chk_end:SetPosX(15)
chk_globals:SetPosX(75)

local button_wrench = gui.Button(wnd_wrench, "Smoke 'em", function()

	local targetf = file.Open(txt_target:GetValue() .. ".lua", "r")
	local outputf = file.Open("wrench_" .. txt_target:GetValue() .. "_" .. globals.CurTime() .. ".lua", "w")
	local cache = tostring(targetf:Read())
	targetf:Close()
	if chk_if:GetValue() then
		cache = string.gsub(cache, " if", "\nif")
	end
	if chk_then:GetValue() then
		cache = string.gsub(cache, " then", "\nthen")
	end
	if chk_else:GetValue() then
		cache = string.gsub(cache, " else", "\nelse")
	end
	if chk_end:GetValue() then
		cache = string.gsub(cache, " end", "\nend")
	end
	outputf:Write(cache)

	if chk_globals:GetValue() then
		outputf:Write("\n\n--[[\n\n")
		LoadScript(txt_target:GetValue())
		for n in pairs(_G) do
			outputf:Write(n .. "\n")
		end
		UnloadScript(txt_target:GetValue())
		outputf:Write("\n\n]]")
	end
	outputf:Close()

end)

button_wrench:SetPosY(175)
button_wrench:SetPosX(60)
