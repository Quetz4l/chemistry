local component = require("component")
local sides = require("sides")
local event = require "event"
TFFT = {}
TFFT.__index = TFFT

--Setings
local tfft = component.proxy("da4a98ad-a06a-4239-b0e4-8b7425266afd")
local ouptut_hatch = sides.up
local tank_list = {
    ["256000"] = sides.bottom,
    ["32000"] = sides.north
}


local fluids_list_with_256000l = {
}


--Code
function TFFT:tanks_is_empty()
    for i, tank in pairs(tank_list) do
        if tfft.getTankLevel(tank) ~= 0 then
            return false
        end
    end
    return true
end

function TFFT:unload()
    if TFFT:tanks_is_empty() then
        for i = 1, 25 do
            local amount = tfft.getTankLevel(ouptut_hatch, i)
            if amount >= 32000 then
                if fluids_list_with_256000l[tfft.getFluidInTank(ouptut_hatch, i).name] then 
                    tfft.transferFluid(ouptut_hatch, tank_list["256000"], 256000 * math.floor(amount / 256000), i - 1)
return
                else
                    tfft.transferFluid(ouptut_hatch, tank_list["32000"], 32000 * math.floor(amount / 32000), i - 1)
return
                end
            end
        end
    end
end

return TFFT
