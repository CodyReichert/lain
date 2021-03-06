
--[[
                                                  
     Licensed under GNU General Public License v2 
      * (c) 2013, Luke Bonham                     
      * (c) 2010, Adrian C. <anrxc@sysphere.org>  
                                                  
--]]

local helpers      = require("lain.helpers")
local async        = require("lain.asyncshell")

local escape_f     = require("awful.util").escape
local naughty      = require("naughty")
local wibox        = require("wibox")

local os           = { execute  = os.execute,
                       getenv   = os.getenv }
local math         = { floor    = math.floor }
local string       = { format   = string.format,
                       match    = string.match,
                       gmatch   = string.gmatch }

local setmetatable = setmetatable

-- MPD infos
-- lain.widgets.mpd
local mpd = {}

local function worker(args)
    local args        = args or {}
    local timeout     = args.timeout or 2
    local password    = args.password or ""
    local host        = args.host or "127.0.0.1"
    local port        = args.port or "6600"
    local music_dir   = args.music_dir or os.getenv("HOME") .. "/Music"
    local cover_size  = args.cover_size or 100
    local default_art = args.default_art or ""
    local settings    = args.settings or function() end

    local mpdcover = helpers.scripts_dir .. "mpdcover"
    local mpdh = "telnet://" .. host .. ":" .. port
    local echo = "echo 'password " .. password .. "\nstatus\ncurrentsong\nclose'"

    mpd.widget = wibox.widget.textbox('')

    helpers.set_map("current mpd track", nil)

    function mpd.update()
        async.request(echo .. " | curl --connect-timeout 1 -fsm 3 " .. mpdh, function (f)
            mpd_now = {
                state  = "N/A",
                file   = "N/A",
                artist = "N/A",
                title  = "N/A",
                album  = "N/A",
                date   = "N/A"
            }

            for line in f:lines() do
                for k, v in string.gmatch(line, "([%w]+):[%s](.*)$") do
                    if     k == "state"   then mpd_now.state   = v
                    elseif k == "file"    then mpd_now.file    = v
                    elseif k == "Artist"  then mpd_now.artist  = escape_f(v)
                    elseif k == "Title"   then mpd_now.title   = escape_f(v)
                    elseif k == "Album"   then mpd_now.album   = escape_f(v)
                    elseif k == "Date"    then mpd_now.date    = escape_f(v)
                    elseif k == "Time"    then mpd_now.time    = v
                    elseif k == "elapsed" then mpd_now.elapsed = string.match(v, "%d+")
                    end
                end
            end

            widget = mpd.widget
            settings()

            if mpd_now.state == "play"
            then
                if mpd_now.title ~= helpers.get_map("current mpd track")
                then
                end
            elseif mpd_now.state ~= "pause"
            then
                helpers.set_map("current mpd track", nil)
            end
        end)
    end

    helpers.newtimer("mpd", timeout, mpd.update)

    return setmetatable(mpd, { __index = mpd.widget })
end

return setmetatable(mpd, { __call = function(_, ...) return worker(...) end })
