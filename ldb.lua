-- Copyright (C) 2012 Simon Chopin <chopin.simon@gmail.com>
--
-- This code is under the "Expat" license as specified in the COPYING file.
-- Do NOT remove this copyright/license notice.

local word_pattern = "[%S]+"

if not ldb then
    ldb = {}
end
ldb.build_lookup_table = function (stack_level)
    local ret = {}
    local info = debug.getinfo(stack_level+1, 'fnu')
    local name = true
    local value = true
    for i = 1,info.nups,1 do
        name, value = debug.getupvalue(info.func, i)
        ret[name] = value
    end
    local i = 1
    name = true
    while name do
        name, value = debug.getlocal(stack_level+1, i)
        if name then
            ret[name] = value
        end
        i = i+1
    end
    return ret
end
    
local function_breakpoints = {} -- Breakpoints per function.

ldb.build_breakpoints_table = function(function_infos)
    local filename = string.gmatch(function_infos.source, ".*@(.*)")()
    local affined_bps = {}
    if filename then
        local bps = ldb.breakpoints[filename]
        if bps then

            -- We need the lines sorted.
            local sorted_active = {}
            -- Simple insertion sort.
            for k,_ in pairs(function_infos.activelines) do
                local inserted = false
                for i,a in ipairs(sorted_active) do
                    if k < a then
                        table.insert(sorted_active, i, k)
                        inserted = true
                        break
                    end
                end
                if not inserted then
                    table.insert(sorted_active, k)
                end
            end

            local iter_active = ipairs(sorted_active)
            local iter_breakpoints = ipairs(bps)
            local i,a = iter_active(sorted_active, 0)
            local j,b = iter_breakpoints(bps, 0)
            while a and b do
                while b and b < a do -- Look for the next breakpoint in the function
                    j,b = iter_breakpoints(bps, j)
                end
                while b and a and b > a do -- Use the next active line.
                    i, a = iter_active(sorted_active, i)
                end
                if a and b then
                    if a == b then
                        affined_bps[a] = true
                    end
                    i, a = iter_active(sorted_active, i)
                end
            end
        end
    end
    return affined_bps
end

local hook = function (event_type, line_nb)
    local infos = debug.getinfo(2)
    local bps = function_breakpoints[infos.func]
    if not bps then
        bps = ldb.build_breakpoints_table(debug.getinfo(2, "SL"))
        function_breakpoints[infos.func] = bps
    end

    local halted = bps[line_nb]

    local msg = ldb.dbsock_read(true)
    if msg and string.find(msg, 'halt', 1, true) == 1 then
        ldb.dbsock_send("ACK halt")
        halted = true
    end

    if halted then
        local continue = false
        local lookup_stack = {}
        local stack_level = 1
        while not continue do
            cmd = ldb.dbsock_read()
            words = string.gmatch(cmd, word_pattern)
            cmd_name = words()

            if cmd_name == "continue" then
                ldb.dbsock_send("ACK continue")
                continue = true

            elseif cmd_name == "up" then
                ldb.dbsock_send("ACK up")
                stack_level = stack_level+1
                if debug.getinfo(stack_level) == nil then
                    stack_level = stack_level-1
                end

            elseif cmd_name == "down" then
                ldb.dbsock_send("ACK down")
                stack_level = math.min(1, stack_level-1)


            elseif cmd_name == "backtrace" then
                ldb.dbsock_send(debug.traceback(nil, 1+stack_level))

                local ack = ""
                while not (string.find(ack, 'ACK frame', 1, true) == 1) do
                    ack = ldb.dbsock_read()
                end

                ldb.dbsock_send("end backtrace")
                while not (string.find(ack, 'ACK end', 1, true) == 1) do
                    ack = ldb.dbsock_read()
                end


            elseif cmd_name == "get_var" then
                local var_name = words()

                if var_name then
                    local lookup_table = lookup_stack[stack_level]
                    if not lookup_table then
                        lookup_table = ldb.build_lookup_table(stack_level+1) 
                        lookup_stack[stack_level] = lookup_table
                    end
                    local value = lookup_table[var_name]

                    ldb.dbsock_send(type(value).." "..tostring(value))

                else
                    ldb.dbsock_send("ERR get_var")
                end

            elseif cmd_name == "add_breakpoint" then
                -- no data sanitation yet, it'll break when it'll break
                local file_name = words()
                local line_number = tonumber(words())
                local breakpoints = ldb.breakpoints[file_name] or {}
                local i = 1
                while i <= #breakpoints do
                    if breakpoints[i] >= line_number then
                        break
                    end
                    i = i+1
                end
                print(ldb.breakpoints)
                if breakpoints[i] ~= line_number then
                    table.insert(breakpoints, i, line_number)
                    function_breakpoints = {}
                    ldb.breakpoints[file_name] = breakpoints
                    print(ldb.breakpoints)
                    for k,v in pairs(ldb.breakpoints) do
                        print(tostring(k)..": "..tostring(v))
                    end
                    table.insert(ldb.breakpoint_stack, {file=file_name, line=line_number, disabled=false})
                    print("Sending "..tostring(#(ldb.breakpoint_stack)))
                    ldb.dbsock_send(#(ldb.breakpoint_stack))
                else
                    print("Sending 0")
                    ldb.dbsock_send("0")
                end
            end
        end
    end
end

ldb.load_debugger = function() 
    print("Loading debugger !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    ldb.breakpoints = {} -- Format : breakpoints[file] = {line_1, line_2, ...}
    ldb.breakpoint_stack = {} -- Format : linear table, element : {file=string, line=int, disabled=bool}
    debug.sethook(hook, "crl")
end

if not ldb.__dbsocket_fd then
    local res, err = pcall(function () require "ldbcore" end)
    if not res then
        print(err)
    end
end
-- Assume it has been set in the require if not earlier
if ldb.__dbsocket_fd then
    ldb.load_debugger()
end
