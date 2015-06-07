# LuaPyro - Python Remote Objects
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

-- Main directory of luaPyro library
__PATH__ = '{somedir}/lib/luaPyro'

-- Sets the location of the bits files.
SHA1_PATH = __PATH__..'/sha1'

-- Api directory
local apiLua_dir = __PATH__..'/api-lua3.2'

-- Loads the file settings of pyro system.
dofile(apiLua_dir..'/configuration.lua')

-- Configuring the name server port.
config.NS_PORT = 9090

-- Loads the log script.
local logger = dofile(apiLua_dir..'/utils/logger.lua')

-- Sets the location of the log file.
config.LOG = {somedir}/lib/logs/rpc.log')

dofile(apiLua_dir..'/naming.lua')
dofile(apiLua_dir..'/constants.lua')
dofile(apiLua_dir..'/core.lua')

nameserver = NameServer:new(constants.FLAME_NAME)
proxy = Proxy:new(self.nameserver:getURI())

-- Once configured simply you use the created proxy.

local os = proxy.module{'os'}
os.getcwd()  -- current work dir
```
