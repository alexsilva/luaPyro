--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 04:11
-- To change this template use File | Settings | File Templates.
--

local package = '/Pyrolite/lua32'

dofile(__path__ .. package .. '/message.lua')
dofile(__path__ .. package ..'/serializer.lua')
dofile(__path__ .. package .. '/pyrouri.lua')

proxy = {}

local TAG = newtag()

settag(proxy, TAG)

-- cria, inicializa a conexão do proxy
function proxy.create_connection(self, uri)
    self.uri = pyrouri(uri)

    local conn, smsg = connect(self.uri.loc, self.uri.port)
    self.connection = conn

    return message:recv(conn)
end

-- resolução dinâmica de méthodos da api remota no proxy
settagmethod(TAG, 'index', function(self, name)
    local callback = {}
    settagmethod(tag(callback), 'function', function(object, ...)
        return %self:call(%name, arg)
    end)
    return callback
end)

-- chama o método remoto
function proxy.call(self, methodname, args)
    local data = serialize:dumps({self.uri.objectid, methodname, args})

    message.serializer_id = serialize.serializer_id
    message.msg_type = message.MSG_INVOKE
    message.data_size = strlen(data)
    message.data = data

    self.connection:send(message:to_bytes())

    local resultmsg = message:recv(self.connection)

    return serialize:loads(resultmsg.data)
end