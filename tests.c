/*
 * Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
 *
 * This code is under the "Expat" license as specified in the COPYING file.
 * Do NOT remove this copyright/license notice.
 */

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "ldbcore.h"

#include <unistd.h>
#include <stdio.h>

static const luaL_Reg STANDARD_LIBS[] = {
    { "_G", luaopen_base },
    { LUA_TABLIBNAME, luaopen_table },
    { LUA_STRLIBNAME, luaopen_string },
    { LUA_MATHLIBNAME, luaopen_math },
    { LUA_DBLIBNAME, luaopen_debug },
    { LUA_LOADLIBNAME, luaopen_package },
    { LUA_LDBCORELIBNAME, luaopen_ldbcore },
    { 0, 0 }
};

int lua_sleep(lua_State * l) {
    int seconds = lua_tointeger(l, 1);
    sleep(seconds);
    return 0;
}

int do_lua_file(lua_State * l, const char * filename) {
    int lua_err = luaL_dofile(l, filename);
    if (lua_err == LUA_OK)
        return 1;
    printf("Error in %s:\n", filename);
    printf("%s", lua_tostring(l, -1));
    lua_pop(l, 1);
    return 0;
}
int main() {
    lua_State * l = (lua_State *)luaL_newstate();
    const luaL_Reg *lib;

    for (lib = STANDARD_LIBS; lib->func; ++lib) {
        luaL_requiref(l, lib->name, lib->func, 1);
        lua_pop(l, 1);
    }

    lua_register(l, "sleep", lua_sleep);
    if (do_lua_file(l, "tests.lua"))
        return 0;
    return 1;
}
