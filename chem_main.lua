local component = require("component")
local sides = require("sides")
local term = require("term")
local ChemicalReactor = dofile("ChemicalReactor.lua")

local transposer = component.proxy(component.get("f56808ef"))

local reactors = {
    ChemicalReactor:new(component.get("97051977"), component.get("e0c009ef")),
    ChemicalReactor:new(component.get("802586de"), component.get("4f989f83")),
    ChemicalReactor:new(component.get("fc68911c"), component.get("e407970c"))
}

local chest_with_circuits = sides.top
local endechest = sides.bottom
local interface = sides.south


local balancer = 0

function isReactorAvailible(reactor)
    return reactor:isInputHatchEmpty() and reactor:isInputBusEmpty()
end


function getNextReactor()
    balancer = balancer + 1
    if balancer > #reactors then
        balancer = 1
    end
    return reactors[balancer]
end

function getAvailibleReactor()
    while true do
        reactor = getNextReactor()
        if isReactorAvailible(reactor) then
            return reactor
        end
        os.sleep(0)
    end
end


term.clear()
term.write(" Запущена химия:\n\n")
load_params(transposer, endechest, interface)

while true do
    first = transposer.getStackInSlot(endechest, 1)
	ready = false
    if first ~= nil then
        if first.name == "minecraft:cobblestone" then
            circuit = transposer.transferItem(endechest, interface, 64, 1)
			if circuit >0 then
				transposer.transferItem(chest_with_circuits, endechest, 1, circuit)
				ready = true
			end
        else
			ready = true
		end
		if ready then 
			reactor = getAvailibleReactor()
			reactor:unload(reactor, true)
			transposer.transferItem(endechest, chest_with_circuits, 1, 27)
			for i = 23, 26 do
				transposer.transferItem(endechest, interface, 64, i)
			end
			reactor:loadRecipe()
		end
    else
        os.sleep(1)
    end
end