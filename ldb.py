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

class Ldb(object):
    def __init__(self, sock_path='/tmp/socket_lua_debug'):
        self._s = socket(AF_UNIX, SOCK_STREAM)
        self._sock_path = sock_path
        self._s.bind(sock_path)
        self._s.listen(1)

    def _wait_ack(self, cmd_name):
        ack = str()
        while not ack.startswith("ACK {0}".format(cmd_name)):
            ack = self._lua.recv(1024)

    def run(self):
        self._lua = self._s.accept()[0]
        self._lua.send('run');

    def start(self):
        self.run()
        self.halt()

    def halt(self):
        self._lua.send("halt\n")
        self._wait_ack("halt")

    def continue_(self): # it is a language keyword, hence the trailing _
        self._lua.send("continue\n")
        self._wait_ack("continue")

    def backtrace(self):
        bt = []
        self._lua.send("backtrace")
        answer = self._lua.recv(1024)
        print answer
        print "end of answer"
        while not answer.startswith("end backtrace"):
            self._lua.send("ACK frame")
            bt.append(answer)
            answer = self._lua.recv(1024)
        self._lua.send("ACK end")
        return bt

    def reload(self):
        self._lua.close()
        self.start()

    def __del__(self):
        if (hasattr(self, "_lua")):
            self._lua.close()
        self._s.close()
        os.remove(self._sock_path)

