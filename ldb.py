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
    def __init__(self, conn, parent):
        self._lua = conn
        self._parent = parent

    def __del__(self):
        self._lua.close()
        self._parent.close_conn(self)

    def _wait_ack(self, cmd_name):
        ack = str()
        while not ack.startswith("ACK {0}".format(cmd_name)):
            ack = self._lua.recv(1024)

    def halt(self):
        self._lua.send("halt\n")
        self._wait_ack("halt")

    def continue_(self): # it is a language keyword, hence the trailing _
        self._lua.send("continue\n")
        self._wait_ack("continue")

    def get(self, var_name):
        self._lua.send("get_var {0}".format(var_name))
        answer = self._lua.recv(1024)
        return answer

    def break_(self, filename, line_nb):
        self._lua.send("add_breakpoint {0} {1}".format(filename, line_nb))
        bp_nb = int(self._lua.recv(1024))
        return None if bp_nb == 0 else bp_nb

    def up(self):
        self._lua.send("up\n")
        self._wait_ack("up")

    def down(self):
        self._lua.send("down")
        self._wait_ack("down")

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

class LdbServer(object):
    def __init__(self, sock_path='/tmp/ldb_sock'):
        self._s = socket(AF_UNIX, SOCK_STREAM)
        self._sock_path = sock_path
        self._s.bind(sock_path)
        self._s.listen(1)
        self._conns = []

    def run(self):
        conn = self._s.accept()[0]
        conn.send('run');
        self._conns.append(Ldb(conn, self))
        return self._conns[-1]

    def start(self):
        conn = self.run()
        conn.halt()
        return conn

    def close_conn(self, conn):
        self._conns.remove(conn)

    def __del__(self):
        for c in list(self._conns):
            del c
        self._lua.close()
        self._s.close()
        os.remove(self._sock_path)

if __name__ == '__main__':
    import sys
    from IPython import embed
    l = LdbServer() if len(sys.argv) < 2 else Ldb(sys.argv[1])
    embed()

