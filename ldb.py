#!/usr/bin/env python
#
# Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
#
# This code is under the "Expat" license as specified in the COPYING file.
# Do NOT remove this copyright/license notice.
#

from socket import socket, AF_UNIX, SOCK_STREAM
import os
import sys
import time

class Ldb(object):
    def __init__(self, conn, parent):
        self._lua = conn
        self._parent = parent

    def teardown(self):
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
        print answer
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

class Console(object):
    def __init__(self, ldb):
        self.ldb = ldb
        self.cmds = {
                "run": ldb.run,
                "start": ldb.start,
                "close": lambda: ldb.close(ldb.current()),
                "next_context": ldb.next_context,
                "continue": lambda: ldb.current().continue_(),
                "c": lambda: ldb.current().continue_(),
                "backtrace": lambda: ldb.current().backtrace(),
                "bt": lambda: ldb.current().backtrace(),
                "up": lambda: ldb.current().up(),
                "down": lambda: ldb.current().down(),
                "break": lambda f, n: ldb.current().break_(f, n),
                "b": lambda f, n: ldb.current().break_(f, n),
                "print": lambda var: ldb.current().get(var),
        }

    def run(self):
        while True:
            try:
                self.prompt()
            except Exception as e:
                print e

    def prompt(self):
        sys.stdout.write("> ")
        cmd = sys.stdin.readline().split()
        self.cmds[cmd[0]](*tuple(cmd[1:]))

class LdbServer(object):
    def __init__(self, sock_path='/tmp/ldb_sock'):
        self._s = socket(AF_UNIX, SOCK_STREAM)
        self._sock_path = sock_path
        self._s.bind(sock_path)
        self._s.listen(1)
        self._current = -1
        self._conns = []

    def current(self):
        return self._conns[self._current] if self._current >= 0 else None

    def next_context(self):
        if self._current >= 0:
            self._current = (self._current+1)%len(self._conns)

    def run(self):
        conn = self._s.accept()[0]
        conn.send('run');
        self._conns.append(Ldb(conn, self))
        self._current = len(self._conns)-1
        return self._conns[-1]

    def start(self):
        conn = self.run()
        conn.halt()
        return conn

    def close_conn(self, conn):
        self._conns.remove(conn)

    def teardown(self):
        for c in list(self._conns):
            c.teardown()
        self._s.close()
        os.remove(self._sock_path)

if __name__ == '__main__':
    import sys
    l = LdbServer()
    console = Console(l)
    try:
        console.run()
    except:
        sys.exit(0)
    finally:
        l.teardown()

