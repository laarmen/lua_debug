i = 10
f = function (a, b)
    local c = "test"
    print(c)
    for ii = 1,10000,1 do
        if ii%1000 == 0 then
            print(ii)
        end
    end
    print(i)
end
for j = 1, 4, 1 do
    print(j)
    f({}, nil)
end
