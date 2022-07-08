local component = require("component")
local sides = require("sides")
--local transposer_base, endechest_base, out_side_base

ChemicalReactor = {}
ChemicalReactor.__index = ChemicalReactor

function load_params(_transposer_base, _endechest_base, _out_side_base)
  transposer_base = _transposer_base
  endechest_base = _endechest_base
  out_side_base = _out_side_base
end 

function ChemicalReactor:new(primaryAddress, secondaryAddress)
    local reactor = {}
    setmetatable(reactor, ChemicalReactor)
    reactor.primary = component.proxy(primaryAddress)
    reactor.secondary = component.proxy(secondaryAddress)
    for i = 2, 5 do
        name = reactor.primary.getInventoryName(i)
        if name == "tile.enderchest" then
            reactor.primaryEnderChestSide = i
        else
            if name == "gt.blockmachines" then
                reactor.primaryInputBusSide = i
            end
        end
    end
    for i = 2, 5 do
        name = reactor.secondary.getInventoryName(i)
        if name == "tile.enderchest" then
            reactor.secondaryEnderChestSide = i
        end
    end
    return reactor
end


local fluids_cell = {
    ["IC2:itemFluidCell0.0"] = true,
    ["extracells:certustank0.0"] = true,
    ["gregtech:gt.Volumetric_Flask0.0"] = true,
    ["miscutils:gt.Volumetric_Flask_8k0.0"] = true,
    ["gregtech:gt.metaitem.0132405.0"] = true,
    ["gregtech:gt.metaitem.0132406.0"] = true,
    ["gregtech:gt.metaitem.0132407.0"] = true,
    ["gregtech:gt.metaitem.0132408.0"] = true,
    ["gregtech:gt.metaitem.0132409.0"] = true,
    ["gregtech:gt.metaitem.01324010.0"] = true,
    ["gregtech:gt.metaitem.01324011.0"] = true,
    ["gregtech:gt.metaitem.01324012.0"] = true,
    ["gregtech:gt.metaitem.01324013.0"] = true,
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
    items = self.primary.getAllStacks(self.primaryEnderChestSide).getAll()
    hatchNumber = 1
    outputs = {}
    needs_cicle = false
    items_counter = 0
    
    for i, item in pairs(items) do
        if item == nil or item.name ==nil or self.primary.getSlotStackSize(self.primaryEnderChestSide, 1) ~= 0  and i ~=0 then break end --Кончиась итерация предметов и уже появился след рецепт
        full_name = item.name .. item.damage
        slot = i+1
        
        if fluids_cell[full_name] == nil then -- не жижа 
            if items_counter >14 then 
                needs_cicle = true
                ::continue::
            end
                self.primary.transferItem(self.primaryEnderChestSide, self.primaryInputBusSide, 64, slot) 
                items_counter = items_counter+1
        elseif outputs[item.fluid_name] ~= nil then -- жижа с повтором              
                needs_cicle = true
                ::continue::
        else -- жажа без повтора
            ChemicalReactor:loadFluid(self, hatchNumber, slot)
            outputs[item.fluid_name] = hatchNumber
            hatchNumber = hatchNumber + 1       
        end
    end
    
    if needs_cicle then
    flag = true
         while flag do-- ждёмс, пока рецепт весь закинеться в химку
                os.sleep(1)
                if self.primary.getSlotStackSize(self.primaryEnderChestSide, 1) ~= 0 then return end
                flag = false
                for slot, item in pairs(items) do 
          chest_slot = slot+1
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

function ChemicalReactor:unload(self, circuit)
  if circuit then
    self.primary.transferItem(self.primaryInputBusSide, self.primaryEnderChestSide, 1, 1, 27)
  end
    self.primary.transferItem(sides.top, self.primaryEnderChestSide, 64, 2, 26)
    self.primary.transferItem(sides.bottom, self.primaryEnderChestSide, 64, 2, 25)
    self.secondary.transferItem(sides.top, self.secondaryEnderChestSide, 64, 2, 24)
    self.secondary.transferItem(sides.bottom, self.secondaryEnderChestSide, 64, 2, 23)
    for i = 23, 26 do
        transposer_base.transferItem(endechest_base, out_side_base, 64, i)
    end
end

function ChemicalReactor:isInputBusEmpty()
    item = self.primary.getStackInSlot(self.primaryInputBusSide, 1)
    if item == nil  or 
       item.name == "gregtech:gt.integrated_circuit" and self.primary.getStackInSlot(self.primaryInputBusSide, 2) == nil
    then return true 
    else return false 
    end
  
end

function ChemicalReactor:isInputHatchEmpty()
   return self.primary.getFluidInTank(sides.top, 1).amount == 0 and self.secondary.getFluidInTank(sides.top, 1).amount == 0
end

return ChemicalReactor
