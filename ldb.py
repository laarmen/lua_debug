#!/usr/bin/env python
#
# Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
#
# This code is under the "Expat" license as specified in the COPYING file.
# Do NOT remove this copyright/license notice.
#

from socket import socket, AF_UNIX, SOCK_STREAM
import os

s = socket(AF_UNIX, SOCK_STREAM)
s.bind('/tmp/socket_lua_debug')
s.listen(1)
lua = s.accept()[0]
print "Connected with Lua."
lua.recv(1024)
lua.close()

os.remove("/tmp/socket_lua_debug") # I don't know why it doesn't do it by itself.
