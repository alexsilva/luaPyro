--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 05:58
-- To change this template use File | Settings | File Templates.
--

dofile(__path__ .. '/Pyrolite/lua32' .. '/serializers/json.lua')

local TYPES = {
    ["serpent"] = {
        id = 1,
    },
    ["json"] = {
        id = 2,
        decoder = json_decode,
        encoder = table2JSON
    },
    ["marshal"] = {
        id = 3
    },
    ["pickle"] = {
        id = 4
    }
}

serializer = {
    id = SERIALIZER_SERPENT,
    type = 'json'
}

function serializer.getid(self)
    return %TYPES[self.type].id
end

-- serializa o objeto para envio na rede
function serializer.dumps(self, ...)
    return %TYPES[self.type].encoder(arg[1])
end

-- retorna os dados deseralizados
function serializer.loads(self, data)
    return %TYPES[self.type].decoder(data)
end

-- objeto real de decodificação/codificação
function serializer.set_type(self, name)
    self.type = name
    return self
end