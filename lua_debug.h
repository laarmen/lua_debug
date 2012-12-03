#ifndef H_LUA_DEBUG
#define H_LUA_DEBUG

struct lua_State;

int lua_debug_init(lua_State * l, const char * sock_addr);

#endif

