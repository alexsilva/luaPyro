--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 27/12/2014
-- Time: 20:47
-- To change this template use File | Settings | File Templates.
--

dofile(__PATH__ .. '/Pyrolite/lua32/configuration.lua')

-- debug messages - by config
debug = {
    println = function(self, object)
        return write(tostring(object) .. '<br/>')
    end,
    -- log in screen
    message = function(self, object, header)
        if config.DEBUG == true then
            if header then self:println(header) end
            if type(object) == 'table' then
                tprint(object) -- print tables
            else
                self:println(object)
            end
        end
        if config.DEBUG_LOG_IN_FILE == true then
             self:messagefile(object, header)
        end
    end,
    -- log in file
    messagefile = function(self, str, header)
        local hnd = openfile(config.DEBUG_LOG_PATH, "a+")
        str = tostring(str)
        if (hnd) then
            write(hnd, "[", date() or '', "] ", (header or ''), " - " .. str .. "\n")
            closefile(hnd)
        end
    end
}