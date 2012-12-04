#!/usr/bin/env python
#
# Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
#
# This code is under the "Expat" license as specified in the COPYING file.
# Do NOT remove this copyright/license notice.
#

from socket import socket, AF_UNIX, SOCK_STREAM
import os
import time

s = socket(AF_UNIX, SOCK_STREAM)
s.bind('/tmp/socket_lua_debug')
s.listen(1)
try:
    while (True):
        lua = s.accept()[0]
        print "Connected with Lua."
        time.sleep(2)
        print("halting.")
        lua.send("halt\n")
        ack = lua.recv(1024);
        if ack.startswith("ACK"):
            print("ACK.")
            time.sleep(2)
            print("continuing")
            lua.send("continue\n")
except KeyboardInterrupt:
    pass
lua.close()

os.remove("/tmp/socket_lua_debug") # I don't know why it doesn't do it by itself.
