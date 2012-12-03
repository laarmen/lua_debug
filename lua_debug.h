/*
 * Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
 *
 * This code is under the "Expat" license as specified in the COPYING file.
 * Do NOT remove this copyright/license notice.
 */

#ifndef H_LUA_DEBUG
#define H_LUA_DEBUG

struct lua_State;

int lua_debug_init(lua_State * l, const char * sock_addr);

#endif

