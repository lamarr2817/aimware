local tab_vmchange = gui.Tab(gui.Reference("Visuals"), "tab_vmchange", "Viewmodel")
local var_vmchange_righthand = gui.Checkbox(tab_vmchange, "var_vmchange_righthand", "Left Hand", 0)
local var_vmchange_x = gui.Slider( tab_vmchange, "var_vmchange_x", "X", 0, -50, 50)
local var_vmchange_y = gui.Slider( tab_vmchange, "var_vmchange_y", "Y", 0, -50, 50)
local var_vmchange_z = gui.Slider( tab_vmchange, "var_vmchange_z", "Z", 0, -50, 50)

var_vmchange_x:SetDescription("Left to Right")
var_vmchange_y:SetDescription("Forward and Back (FOV)")
var_vmchange_z:SetDescription("Up and Down")

local vmdefs = {
client.GetConVar("cl_righthand"),
client.GetConVar("viewmodel_offset_x"),
client.GetConVar("viewmodel_offset_y"),
client.GetConVar("viewmodel_offset_z")
}

callbacks.Register( "Draw", function()

	if var_vmchange_righthand:GetValue() then
		client.SetConVar("cl_righthand", "0", true)
	else
		client.SetConVar("cl_righthand", "1", true)
	end
	
	client.SetConVar("viewmodel_offset_x", var_vmchange_x:GetValue(), true)
	client.SetConVar("viewmodel_offset_y", var_vmchange_y:GetValue(), true)
	client.SetConVar("viewmodel_offset_z", var_vmchange_z:GetValue(), true)

end)

callbacks.Register("Unload", function()
	client.SetConVar("cl_righthand", vmdefs[1], true)
	client.SetConVar("viewmodel_offset_x", vmdefs[2], true)
	client.SetConVar("viewmodel_offset_y", vmdefs[3], true)
	client.SetConVar("viewmodel_offset_z", vmdefs[4], true)
end)
