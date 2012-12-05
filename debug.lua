local hook = function (event_type, line_nb)
    local cmd = debug.dbsock_read()
    if cmd then print(cmd) end
    if cmd and string.find(cmd, 'halt', 1, true) == 1 then
        debug.dbsock_send("ACK halt")
        local continue = false
        while not continue do
            cmd = debug.dbsock_read(true)
            if string.find(cmd, "continue", 1, true) == 1 then
                debug.dbsock_send("ACK continue")
                continue = true
            end
        end
    end
end
debug.load_debugger = function() 
    debug.sethook(hook, "crl")
end
