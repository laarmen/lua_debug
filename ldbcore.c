/*
 * Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
 *
 * This code is under the "Expat" license as specified in the COPYING file.
 * Do NOT remove this copyright/license notice.
 */

#include <lua.h>
#include <lauxlib.h>

#include <assert.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>

int ldb_dbsock_read(lua_State *);
int ldb_dbsock_send(lua_State *);
int ldb_dbsock_close(lua_State *);

static const luaL_Reg ldb[] = {
    {"dbsock_read", ldb_dbsock_read},
    {"dbsock_send", ldb_dbsock_send},
    {NULL, NULL}
};

int luaopen_ldbcore(lua_State * l) {
    int loaded = 1;
    char * ldb_sock_addr;
    char run_buf[] = "  "; /* Plus the final \0 */
    struct sockaddr_un addr;
    int sock;

    sock = socket(AF_UNIX, SOCK_STREAM, 0);
    addr.sun_family = AF_UNIX;
    ldb_sock_addr = getenv("LDB_SOCK");
    if (!ldb_sock_addr)
        ldb_sock_addr = "/tmp/ldb_sock";

    strcpy(addr.sun_path, ldb_sock_addr);

    if (connect(sock, (struct sockaddr *)(&addr), sizeof(addr.sun_family)+strlen(addr.sun_path)) != 0) {
#ifdef DEBUG
        luaL_error(l, strerror(errno));
#else
        return errno;
#endif
    }

    while (strncmp(run_buf, "run", 3) != 0) {
        recv(sock, run_buf, 3, 0);
    }

    lua_getglobal(l, "ldb");
    if (lua_isnil(l, -1)) {
        loaded = 0;
        lua_pop(l, 1);
        lua_newtable(l);
        lua_pushvalue(l, -1);
        lua_setglobal(l, "ldb");
    }
    luaL_setfuncs(l, ldb, 0);
    lua_pushstring(l, "__dbsocket_fd");
    lua_pushinteger(l, sock);
    lua_settable(l, -3);
    lua_pop(l, 1);
    
    if (!loaded) {
        const char * script = (access(PREFIX "/share/ldb/ldb.lua", F_OK) == 0) ? PREFIX "/share/ldb/ldb.lua" : "ldb.lua";
        int lua_err = luaL_dofile(l, script);
        if (lua_err != LUA_OK) {
            fprintf(stderr, "Error in ldb.lua: %s", lua_tostring(l, -1));
            lua_error(l);
        }
    }

    return 0;
}

/*
 * Function: dbsock_read
 *
 * Get data from the debug socket.
 *
 * > cmd = debug.dbsock_read()
 *
 * Parameters:
 *
 *   non-blocking - Defaults to false. If false, the function halts until it can
 *              return a whole line.
 * Returns:
 *
 *   data - the data received through the socket.
 *
 * Availability:
 *
 *  0.1
 *
 */
int ldb_dbsock_read(lua_State * l) {
    char buf[1024];
    int sock, res, flags;

    if (lua_gettop(l) == 0 || !lua_toboolean(l, 1)) {
        flags = 0;
    } else {
        flags = MSG_DONTWAIT;
    }
    lua_getglobal(l, "ldb");
    lua_pushstring(l, "__dbsocket_fd");
    lua_gettable(l, -2);
    sock = lua_tointeger(l, -1);
    lua_pop(l, 2);

    res = recv(sock, buf, 1024, flags);
    if (res == -1 && errno != EAGAIN) { luaL_error(l, strerror(errno)); }
    if (res > 0) {
        lua_pushlstring(l, buf, res);
        return 1;
    }
    return 0;
}

/*
 * Function: dbsock_send
 *
 * Send data through the debug socket.
 *
 * > debug.dbsock_send("ACK")
 *
 * Parameters:
 *
 *   data - Data to send. 
 *
 * Availability:
 *
 *  0.1
 *
 */
int ldb_dbsock_send(lua_State * l) {
    size_t length;
    int sock;
    const char * str = lua_tolstring(l, 1, &length);

    lua_getglobal(l, "ldb");
    lua_pushstring(l, "__dbsocket_fd");
    lua_gettable(l, -2);
    sock = lua_tointeger(l, -1);
    lua_pop(l, 2);

    /* TODO: proper error handling. */
    send(sock, str, length, 0);

    return 0;
}

int ldb_close(lua_State * l) {
    int sock;
    lua_getglobal(l, "ldb");
    lua_pushstring(l, "__socket_fd");
    lua_gettable(l, -2);
    sock = lua_tointeger(l, -1);
    lua_pop(l, 1);
    close(sock);
    lua_pushstring(l, "__socket_fd");
    lua_pushnil(l);
    lua_settable(l, -3);
    lua_pop(l, 1);

    return 0;
}
