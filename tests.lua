
i = 10
f = function (a, b)
    local c = "test"
    for ii = 1,100000,1 do
        if ii%10 == 0 then
            print(ii)
        end
    end
    print(i)
end

f({}, nil)
