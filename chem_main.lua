local component = require("component")
local sides = require("sides")
local term = require("term")
local ChemicalReactor = dofile("ChemicalReactor.lua")
--local TFFT = dofile("TFFT.lua")
local main_transposer = component.proxy("2eefaa58-e253-4009-a36c-dcc080608cb4")

local reactors = {
    ChemicalReactor:new("857b8c28-a680-4d73-8b7b-6345c1c857ae", "3c452c8f-b55e-41bd-97e0-34a9b4b32ac4"),
    ChemicalReactor:new("9bc0aea0-a4dd-4c54-b9a5-982cd961e29c", "c51c2339-0275-4352-87c8-83b23d350c40"),
    ChemicalReactor:new("03a64490-7a6c-4b82-8497-05ebf3524ff9", "4f6d3a0d-3980-4b9f-9f16-6c2726923ee5"),
    ChemicalReactor:new("be17551c-5520-465f-8e9c-f4d4444512ef", "bb9728c9-9219-4332-8119-2494a7835c65"),
    ChemicalReactor:new("1e01d0a1-f5ab-46aa-874f-56730639f01b", "06d57347-1780-4ce0-88ac-7dd03a653e7e"),
}

local chest_with_circuits = sides.top
local main_enderchest = sides.bottom
local interface = sides.east

local balancer = 0

function check_chests_exist()
  if main_transposer == nil then
    print('Главный трансопзер не найден!')
    exit()
  elseif main_transposer.getInventoryName(chest_with_circuits) == nil then
    print('Сундук со схемами не найден!')
    exit()
  elseif main_transposer.getInventoryName(main_enderchest) == nil then
    print('Главный эндерсундук не найден!')
    exit()
  elseif main_transposer.getInventoryName(interface) == nil then
    print('Место, куда можно сбросить коблу и пустые капсулы не найдено!')
    exit()
  end
end

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
        os.sleep(0.5)
    end
end

term.clear()
term.write(" Запущена химия:\n\n")
check_chests_exist()
load_params(main_transposer, main_enderchest, interface)

while true do
    local first = main_transposer.getStackInSlot(main_enderchest, 1)
    if first ~= nil then
        if first.name == "minecraft:cobblestone" then
            local circuit = main_transposer.transferItem(main_enderchest, interface, 64, 1)
            if circuit > 0 then
                main_transposer.transferItem(chest_with_circuits, main_enderchest, 1, circuit)
            end
    end

    reactor = getAvailibleReactor()
    reactor:unload(reactor)
    main_transposer.transferItem(main_enderchest, chest_with_circuits, 1, 27)
    for i = 23, 26 do
      main_transposer.transferItem(main_enderchest, interface, 64, i)
    end
    reactor:loadRecipe()
        os.sleep(0.1)

    else
        os.sleep(0.3)
    end
end
