# LuaPyro - It `Lua 3.2` client to the library python [Pyro4](https://github.com/irmen/Pyro4).
This software is distributed under the terms written in the file `LICENSE`.

## Setup luaPyro


The project has dependencies with sub-modules, so before you use it you need to build it.
For this it contains the script `builder.py`. This script exports only the necessary script
to the location indicated by parameter `--buildpath`. So:


python builder.py --buildpath={somedir}/lib/luaPyro


Create a package with this structure inside lib dir:

luaPyro
```
--- api-lua3.2
--- luabit
--- sha1
```

Considering that we are in the `lib` directory as working directory. We have to create an
initialization lua script (configuration). I will call this script rpc.lua.
rpc.lua the script we have to initialize some global variables to work with the package luaPyro.


```lua

-- One of the main dependencies of luaPyro, is a socket library that provides 
-- a `connect` method, through which will be given the `host` and the server `port`.

loadlib('sock')

-- Main directory of luaPyro library
PYRO_PATH = '{somedir}/lib/luaPyro'

-- Sets the location of the bits files.
SHA1_PATH = PYRO_PATH..'/sha1'

-- Api directory
local apiLua_dir = PYRO_PATH..'/api-lua3.2'

-- Loads the file settings of pyro system.
dofile(apiLua_dir..'/configuration.lua')

-- Configuring the name server port.
config.NS_PORT = 9090

-- Loads the log script.
local logger = dofile(apiLua_dir..'/utils/logger.lua')

-- Sets the default log object (may be changed to another if necessary).
config.LOG = logger.Log:new('rpc.log')

dofile(apiLua_dir..'/naming.lua')
dofile(apiLua_dir..'/constants.lua')
dofile(apiLua_dir..'/core.lua')

local nameserver = PyroNameServer:new(constants.FLAME_NAME)
local proxy = PyroProxy:new(self.nameserver:getURI())

-- Once configured simply you use the created proxy.
local os = proxy.module{'os'}
print(os.getcwd())  -- current work dir
```
