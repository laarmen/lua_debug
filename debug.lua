local word_pattern = "[%w_]+"

debug.build_lookup_table = function (stack_level)
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
    
local hook = function (event_type, line_nb)
    local msg = debug.dbsock_read(true)
    if msg and string.find(msg, 'halt', 1, true) == 1 then
        debug.dbsock_send("ACK halt")
        local continue = false
        local lookup_stack = {}
        local stack_level = 1
        while not continue do
            cmd = debug.dbsock_read()
            words = string.gmatch(cmd, word_pattern)
            cmd_name = words()

            if cmd_name == "continue" then
                debug.dbsock_send("ACK continue")
                continue = true


            elseif cmd_name == "backtrace" then
                debug.dbsock_send(debug.traceback(nil, 1+stack_level))

                local ack = ""
                while not (string.find(ack, 'ACK frame', 1, true) == 1) do
                    ack = debug.dbsock_read()
                end

                debug.dbsock_send("end backtrace")
                while not (string.find(ack, 'ACK end', 1, true) == 1) do
                    ack = debug.dbsock_read()
                end


            elseif cmd_name == "get_var" then
                local var_name = words()

                if var_name then
                    debug.dbsock_send("ACK get_var")

                    local lookup_table = lookup_stack[stack_level]
                    if not lookup_table then
                        lookup_table = debug.build_lookup_table(stack_level+2) 
                        lookup_stack[stack_level] = lookup_table
                    end
                    local value = lookup_table[var_name]

                    debug.dbsock_send(type(value).." "..tostring(value))

                else
                    debug.dbsock_send("ERR get_var")
                end

            end
        end
    end
end
debug.load_debugger = function() 
    debug.sethook(hook, "crl")
end
