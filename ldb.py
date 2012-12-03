#!/usr/bin/env python

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
