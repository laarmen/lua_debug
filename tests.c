/*
 * Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
 *
 * This code is under the "Expat" license as specified in the COPYING file.
 * Do NOT remove this copyright/license notice.
 */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "lua_debug.h"

#include <unistd.h>
#include <stdio.h>

static const luaL_Reg STANDARD_LIBS[] = {
    { "_G", luaopen_base },
    { LUA_TABLIBNAME, luaopen_table },
    { LUA_STRLIBNAME, luaopen_string },
    { LUA_MATHLIBNAME, luaopen_math },
    { LUA_DBLIBNAME, luaopen_debug },
    { 0, 0 }
};

int main() {
    lua_State * l = (lua_State *)luaL_newstate();
    const luaL_Reg *lib;

    for (lib = STANDARD_LIBS; lib->func; ++lib) {
        luaL_requiref(l, lib->name, lib->func, 1);
        lua_pop(l, 1);
    }

    luaL_dofile(l, "debug.lua");
    lua_debug_init(l, "/tmp/socket_lua_debug");
    lua_debug_close(l);
    return 0;
}
