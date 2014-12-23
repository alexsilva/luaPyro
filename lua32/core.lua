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

settagmethod(TAG, 'function', function(self, uri)
    self.uri = pyrouri(uri)
    return self
end)

function proxy.set_serializer(self, name)
    serializer:set_type(name)
end

-- cria, inicializa a conexão do proxy
function proxy.start_connection(self)
    local conn, smsg = connect(self.uri.loc, self.uri.port)

    self.connection = conn

    return message:recv(conn)
end

-- resolução dinâmica de méthodos da api remota no proxy
settagmethod(TAG, 'index', function(self, name)
    local callback = {}
    settagmethod(tag(callback), 'function', function(object, ...)
        arg.n = nil
        return %self:call(%name, arg)
    end)
    return callback
end)

-- chama o método remoto
function proxy.call(self, methodname, args)
    local data = serializer:dumps({
        object= self.uri.objectid,
        method = methodname,
        params = args,
        kwargs = { x =1 }
    })

    message.serializer_id = serializer:getid()
    message.msg_type = message.MSG_INVOKE
    message.data_size = strlen(data)
    message.data = data

    self.connection:send(message:to_bytes())

    local resultmsg = message:recv(self.connection)

    return serializer:loads(resultmsg.data)
end