local bDtap, fPlayerRealAngle, fPlayerDesyncAngle, fDesyncAmount, fRawDesyncAmount, fAlpha = 1, 1, 1, 1, 1, 1; -- this looks bad but fixes an annoying console message
local debug = false; -- enabling this really just spams your console
local gui_window_indicators = gui.Window("nomad.window.indicators", "", 5, 425, 135, 150) -- i maybe could put these in a table but i've had problems with them in the past and it's at the top of the code so no reason
local gui_tab = gui.Tab(gui.Reference("Ragebot"), "nomad.tab", "Nomad")
local gui_gbox_aa = gui.Groupbox(gui_tab, "Anti-Aim", 16, 16, 296, 5) -- fuck spacing bro
local gui_gbox_ple = gui.Groupbox(gui_tab, "Anti-Prediction/Logic", 16, 138, 296, 5) -- neato trick instead of using one groupbox just make one for every set of options in the same location, then hide the other groupboxes
local gui_gbox_fakedesync = gui.Groupbox(gui_tab, "Fake Desync", 16, 138, 296, 5)
local gui_gbox_wave = gui.Groupbox(gui_tab, "Desync Wave", 16, 138, 296, 5)
local gui_gbox_extra = gui.Groupbox(gui_tab, "Extra", 328, 16, 296, 5)

local options = {
    -- i keep everything in tables that i can because it lets me fold them in IDE
    aamode = gui.Combobox(gui_gbox_aa, "nomad.mode", "Anti-Aim Mode", "Off", "Anti-Prediction/Logic", "Fake Desync", "Desync Wave"), -- anti-aim mode
    mode = gui.Combobox(gui_gbox_ple, "nomad.ple.mode", "Peek Real Mode", "Overlapping", "Not Overlapping"), -- When you want to peek your real
    gap_desync = gui.Slider(gui_gbox_ple, "nomad.ple.gap.desync", "Desync Gap", 29, 0, 58), -- How much to reduce your desync when not overlapping
    gap_real = gui.Slider(gui_gbox_ple, "nomad.ple.gap.real", "Real Gap", 3, 0, 58), -- Yaw offset, for more customization
    overlap_threshold = gui.Slider(gui_gbox_extra, "nomad.overlap.threshold", "Overlap Threshold", 16, 1, 58), -- How close your real has to be to your desync to be considered overlapping
    lby_mode = gui.Combobox(gui_gbox_extra, "nomad.lby.mode", "LBY Mode", "Default", "Desync", "Real", "Between", "Opposite", "Spin", "Lisp"), -- LBY customization
    delay = gui.Slider(gui_gbox_fakedesync, "nomad.fd.delay", "Desync Delay", 7, 2, 14), -- Fake desync delay
    dtfix = gui.Checkbox(gui_gbox_extra, "nomad.dtfix", "Double-Tap Fix", 1), -- double tap speed fix
    xhair = gui.Checkbox(gui_gbox_extra, "nomad.xhair", "Nomad Crosshair", 0), -- crosshair
    xhairsize = gui.Slider(gui_gbox_extra, "nomad.xhair.size", "Crosshair Size", 12, 1, 25), -- crosshair size adjust
    wavespeed = gui.Slider(gui_gbox_wave, "nomad.wave.speed", "Wave Speed", 1, -6, 6), -- wave speed
    hitsound = gui.Checkbox(gui_gbox_extra, "nomad.hitsound", "Hitsound", 0),
    indicator = gui.Combobox(gui_gbox_extra, "nomad.indicator", "Indicator", "Off", "Aimware") -- Show aimware indicator window
}

local descriptions = {
    -- again, just used to keep code cleaner in IDE
    options.mode:SetDescription("When to peek your real"),
    options.gap_desync:SetDescription("Desync to reduce when not overlapping"),
    options.gap_real:SetDescription("Amount to hide/peek"),
    options.overlap_threshold:SetDescription("How close to consider Overlapping"),
    options.dtfix:SetDescription("Fixes issue that reduces speed"),
    options.xhair:SetDescription("Custom crosshair and hitmarker")
}

local labels = {
    -- I should change "Overlapping" to things relating to the selected anti-aim mode, but i don't think it's really worth it
    gui.Text(gui_window_indicators, "Overlapping:"),
    gui.Text(gui_window_indicators, "Desync Side:"),
    gui.Text(gui_window_indicators, "Desync Amt:"),
    gui.Text(gui_window_indicators, "Peek Angle:")
}

local indicator_text = {
    gui.Text(gui_window_indicators, "nil"), -- overlap
    gui.Text(gui_window_indicators, "nil"), -- desync side
    gui.Text(gui_window_indicators, "nil"), -- desync amount
    gui.Text(gui_window_indicators, "nil") -- peeking side
}

for i = 1, #indicator_text do -- it's not lazy, it's efficient.
    indicator_text[i]:SetPosX(85)
end

local desyncside = {
    -- look guys i figured out how tables work :^)
    [0] = "Off",
    [1] = "Left",
    [2] = "Right",
    [3] = "JRight",
    [4] = "JLeft"
}

local peekside = {
    [0] = "Fake",
    [1] = "Real"
}

local function isOverlapping()
    return fDesyncAmount <= options.overlap_threshold:GetValue()
end

local function setDesync(val)
    gui.SetValue("rbot.antiaim.desync", val)
    gui.SetValue("rbot.antiaim.desyncleft", val)
    gui.SetValue("rbot.antiaim.desyncright", val)
end

local function handleLBY() -- now global :)

    local lp = entities.GetLocalPlayer()
    local lby = lp:GetProp("m_flLowerBodyYawTarget")
    local lbymode = options.lby_mode:GetValue() -- "Default", "Desync", "Real", "Between", "Opposite", "Spin", "Lisp"

    if lbymode == 0 then
        gui.SetValue("rbot.antiaim.lbyextend", 0)
        return
    else
        gui.SetValue("rbot.antiaim.lbyextend", 1)
    end

    local angles = {
        -- default isn't listed because it's just not editing it at all.
        fPlayerDesyncAngle, -- desync (better than you might think)
        fPlayerRealAngle, -- real
        (fPlayerRealAngle + fPlayerDesyncAngle) / 2, -- between
        ((fPlayerRealAngle + fPlayerDesyncAngle) / 2) + 180, -- opposite
        lby + 5, -- spin
        fPlayerRealAngle - (360 - fDesyncAmount * 2) -- lisp
    }
    lp:SetProp("m_flLowerBodyYawTarget", angles[lbymode])
end

local function handleAPL() -- good against anything with the right config. proud of how this came out and how well it works tbh
    if options.aamode:GetValue() ~= 1 then return end
    local plemode = options.mode:GetValue()
    local gap_desync = options.gap_desync:GetValue()
    local gap_real = options.gap_real:GetValue()

    if not isOverlapping() then
        setDesync(58 - gap_desync) -- if not overlapping, reduce your desync by the gap selected in gui
        gui.SetValue("rbot.antiaim.fakeyawstyle", 2) -- desync right
        gui.SetValue("rbot.antiaim.autodirmode", plemode) -- peeks real depending on gui selection
        gui.SetValue("rbot.antiaim.yaw", 180 - gap_real) -- real gap
    else
        setDesync(58) -- if overlapping, maximize desync
        gui.SetValue("rbot.antiaim.fakeyawstyle", 1) -- desync left
        gui.SetValue("rbot.antiaim.autodirmode", not plemode)
        gui.SetValue("rbot.antiaim.yaw", -180 + gap_real) -- flip your gap, this helps you keep your head behind a wall otherwise you peek a lot.
    end
end

local function handleFakeDesync() -- skeet will destroy this, but good against nixware, otc, aw, and ot.

    if options.aamode:GetValue() ~= 2 then return end
    local delay = options.delay:GetValue()

    if globals.TickCount() % delay == 0 then
        setDesync(0) -- nope im not desyncing
        gui.SetValue("rbot.antiaim.yaw", 180)
    else
        setDesync(1) -- wait yes i am ooOOoOooo
        gui.SetValue("rbot.antiaim.yaw", 179)
    end
end

local function handleDesyncWave() -- skeet will SMOKE this antiaim. nixware and otc will dump tho, aimware and ot are 50/50
    if options.aamode:GetValue() ~= 3 then return end
    local wavespeed = options.wavespeed:GetValue()
    if wavespeed > 0 then -- forward
        if gui.GetValue("rbot.antiaim.desync") == 58 then -- this makes it snap back
            setDesync(0)
        else
            setDesync(gui.GetValue("rbot.antiaim.desync") + wavespeed) -- tried using tickcount but it was too slow, might try other timers because it seems fast
        end
    elseif wavespeed < 0 then -- backwards
        if gui.GetValue("rbot.antiaim.desync") == 0 then
            setDesync(58)
        else
            setDesync(gui.GetValue("rbot.antiaim.desync") + wavespeed)
        end
    end
end

local function handleGUI() -- please dont look at this

    local mode = options.aamode:GetValue()

    indicator_text[1]:SetPosY(17)

    -- some boolean logic to simplify menu code // Scape
    gui_gbox_ple:SetInvisible( mode ~= 1)        -- prediction      (mode 1)
    gui_gbox_fakedesync:SetInvisible(mode ~= 2) -- fake desync      (mode 2)
    gui_gbox_wave:SetInvisible(mode ~= 3)       -- wave             (mode 3)
    gui_window_indicators:SetActive(options.indicator:GetValue() == 1)

    if mode ~= 0 then
        gui.SetValue("rbot.antiaim.lbyextend", mode == 1)
    end

    options.xhairsize:SetInvisible(not options.xhair:GetValue())

    local conditions = {
        -- this is fine
        tostring(isOverlapping()),
        desyncside[gui.GetValue("rbot.antiaim.fakeyawstyle")],
        tostring(fDesyncAmount) .. "°",
        peekside[gui.GetValue("rbot.antiaim.autodirmode")]
    }

    for i = 1, #indicator_text do
        indicator_text[i]:SetText(string.upper(conditions[i])) -- it's not lazy, it's efficient
    end
end

local function handleCrosshair() -- fun fact this is just a copy of my team fortress 2 crosshair

    if not options.xhair:GetValue() then return end
    local size = options.xhairsize:GetValue()
    local scrW, scrY = draw.GetScreenSize()
    local centW, centY = scrW / 2, scrY / 2
    local r, g, b, a = gui.GetValue("esp.other.crosshair.clr")

    draw.Color(r, g, b, a)
    draw.OutlinedRect(centW - size, centY - size, centW + size, centY + size)

    if fAlpha >= 2 then
        draw.Color(r, g, b, fAlpha)
        fAlpha = fAlpha - 5
    else
        draw.Color(r, g, b, fAlpha)
    end

    draw.FilledRect(centW - size, centY - size, centW + size, centY + size)

end

local function handleShooting(event)

if not (event:GetName() == 'weapon_fire') then return end

    local lp = client.GetLocalPlayerIndex()
    local int_shooter = event:GetInt('userid')
    local index_shooter = client.GetPlayerIndexByUserID(int_shooter)
    if (index_shooter == lp) then
        if options.dtfix:GetValue() then
            bDtap = true;
            if debug then print("[DTFIX] Local Shot Registered") end
        end
    end
end

local function handleCrosshairEvent(event)
    if(event:GetName() == 'player_hurt') then
        local attacker = event:GetInt('attacker')
        local attackerindex = client.GetPlayerIndexByUserID(attacker)
        if(attackerindex == client.GetLocalPlayerIndex()) then
            fAlpha = 255;
            if options.hitsound:GetValue() then
                if debug then print("[HSOUND] Hit Registered") end
                client.Command('playvol weapons/scar20/scar20_boltback 2', true)
                gui.SetValue("esp.world.hiteffects.sound", 0)
            end
        end
    end
end

local function handleDesyncInfo(cmd)

    if not cmd.sendpacket then
        fPlayerDesyncAngle = cmd.viewangles.y; -- if you are not choking packets, this is your desync angle
    else
        fPlayerRealAngle = cmd.viewangles.y; -- if you are choking packets, it's your real angle.
    end

    fDesyncAmount = math.min(58, math.ceil(math.abs((math.floor(fPlayerDesyncAngle) - math.floor(fPlayerRealAngle)) / 2.1))) -- adjusted for accuracy on the indicator and smoother math, there's probably a more efficient way to do this
    fRawDesyncAmount = math.abs((math.abs(fPlayerDesyncAngle) - math.abs(fPlayerRealAngle)) / 2.1) -- not adjusted, should be using this for everything else but i don't think it matters much.
end

local function handleDoubleTap(cmd)

    if not options.dtfix:GetValue() then return end
    if bDtap then
        cmd.sidemove = 0;
        cmd.forwardmove = 0;
        bDtap = false;
        if debug then print("[DTAP] Local Shot Registered") end
    end
end

callbacks.Register("CreateMove", function(cmd)

    handleDesyncInfo(cmd); -- wish there was a better way to do this so i could still pass args, maybe there is idk
    handleDoubleTap(cmd);

end)

callbacks.Register("Draw", function()

    handleGUI(); -- want this running in main menu so newbies can explore it when not ingame
    local lp = entities.GetLocalPlayer()
    if not lp or not lp:IsAlive() then return end
    isOverlapping(); -- keeps indicator up-to-date, otherwise should only be used internally
    handleDesyncWave(); -- desync wave
    handleFakeDesync(); -- fake desync
    handleAPL();        -- anti prediction/logic
    handleLBY();        -- part of APL (may add to other antiaims)
    handleCrosshair();

end)

callbacks.Register("FireGameEvent", function(event)
    handleCrosshairEvent(event);
    handleShooting(event);
end)

client.AllowListener('player_hurt');
client.AllowListener('weapon_fire');
-- there's no reason this code should be this long but i'm too lazy to make proper functions for the gui and anti-aim modes. this is the pure raw shitty way that i prototype antiaim.
-- this wasn't made for public release, i just felt like posting it. i won't give any support, if you don't understand how to config it then don't use it
-- if i catch someone selling this i will issue a dmca as it's licensed under GPL. feel free to edit and contribute to this project for personal use though
