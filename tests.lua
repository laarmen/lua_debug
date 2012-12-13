debug.breakpoints['tests.lua'] = {5, 10}
i = 10
f = function (a, b)
    local c = "test"

    for ii = 1,10000,1 do
        if ii%1000 == 0 then
            print(ii)
        end
    end
    print(i)
end

f({}, nil)
