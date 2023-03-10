local component = require("component")
local sides = require("sides")

reactor_id = 1
ChemicalReactor = {}
ChemicalReactor.__index = ChemicalReactor

function load_params(_main_transpoer, _main_endechest, _interface)
    main_transpoer = _main_transpoer
    main_endechest = _main_endechest
    interface = _interface
end

function ChemicalReactor:new(primaryAddress, secondaryAddress)
    local reactor = {}
    setmetatable(reactor, ChemicalReactor)
    reactor.primary = component.proxy(primaryAddress)
    reactor.secondary = component.proxy(secondaryAddress)
    reactor.id = reactor_id
    reactor_id = reactor_id + 1
    for i = 2, 5 do
        local name = reactor.primary.getInventoryName(i)
        if name == "tile.enderchest" then
            reactor.primaryEnderChestSide = i
        elseif name == "gt.blockmachines" then
            reactor.primaryInputBusSide = i
        end
    end
    for i = 2, 5 do
        local name = reactor.secondary.getInventoryName(i)
        if name == "tile.enderchest" then
            reactor.secondaryEnderChestSide = i
        end
    end
    return reactor
end

local fluids_cell = {
    ["IC2:itemFluidCell0"] = true,
    ["extracells:certustank0"] = true,
    ["gregtech:gt.Volumetric_Flask0"] = true,
    ["miscutils:gt.Volumetric_Flask_8k0"] = true,
    ["gregtech:gt.metaitem.0132405"] = true,
    ["gregtech:gt.metaitem.0132406"] = true,
    ["gregtech:gt.metaitem.0132407"] = true,
    ["gregtech:gt.metaitem.0132408"] = true,
    ["gregtech:gt.metaitem.0132409"] = true,
    ["gregtech:gt.metaitem.01324010"] = true,
    ["gregtech:gt.metaitem.01324011"] = true,
    ["gregtech:gt.metaitem.01324012"] = true,
    ["gregtech:gt.metaitem.01324013"] = true
}

local item_filter = {
    ['gregtech:gt.metaitem.01:17035'] = true,
    ['gregtech:gt.metaitem.01:2026'] = true,
}

function ChemicalReactor:loadFluid(self, hatchNumber, slot)
    if hatchNumber == 1 then
        self.primary.transferItem(self.primaryEnderChestSide, sides.top, 64, slot)
    elseif hatchNumber == 2 then
        self.primary.transferItem(self.primaryEnderChestSide, sides.bottom, 64, slot)
    elseif hatchNumber == 3 then
        self.secondary.transferItem(self.secondaryEnderChestSide, sides.top, 64, slot)
    else
        self.secondary.transferItem(self.secondaryEnderChestSide, sides.bottom, 64, slot)
    end
end

function ChemicalReactor:loadRecipe()
    local items = self.primary.getAllStacks(self.primaryEnderChestSide).getAll()
    local hatchNumber = 1
    local outputs = {}
    local needs_cicle = false
    local items_counter = 0

    for i, item in pairs(items) do
        if item == nil 
        or item.name == nil 
        or self.primary.getSlotStackSize(self.primaryEnderChestSide, 1) ~= 0 and i ~= 0 then
            break
        end --Кончиась итерация предметов и уже появился след рецепт
        full_name = item.name .. item.damage
        slot = i + 1

        if fluids_cell[full_name] == nil then -- не жижа
            if items_counter > 14 then
                needs_cicle = true
            end
            self.primary.transferItem(self.primaryEnderChestSide, self.primaryInputBusSide, 64, slot)
            items_counter = items_counter + 1
        elseif outputs[item.fluid_name] ~= nil then -- жижа с повтором
            needs_cicle = true
        else -- жажа без повтора
            ChemicalReactor:loadFluid(self, hatchNumber, slot)
            outputs[item.fluid_name] = hatchNumber
            hatchNumber = hatchNumber + 1
        end
    end

    if needs_cicle then
        local flag = true
        while flag do -- ждёмс, пока рецепт весь закинется в химку
            os.sleep(1)
            if self.primary.getSlotStackSize(self.primaryEnderChestSide, 1) ~= 0 then
                return
            end
            flag = false
            for slot, item in pairs(items) do
                chest_slot = slot + 1
                if item ~= nil and chest_slot ~= 1 and chest_slot < 23 then
                    if self.primary.getSlotStackSize(self.primaryEnderChestSide, chest_slot) == 0 then
                        items[slot] = nil
                    else
                        full_name = item.name .. item.damage
                        if fluids_cell[full_name] == nil then -- не жижа
                            self.primary.transferItem(self.primaryEnderChestSide, self.primaryInputBusSide, 64, slot)
                            flag = true
                        else --жижа
                            ChemicalReactor:loadFluid(self, outputs[item.fluid_name], chest_slot)
                            flag = true
                        end
                    end
                end
                ChemicalReactor:unload(self, false)
            end
        end
    end
end

function ChemicalReactor:unload(self, unload_circuit)
    for slot= 1,2 do
        item = self.primary.getStackInSlot(self.primaryInputBusSide, slot)
        if item ~= nil then
            if item.name == "gregtech:gt.integrated_circuit" then 
                if unload_circuit == true then
                    self.primary.transferItem(self.primaryInputBusSide, self.primaryEnderChestSide, 1, slot, 27)
                end
            else
                if  unload_circuit == false and item_filter[item.name .. ":" .. item.damage] ~= nil then
                    
                else
                    self.primary.transferItem(self.primaryInputBusSide, self.primaryEnderChestSide, 1, slot, 26)
                end
            end
        end
    end

    self.secondary.transferItem(sides.bottom, self.secondaryEnderChestSide, 64, 2, 22)
    self.secondary.transferItem(sides.top, self.secondaryEnderChestSide, 64, 2, 23)
    self.primary.transferItem(sides.bottom, self.primaryEnderChestSide, 64, 2, 24)
    self.primary.transferItem(sides.top, self.primaryEnderChestSide, 64, 2, 25)
      
    for i = 22, 26 do
        main_transpoer.transferItem(main_endechest, interface, 64, i)
    end
end

function ChemicalReactor:isInputBusEmpty()
    for slot= 1,3 do
        local item = self.primary.getStackInSlot(self.primaryInputBusSide, slot)
        local is_empty = true

        if item ~= nil and item.name ~= "gregtech:gt.integrated_circuit" and item_filter[item.name .. ":" .. item.damage] == nil then 
            is_empty = false
        end

        return is_empty
    end
end

function ChemicalReactor:isInputHatchEmpty()
    return self.primary.getFluidInTank(sides.top, 1).amount == 0 and
        self.primary.getFluidInTank(sides.bottom, 1).amount == 0 and
        self.secondary.getFluidInTank(sides.top, 1).amount == 0 and
        self.secondary.getFluidInTank(sides.bottom, 1).amount == 0
end

return ChemicalReactor
