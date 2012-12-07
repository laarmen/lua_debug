local word_pattern = "[%w_]+"

local hook = function (event_type, line_nb)
    local msg = debug.dbsock_read(true)
    if msg and string.find(msg, 'halt', 1, true) == 1 then
        debug.dbsock_send("ACK halt")
        local continue = false
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
            end
        end
    end
end
debug.load_debugger = function() 
    debug.sethook(hook, "crl")
end
