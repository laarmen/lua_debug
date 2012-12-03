/*
 * Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
 *
 * This code is under the "Expat" license as specified in the COPYING file.
 * Do NOT remove this copyright/license notice.
 */

#include <lua.h>

#include <assert.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <errno.h>

int lua_debug_readline(lua_State *);
int lua_debug_send(lua_State *);

int lua_debug_init(lua_State * l, const char * sock_addr) {
    int flags;
    struct sockaddr_un addr;

    int sock = socket(AF_UNIX, SOCK_STREAM, 0);

    addr.sun_family = AF_UNIX;
    strcpy(addr.sun_path, sock_addr);
    if (connect(sock, (struct sockaddr *)(&addr), sizeof(addr.sun_family)+strlen(addr.sun_path)) != 0)
        lua_error(l);

    /* Check the current flags */
    if ((flags = fcntl(sock, F_GETFL, 0)) == -1)
        flags = 0;
    /* Non-blocking */
    fcntl(sock, F_SETFL, flags | O_NONBLOCK);

    lua_getglobal(l, "debug");
    lua_pushstring(l, "__dbsock_fd");
    lua_pushinteger(l, sock);
    lua_settable(l, -3);
    lua_pushstring(l, "dbsock_readline");
    lua_pushcfunction(l, lua_debug_readline);
    lua_settable(l, -3);
    lua_pushstring(l, "dbsock_send");
    lua_pushcfunction(l, lua_debug_send);
    lua_settable(l, -3);

    return 0;
}

int lua_debug_readline(lua_State * l) {
    char buf[1024];
    int i, sock, res;

    lua_getglobal(l, "debug");
    lua_pushstring(l, "__socket_fd");
    lua_gettable(l, -2);
    sock = lua_tointeger(l, -1);
    lua_pop(l, 2);

    for(i = 0 ; i < 1024 ; ++i) {
        res = recv(sock, &(buf[i]), 1, 0);
        if (res == -1) {
            assert(errno == EAGAIN || errno == EWOULDBLOCK);
            break;
        } else if (buf[i] == '\n')
            break;
    }
    if (i) {
        lua_pushlstring(l, buf, i);
        return 1;
    }
    return 0;
}

int lua_debug_send(lua_State * l) {
    size_t length;
    int sock;
    const char * str = lua_tolstring(l, 1, &length);

    lua_getglobal(l, "debug");
    lua_pushstring(l, "__socket_fd");
    lua_gettable(l, -2);
    sock = lua_tointeger(l, -1);
    lua_pop(l, 2);

    /* TODO: proper error handling. */
    send(sock, str, length, 0);

    return 0;
}
