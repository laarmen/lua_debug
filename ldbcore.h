/*
 * Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
 *
 * This code is under the "Expat" license as specified in the COPYING file.
 * Do NOT remove this copyright/license notice.
 */

#ifndef H_LUA_DEBUG
#define H_LUA_DEBUG

#define LUA_LDBCORELIBNAME "ldbcore"

struct lua_State;
const char * ldb_sock_addr;

int luaopen_ldbcore(lua_State * l);

#endif

