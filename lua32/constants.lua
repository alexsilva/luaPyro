--
-- Created by IntelliJ IDEA.
-- User: alex
-- Date: 26/12/2014
-- Time: 01:41
-- To change this template use File | Settings | File Templates.
--
-- Definitions of various hard coded constants.

-- Pyro - Python Remote Objects.  Copyright by Irmen de Jong (irmen@razorvine.net).

-- Pyro version

constants = {
    VERSION = "4.31",

    -- standard object name for the Daemon object
    DAEMON_NAME = "Pyro.Daemon",

    -- standard name for the Name server itself
    NAMESERVER_NAME = "Pyro.NameServer",

    -- standard name for Flame server
    FLAME_NAME = "Pyro.Flame",

    -- wire protocol version. Note that if this gets updated, Pyrolite might need an update too.
    PROTOCOL_VERSION = 47,
}
