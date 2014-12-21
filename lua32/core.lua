--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 04:11
-- To change this template use File | Settings | File Templates.
--
dofile('C:/inetpub/wwwroot/publique-repo/web/cgi/cgilua.conf/Pyrolite/lua32/message.lua')

local host = "localhost"
local port = 49342


proxy = {}

function proxy.create_connection(self, host, port)
    local connection, smsg = connect(host, port)

    self.connection = connection

    return message:recv(connection)
end