local ADDON_NAME = "SimpleMaillog"
local core_mainmenu = require("core_mainmenu")
local cfg = require("Chatlog.configuration")
local optionsLoaded, options = pcall(require, "Chatlog.options")

local optionsFileName = "addons/"..ADDON_NAME.."/options.lua"
local firstPresent = true
local ConfigurationWindow

-- Application constant
local LOG_NAME = "addons/"..ADDON_NAME.."/log/simple_mail.txt"
local DATE_LOG_NAME = "addons/"..ADDON_NAME.."/log/simple_mail"..os.date('%Y%m%d')..".txt"
local DEBUG_LOG_NAME = "addons/"..ADDON_NAME.."/debug.txt"

-- Helpers in solylib
local function _getMenuState()
    local offsets = {
        0x00A98478,
        0x00000010,
        0x0000001E,
    }
    local address = 0
    local value = -1
    local bad_read = false
    for k, v in pairs(offsets) do
        if address ~= -1 then
            address = pso.read_u32(address + v)
            if address == 0 then
                address = -1
            end
        end
    end
    if address ~= -1 then
        value = bit.band(address, 0xFFFF)
    end
    return value
end
local function IsMenuOpen()
    local menuOpen = 0x43
    local menuState = _getMenuState()
    return menuState == menuOpen
end
local function IsSymbolChatOpen()
    local wordSelectOpen = 0x40
    local menuState = _getMenuState()
    return menuState == wordSelectOpen
end
local function IsMenuUnavailable()
    local menuState = _getMenuState()
    return menuState == -1
end
local function NotNilOrDefault(value, default)
    if value == nil then
        return default
    else
        return value
    end
end
local function GetPosBySizeAndAnchor(_x, _y, _w, _h, _anchor)
    local x
    local y

    local resW = pso.read_u16(0x00A46C48)
    local resH = pso.read_u16(0x00A46C4A)

    -- Top left
    if _anchor == 1 then
        x = _x
        y = _y

    -- Left
    elseif _anchor == 2 then
        x = _x
        y = (resH / 2) - (_h / 2) + _y

    -- Bottom left
    elseif _anchor == 3 then
        x = _x
        y = resH - _h + _y

    -- Top
    elseif _anchor == 4 then
        x = (resW / 2) - (_w / 2) + _x
        y = _y

    -- Center
    elseif _anchor == 5 then
        x = (resW / 2) - (_w / 2) + _x
        y = (resH / 2) - (_h / 2) + _y

    -- Bottom
    elseif _anchor == 6 then
        x = (resW / 2) - (_w / 2) + _x
        y = resH - _h + _y

    -- Top right
    elseif _anchor == 7 then
        x = resW - _w + _x
        y = _y

    -- Right
    elseif _anchor == 8 then
        x = resW - _w + _x
        y = (resH / 2) - (_h / 2) + _y

    -- Bottom right
    elseif _anchor == 9 then
        x = resW - _w + _x
        y = resH - _h + _y

    -- Whatever
    else
        x = _x
        y = _y
    end

    return { x, y }
end
-- End of helpers in solylib

if optionsLoaded then
    -- If options loaded, make sure we have all those we need
    options.configurationEnableWindow = NotNilOrDefault(options.configurationEnableWindow, true)
    options.enable                    = NotNilOrDefault(options.enable, true)
    options.useCustomTheme            = NotNilOrDefault(options.useCustomTheme, false)
    options.fontScale                 = NotNilOrDefault(options.fontScale, 1.0)

    options.clEnableWindow            = NotNilOrDefault(options.clEnableWindow, true)
    options.clHideWhenMenu            = NotNilOrDefault(options.clHideWhenMenu, true)
    options.clHideWhenSymbolChat      = NotNilOrDefault(options.clHideWhenSymbolChat, true)
    options.clHideWhenMenuUnavailable = NotNilOrDefault(options.clHideWhenMenuUnavailable, true)
    options.clChanged                 = NotNilOrDefault(options.clChanged, false)
    options.clAnchor                  = NotNilOrDefault(options.clAnchor, 1)
    options.clX                       = NotNilOrDefault(options.clX, 50)
    options.clY                       = NotNilOrDefault(options.clY, 50)
    options.clW                       = NotNilOrDefault(options.clW, 450)
    options.clH                       = NotNilOrDefault(options.clH, 350)
    options.clNoTitleBar              = NotNilOrDefault(options.clNoTitleBar, "")
    options.clNoResize                = NotNilOrDefault(options.clNoResize, "")
    options.clNoMove                  = NotNilOrDefault(options.clNoMove, "")
    options.clTransparentWindow       = NotNilOrDefault(options.clTransparentWindow, false)
else
    options =
    {
        configurationEnableWindow = true,
        enable = true,
        useCustomTheme = false,
        fontScale = 1.0,

        clEnableWindow = true,
        clHideWhenMenu = false,
        clHideWhenSymbolChat = false,
        clHideWhenMenuUnavailable = false,
        clChanged = false,
        clAnchor = 1,
        clX = 50,
        clY = 50,
        clW = 450,
        clH = 350,
        clNoTitleBar = "",
        clNoResize = "",
        clNoMove = "",
        clTransparentWindow = false,
    }
end

local function SaveOptions(options)
    local file = io.open(optionsFileName, "w")
    if file ~= nil then
        io.output(file)

        io.write("return\n")
        io.write("{\n")
        io.write(string.format("    configurationEnableWindow = %s,\n", tostring(options.configurationEnableWindow)))
        io.write(string.format("    enable = %s,\n", tostring(options.enable)))
        io.write(string.format("    useCustomTheme = %s,\n", tostring(options.useCustomTheme)))
        io.write(string.format("    fontScale = %s,\n", tostring(options.fontScale)))
        io.write("\n")
        io.write(string.format("    clEnableWindow = %s,\n", tostring(options.clEnableWindow)))
        io.write(string.format("    clHideWhenMenu = %s,\n", tostring(options.clHideWhenMenu)))
        io.write(string.format("    clHideWhenSymbolChat = %s,\n", tostring(options.clHideWhenSymbolChat)))
        io.write(string.format("    clHideWhenMenuUnavailable = %s,\n", tostring(options.clHideWhenMenuUnavailable)))
        io.write(string.format("    clChanged = %s,\n", tostring(options.clChanged)))
        io.write(string.format("    clAnchor = %i,\n", options.clAnchor))
        io.write(string.format("    clX = %i,\n", options.clX))
        io.write(string.format("    clY = %i,\n", options.clY))
        io.write(string.format("    clW = %i,\n", options.clW))
        io.write(string.format("    clH = %i,\n", options.clH))
        io.write(string.format("    clNoTitleBar = \"%s\",\n", options.clNoTitleBar))
        io.write(string.format("    clNoResize = \"%s\",\n", options.clNoResize))
        io.write(string.format("    clNoMove = \"%s\",\n", options.clNoMove))
        io.write(string.format("    clTransparentWindow = %s,\n", tostring(options.clTransparentWindow)))
        io.write("}\n")

        io.close(file)
    end
end

local function read_pso_str(addr, len)
    local buf = {}
    pso.read_mem(buf, addr, len)
    local str = ""

    local i = 0
    while i < len do
        i = i + 2
        local b1 = buf[i - 1]
        local b2 = buf[i]

        xpcall(function() str = str .. string.char(b1) end, function(err) str = str .. "?" end)
    end

    return str
end

local function logging(msg, path)
    if path == nil then
        path = DEBUG_LOG_NAME
    end

    -- Create file
    local file = io.open(path, "a")

    io.output(file)
    io.write(msg.."\n")
    io.close(file)
end

local function getUnixTime(receivedAt)
    -- receivedAt format: 04/15/2023 09:55:34
    local unixTime = os.date(
        "*t",
        os.time {
            year = string.sub(receivedAt, 7, 11),
            month = string.sub(receivedAt, 1, 2),
            day = string.sub(receivedAt, 4, 5),
            hour = string.sub(receivedAt, 12, 13),
            min = string.sub(receivedAt, 15, 16),
            sec = string.sub(receivedAt, 18, 19)
        }
    )

    return os.time(unixTime)
end

local TIME_DIFFERENCE_HOURS = os.date("%H") - os.date("!%H")
local function addTimeDifference(receivedAt)
    local adjusted_time = getUnixTime(receivedAt) + (TIME_DIFFERENCE_HOURS * 3600)
    return os.date("%m/%d/%Y %H:%M:%S", adjusted_time )
end

local CHAT_PTR = 0x00AB0300
local MAIL_LENGTH = 444
local SENDER_OFFSET = 12
local RECIEVED_AT_OFFSET = 56
local TEXT_OFFSET = 100
local prevmaxy = 0
local MAX_MSG_SIZE = 50
local output_messages = {}

local function get_chat_log()
    local messages = {}
    for i = 0, (MAX_MSG_SIZE - 1) do -- for each pointer to a message
        local ptr = pso.read_u32(CHAT_PTR + i * MAIL_LENGTH)

        if ptr and ptr ~= 0 then
            local receivedAt = read_pso_str(CHAT_PTR + i * MAIL_LENGTH + RECIEVED_AT_OFFSET, 38)
            local name = read_pso_str(CHAT_PTR + i * MAIL_LENGTH + SENDER_OFFSET, 19)
            local text = read_pso_str(CHAT_PTR + i * MAIL_LENGTH + TEXT_OFFSET, 250)

            table.insert(
                messages,
                {
                    date = addTimeDifference(receivedAt), -- Calculate time difference
                    gcno = ptr,
                    name = name,
                    text = string.gsub(text, "%z", "") -- Delete empty characters
                }
            )
        end
    end
    return messages
end

local UPDATE_INTERVAL = 30
local counter = UPDATE_INTERVAL - 1
local MAX_LOG_SIZE = 1000

local function DoChat()
    counter = counter + 1

    if counter % UPDATE_INTERVAL == 0 then
        local sy = imgui.GetScrollY()
        local sym = imgui.GetScrollMaxY()
        scrolldown = false

        if sy <= 0 or prevmaxy == sy then
            scrolldown = true
        end

        local updated_messages = get_chat_log()

        if #output_messages == 0 and #updated_messages > 0 then
            -- old list is empty but there are new messages
            output_messages = updated_messages
        elseif #output_messages == 0 or #updated_messages == 0 then
            -- do nothing
        else
            -- diff old and new messages

            local idx = 1
            -- find index of the latest matching message
            -- wrap loops in func so we can break both with return
            ;(function()
                -- realistically we probably dont need the outer loop
                -- since there's no way more than 30 messages could be sent
                -- in between updates
                for i = #output_messages, 1, -1 do
                    for j = #updated_messages, 1, -1 do
                        if output_messages[i].text == updated_messages[j].text and
                        output_messages[i].name == updated_messages[j].name then
                            idx = j + 1
                            return
                        end
                    end
                end
            end)()

            -- add all new messages after that index
            for i = idx, #updated_messages do
                local msg = updated_messages[i]
                table.insert(output_messages, msg)

                -- write log file
                -- m:d:y h:m: \t gcno \t name \t text
                logging(
                    updated_messages[i].date.."\t" ..updated_messages[i].gcno.."\t" ..updated_messages[i].name.."\t" ..updated_messages[i].text,
                    LOG_NAME
                )
                -- write date log file. received_at is only h:m:s
                -- h:m:s \t gcno \t name \t text
                logging(
                    string.sub(updated_messages[i].date, 12, 19).."\t" ..updated_messages[i].gcno.."\t" ..updated_messages[i].name.."\t" ..updated_messages[i].text,
                    DATE_LOG_NAME
                )

                -- remove from start if log is too long
                if #output_messages > MAX_LOG_SIZE then
                    table.remove(output_messages, 1)
                end
            end
        end

        counter = 0
    end

    -- draw messages
    for i,msg in ipairs(output_messages) do
        local formatted = msg.formatted or
                          ( "[".. msg.date .. "] " ..  " (" .. msg.gcno .. ")"  .. string.format("%-11s", msg.name) .. -- rpad name
                          "| " .. string.gsub(msg.text, "%%", "%%%%")) -- escape '%'
        msg.formatted = formatted -- cache

        imgui.TextWrapped(formatted)

        if scrolldown then
            imgui.SetScrollY(imgui.GetScrollMaxY())
        end

        prevmaxy = imgui.GetScrollMaxY()
    end
end

local function present()
    -- If the addon has never been used, open the config window
    -- and disable the config window setting
    if options.configurationEnableWindow then
        ConfigurationWindow.open = true
        options.configurationEnableWindow = false
    end

    ConfigurationWindow.Update()
    if ConfigurationWindow.changed then
        ConfigurationWindow.changed = false
        SaveOptions(options)
    end

    -- Global enable here to let the configuration window work
    if options.enable == false then
        return
    end

    if (options.clEnableWindow == true)
        and (options.clHideWhenMenu == false or IsMenuOpen() == false)
        and (options.clHideWhenSymbolChat == false or IsSymbolChatOpen() == false)
        and (options.clHideWhenMenuUnavailable == false or IsMenuUnavailable() == false)
    then
        if firstPresent or options.clChanged then
            options.clChanged = false
            local ps = GetPosBySizeAndAnchor(options.clX, options.clY, options.clW, options.clH, options.clAnchor)
            imgui.SetNextWindowPos(ps[1], ps[2], "Always");
            imgui.SetNextWindowSize(options.clW, options.clH, "Always");
        end
        if options.clTransparentWindow == true then
            imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
        end
        if imgui.Begin(ADDON_NAME, nil, { options.clNoTitleBar, options.clNoResize, options.clNoMove }) then
            imgui.SetWindowFontScale(options.fontScale)
            DoChat()
        end
        imgui.End()
        if options.clTransparentWindow == true then
            imgui.PopStyleColor()
        end
        if firstPresent then
            firstPresent = false
        end
    end
end

local function readSimpleMaillog()
    local file = io.open(LOG_NAME, "r")

    if file ~= nil then
        for line in io.lines(LOG_NAME) do
            local msg = {}
            for substr in string.gmatch(line, "[^\t]+") do
                table.insert(msg, substr)
            end

            table.insert(
                output_messages,
                {
                    date = msg[1] or "",
                    gcno = msg[2] or "",
                    name = msg[3] or "",
                    text = msg[4] or ""
                }
            )
        end
        file:close()
    end
end

local function init()
    ConfigurationWindow = cfg.ConfigurationWindow(options)

    local function mainMenuButtonHandler()
        ConfigurationWindow.open = not ConfigurationWindow.open
    end

    core_mainmenu.add_button(ADDON_NAME, mainMenuButtonHandler)

    -- Read mail logs at init.
    readSimpleMaillog()

    return
    {
        name = ADDON_NAME,
        version = "0.1.0",
        author = "esc",
        present = present
    }
end

return {
    __addon =
    {
        init = init,
    },
}
