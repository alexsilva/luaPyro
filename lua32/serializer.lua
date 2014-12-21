--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 21/12/2014
-- Time: 05:58
-- To change this template use File | Settings | File Templates.
--

local SERIALIZER_SERPENT = 1
local SERIALIZER_JSON = 2
local SERIALIZER_MARSHAL = 3
local SERIALIZER_PICKLE = 4

serialize = {
    serializer_id = SERIALIZER_SERPENT
}

function serialize.dumps(self, obj)
    local data = "# serpent utf-8 python2.6\n('obj_c08fe2e66e404a33ad4d90cd7c19791f','sum',(2,2),{})"

    return data
end