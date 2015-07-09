--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 05:58
-- To change this template use File | Settings | File Templates.
--

--dofile(PYRO_PATH .. '/api-lua3.2/serializers/json.lua')
dofile(PYRO_PATH .. '/api-lua3.2/configuration.lua')

local TYPES = {
    ["serpent"] = {
        id = 1,
    },
    ["json"] = {
        id = 2,
        decoder = function(data)
            data = json_decode(data)
            return data
        end,
        encoder = function(data)
            data = json_encode(data)
            return data
        end,
    },
    ["marshal"] = {
        id = 3
    },
    ["pickle"] = {
        id = 4
    }
}

Serializer = settag({}, newtag())

-- Method of resolution of the Serializer object instances.
settagmethod(tag(Serializer), 'index', function(tbl, name)
    return rawgettable(Serializer, name)
end)

function Serializer:new(type)
    local self = settag({}, tag(Serializer))
    self.type = (type or config.SERIALIZER) --  default json
    return self
end

function Serializer:getid()
    return %TYPES[self.type].id
end

-- serializa o objeto para envio na rede
function Serializer:dumps(...)
    return %TYPES[self.type].encoder(arg[1])
end

-- retorna os dados deseralizados
function Serializer:loads(data)
    return %TYPES[self.type].decoder(data)
end

-- objeto real de decodificação/codificação
function Serializer:set_type(name)
    self.type = name
    return self
end