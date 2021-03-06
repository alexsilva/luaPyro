--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 26/12/2014
-- Time: 01:35
-- To change this template use File | Settings | File Templates.
--
-- Configuration settings.
--

config = {
    LOG = nil,
    MSG_TRACE_DIR = nil,
    NS_PORT = 9090,
    NS_BCPORT = 9091,
    NS_HOST = "localhost",
    PROTOCOL_VERSION = 47,	-- Pyro 4.26
    PYROLITE_VERSION = "4.3",
    SERPENT_INDENT = 0,
    SERPENT_SET_LITERALS = 0,   -- set to true if talking to Python 3.2 or newer
    SERIALIZER = "json",
    DAEMON_NAME = "Pyro.Daemon",
    DEBUG = false
}

