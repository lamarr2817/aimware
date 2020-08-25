local meta = {
    version = "1",
    name = "Armada",
    git_source = "https://raw.githubusercontent.com/lamarr2817/meta/master/base",
    git_version = "https://raw.githubusercontent.com/lamarr2817/meta/master/version"
}

local viewangles = {
    camera,
    real,
    lby,
    desync
}
local gcache = {
    doubletapping = false,
    shot = false
}

local tab = gui.Tab(gui.Reference("Ragebot"), string.lower(meta.name) .. ".tab", meta.name)
local versiontext = gui.Text(tab, meta.version)
versiontext:SetPosY(500)
versiontext:SetPosX(595)
local gbox = gui.Groupbox(tab, "Anti-Aim", 16, 16, 296, 5)
local gbox_extra = gui.Groupbox(tab, "Ragebot", 328, 16, 296, 5)
local gui_enable = gui.Checkbox(gbox, "lua.armada.enable", "Enable Armada", 1)

local gui_armada_aa = gui.Checkbox(gbox, "lua.armada.lby", "Force Live LBY", 0)
gui_armada_aa:SetDescription("Updates your LBY more frequently.")
local gui_armada_aa_delay = gui.Slider(gbox, "lua.armada.lby.delay", "Force Live Delay", 9, 4, 12)
gui_armada_aa_delay:SetDescription("Delay between LBY updates.")

local gui_armada_aa_bridge = gui.Checkbox(gbox, "lua.armada.bridge", "LBY Bridge", 0)
gui_armada_aa_bridge:SetDescription("Changes your LBY before and after updating.")
local gui_armada_aa_bridge_base = gui.Combobox(gbox, "lua.armada.bridge.base", "LBY Bridge Base", "Current", "Desync", "Real", "Localview")
local gui_armada_aa_bridge_type = gui.Combobox(gbox, "lua.armada.bridge.type", "LBY Bridge Modifier", "Add", "Subtract", "Invert", "Sway")
local gui_armada_aa_bridge_amount = gui.Slider(gbox, "lua.armada.bridge.amount", "LBY Bridge Amount", 0, 0, 180)
gui_armada_aa_bridge_amount:SetDescription("Also controls sway range.")

local gui_armada_rbot_doubletap = gui.Checkbox(gbox_extra, "armada_rbot_doubletap", "Double-Tap", 0)
gui_armada_rbot_doubletap:SetDescription("Increases double-tap speed [Beta]")

local gui_armada_shotswitch = gui.Checkbox(gbox_extra, "lua.armada.shotswitch", "Switch Desync On Shot", 0)

local gui_armada_slowjitter = gui.Checkbox(gbox_extra, "lua.armada.slowwalk", "Jitter Slowwalk Speed", 0)
local gui_armada_slowjitter_min = gui.Slider(gbox_extra, "lua.armada.slowwalk.min", "Minimum Slowwalk Speed", 15, 0, 100)
local gui_armada_slowjitter_max = gui.Slider(gbox_extra, "lua.armada.slowwalk.max", "Max Slowwalk Speed", 65, 0, 100)

local function switch(var)
    if var == 1 then
        return 2
    else
        return 1
    end
end

local function log(text, err)
    if err then
        print("[ARMADA] [ERROR] " .. text)
    else
        print("[ARMADA] " .. text)
    end
end

local function update()
    if tonumber(http.Get(meta.git_version)) > meta.version then
        log("New version found. Update started.")
        local current_script = file.Open(GetScriptName(), "w")
        current_script:Write(http.Get(meta.git_source))
        current_script:Close()
        gui.Command("lua.run " .. GetScriptName())
    else
        log("Script is up-to-date.")
    end
end

update()

local function bridge()
local base = gui_armada_aa_bridge_base:GetValue()
local type = gui_armada_aa_bridge_type:GetValue()
local amount = gui_armada_aa_bridge_amount:GetValue()
local cache_bridge = {a, b }

    if base == 0 then
        cache_bridge.b = viewangles.lby
    elseif base == 1 then
        cache_bridge.b = viewangles.desync
    elseif base == 2 then
        cache_bridge.b = viewangles.real
    elseif base == 3 then
        cache_bridge.b = viewangles.camera
    end

    if type == 0 then
        cache_bridge.a = amount
    elseif type == 1 then
        cache_bridge.a = -amount
    elseif type == 2 then
        cache_bridge.a = -(cache_bridge.b * 2)
    elseif type == 3 then
        cache_bridge.a = math.cos((globals.RealTime() * 2)) * amount
    end

    return (cache_bridge.b + cache_bridge.a)
end

callbacks.Register("Draw", function()
    gui_armada_aa_delay:SetInvisible(not gui_armada_aa:GetValue())
    gui_armada_aa_bridge:SetInvisible(not gui_armada_aa:GetValue())
    gui_armada_aa_bridge_type:SetInvisible(not gui_armada_aa_bridge:GetValue() or not gui_armada_aa:GetValue())
    gui_armada_aa_bridge_amount:SetInvisible(not gui_armada_aa_bridge:GetValue() or not gui_armada_aa:GetValue())
    gui_armada_aa_bridge_base:SetInvisible(not gui_armada_aa_bridge:GetValue() or not gui_armada_aa:GetValue())
    if gcache.shot then
        gui.SetValue("rbot.antiaim.fakeyawstyle", switch(gui.GetValue("rbot.antiaim.fakeyawstyle")))
        gcache.shot = false
    end
    if gui_armada_slowjitter:GetValue() then
        if input.IsButtonDown(gui.GetValue("rbot.accuracy.movement.slowkey")) and (globals.TickCount() % 9 == 0) then
            gui.SetValue("rbot.accuracy.movement.slowspeed", math.random(gui_armada_slowjitter_min:GetValue(), gui_armada_slowjitter_max:GetValue()))
        end
    end
end)

callbacks.Register("CreateMove", function(cmd)
    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() or not gui_enable:GetValue() then return end
    --\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    if cmd.sendpacket then
        viewangles.desync = viewangles.real
    else
        viewangles.real = cmd.viewangles.y
    end
    viewangles.camera = entities.GetLocalPlayer():GetProp("m_angEyeAngles[1]")
    viewangles.lby = entities.GetLocalPlayer():GetProp("m_flLowerBodyYawTarget")
    --///////////////////////////////////////////////////////////////////////////////////
    if gui_armada_aa:GetValue() then
        if (globals.TickCount() % gui_armada_aa_delay:GetValue() == 0) and not gcache.doubletapping then
            cmd.forwardmove = 1.01
        elseif gui_armada_aa_bridge:GetValue() and not gcache.doubletapping then
            lp:SetProp("m_flLowerBodyYawTarget", bridge())
        else
        end
    end
    --\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    if gui_armada_rbot_doubletap:GetValue() then
        if gcache.doubletapping then
            cmd.sidemove = 0
            cmd.forwardmove = 0
            gcache.doubletapping = false
        end
    end
    --///////////////////////////////////////////////////////////////////////////////////
end )

callbacks.Register("FireGameEvent", function(event)

    if ( event:GetName() == 'weapon_fire' ) then

        local lp = client.GetLocalPlayerIndex()
        local int_shooter = event:GetInt('userid')
        local index_shooter = client.GetPlayerIndexByUserID(int_shooter)

        if ( index_shooter == lp) then
            if gui_armada_rbot_doubletap:GetValue() then
                gcache.doubletapping = true
            end
            if gui_armada_shotswitch:GetValue() then
                gcache.shot = true
            end
        end
    end
end)

client.AllowListener( 'weapon_fire' )
