VineHandTool = {}
local VineHandTool_mt = Class(VineHandTool, HandTool)
VineHandTool.className = "VineHandTool"
--InitStaticObjectClass(VineHandTool, "VineHandTool", ObjectIds.OBJECT_VineHandTool)
ObjectIds.assignObjectClassObjectId(VineHandTool, "VineHandTool", 69)
HandTool.handToolTypes["vineHandTool"] = VineHandTool

g_xmlManager:addInitSchemaFunction(function ()
	local schema = HandTool.xmlSchema

	schema:setXMLSpecializationType("VineHandTool")
	schema:register(XMLValueType.NODE_INDEX, "handTool.vineHandTool.raycast#node", "Raycast node")
	schema:register(XMLValueType.FLOAT, "handTool.vineHandTool.raycast#maxDistance", "Max raycast distance", 1)
	schema:register(XMLValueType.FLOAT, "handTool.vineHandTool.raycast#maxTrailerDistance", "Max raycast distance for trailer searching", 2)
	--SoundManager.registerSampleXMLPaths(schema, "handTool.VineHandTool.sounds", "cut")
	schema:setXMLSpecializationType()
end)

function VineHandTool.new(isServer, isClient, customMt)
	local self = HandTool.new(isServer, isClient, customMt or VineHandTool_mt)

	return self
end

function VineHandTool:postLoad(xmlFile)
	if not VineHandTool:superClass().postLoad(self, xmlFile) then
		return false
	end
	self.raycast = {
		node = xmlFile:getValue("handTool.vineHandTool.raycast#node", nil, self.rootNode)
	}

	if self.raycast.node == nil then
		Logging.xmlWarning(xmlFile, "Missing vine detector raycast node")
	end

	self.raycast.maxDistance = xmlFile:getValue("handTool.vineHandTool.raycast#maxDistance", 1)
	self.raycast.maxTrailerDistance = xmlFile:getValue("handTool.vineHandTool.raycast#maxTrailerDistance", 2)
	self.raycast.isRaycasting = false
	self.raycast.currentNode = nil
	self.isVineDetectionActive = false
	
	self.activatePressed = false
	self.wasLastActivated = false
	
	self.fillType = FillType.GRAPE
	
	self.unloadRaycast = {
		found = false,
		object = nil,
		fillUnitIndex = nil
	}
	
	self.yieldContainer = {
		isSet = false,
		object = nil,
		fillUnitIndex = nil,
		distance = 0
	}
	self.containerMaxDistance = 8
	
	self.triggeredObjects = {}
	
	self.eventIdActivateUnload = ""
	self.inputActionActive = false
	
	return true
end

function VineHandTool:registerActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	--print("register")

	local _, eventId = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA, self, self.onInputActivateUnload, false, true, false, false)
	self.eventIdActivateUnload = eventId
	--local _, eventActivateId, collidingAction = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_HANDTOOL, self, self.onInputActivateTool, true, true, false, true, nil, true)
	--actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings
	--print_r(g_inputBinding:getEventsForActionName(InputAction.ACTIVATE_HANDTOOL))
	local activateAction = g_inputBinding:getEventsForActionName(InputAction.ACTIVATE_HANDTOOL)[1]
	if activateAction ~= nil then
		--print("changing original action event")
		--activateAction.targetObject = self
		activateAction.triggerAlways = false
		activateAction.triggerUp = true
		--activateAction.triggerDown = true
		--activateAction.callback = self.onInputActivateTool
	--else
		--print("adding own action event")
	--	local _, eventActivateId = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_HANDTOOL, self, self.onInputActivateTool, true, true, false, true, nil, true)
	end

	g_inputBinding:endActionEventsModification()
end

function VineHandTool:removeActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	g_inputBinding:removeActionEventsByTarget(self)
	--print("remove")
	local activateAction = g_inputBinding:getEventsForActionName(InputAction.ACTIVATE_HANDTOOL)[1]
	if activateAction ~= nil then -- restore original setup
		activateAction.triggerAlways = true
		activateAction.triggerUp = false
	end
	g_inputBinding:endActionEventsModification()
end


function VineHandTool:onInputActivateHandtool(_, inputValue)
	--print_r(self.baseInformation.currentHandtool)
	if self.baseInformation.currentHandtool.isVineDetectionActive ~= nil then
		--printf("input: %d", inputValue)
		if g_client ~= nil then
			g_client:getServerConnection():sendEvent(VineHandToolActivateEvent.new(self, self.baseInformation.currentHandtool.activatePressed))
		end
	end
end

Player.onInputActivateHandtool = Utils.appendedFunction(Player.onInputActivateHandtool, VineHandTool.onInputActivateHandtool)

function VineHandTool:onInputActivateUnload(_, inputValue)
	if inputValue == 1 and self.unloadRaycast.found then
		self:setYieldContainer(self.unloadRaycast.object, self.unloadRaycast.fillUnitIndex, self.unloadRaycast.distance)
		--printf("Object type: %s ---- fillUnitIndex type: %s", type(self.yieldContainer.object), type(self.yieldContainer.fillUnitIndex))
	end
end

--[[function VineHandTool:onInputActivateTool(_, inputValue)
	--printf("input %.1f", inputValue)
	if self.yieldContainer.isSet then
		if inputValue == 1 then
			self.activatedPressed = true
			if g_client ~= nil then
				g_client:getServerConnection():sendEvent(VineHandToolActivateEvent.new(self.player, self.activatedPressed))
			end
			--self:setYieldContainer(self.unloadRaycast.object, self.unloadRaycast.fillUnitIndex, self.unloadRaycast.distance)
			--printf("Object type: %s ---- fillUnitIndex type: %s", type(self.yieldContainer.object), type(self.yieldContainer.fillUnitIndex))
		elseif inputValue == 0 then
			self.activatedPressed = false
			if g_client ~= nil then
				g_client:getServerConnection():sendEvent(VineHandToolActivateEvent.new(self.player, self.activatedPressed))
			end
			--self:setYieldContainer(self.unloadRaycast.object, self.unloadRaycast.fillUnitIndex, self.unloadRaycast.distance)
			--printf("Object type: %s ---- fillUnitIndex type: %s", type(self.yieldContainer.object), type(self.yieldContainer.fillUnitIndex))
		end
	end
end]]

function VineHandTool:delete()
	VineHandTool:superClass().delete(self)
end

function VineHandTool:isBeingUsed()
	return self.activatePressed
end

function VineHandTool:update(dt, allowInput)
	VineHandTool:superClass().update(self, dt, allowInput)
	if self.raycast.node ~= nil then --self.isServer and
		local x, y, z = getWorldTranslation(self.raycast.node)
		local dx, dy, dz = localDirectionToWorld(self.raycast.node, 0, 0, 1)
		if self:getCanHarvest() and self.activatePressed then
			self.isVineDetectionActive = true
			
			if not self.raycast.isRaycasting then
				self.raycast.isRaycasting = true

				raycastAll(x, y, z, dx, dy, dz, "raycastCallbackVineDetection", self.raycast.maxDistance, self, nil, false, true)
			end
		elseif self.isVineDetectionActive then
			self.raycast.currentNode = nil
			self.raycast.placeable = nil
			self.raycast.isRaycasting = false

			self.isVineDetectionActive = false
			if self.yieldContainer.isSet and self.yieldContainer.object:getFillUnitFreeCapacity(self.yieldContainer.fillUnitIndex, self.fillType, g_farmManager:getFarmById(self.player.farmId)) <= 0 then
				g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_noMoreFreeCapacity"), g_fillTypeManager:getFillTypeByIndex(self.fillType).title), 4000)
			end
		end
		self.triggeredObjects = {}
		raycastAll(x, y, z, dx, dy, dz, "rayCastCallbackTrailerDetection", self.raycast.maxTrailerDistance, self, nil, false)
		if not self.activatePressed and self.wasLastActivated then
			self.wasLastActivated = false
		end
		--if self.activatePressed then
			--VineHandToolActivateEvent.sendEvent(self.player, true, self.isServer)
			--self.activatePressed = false
		--end
	end
end

function VineHandTool:updateTick(dt)
	if self.raycast.node ~= nil and self.isClient then
		if self.yieldContainer.isSet then
			self.yieldContainer.distance = calcDistanceFrom(self.raycast.node, self.yieldContainer.object.rootNode)
			if self.yieldContainer.distance > self.containerMaxDistance then
				self:setYieldContainer(nil, nil, 0)
				--self.yieldContainer.isSet = false
				--self.yieldContainer.object = nil
				--self.yieldContainer.fillUnitIndex = nil
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooFarAway"), 4000)
			end
		end
		if #self.triggeredObjects > 0 and self.triggeredObjects[1][1] ~= self.yieldContainer.object and not self.inputActionActive then
			self.unloadRaycast.found = true
			self.unloadRaycast.object = self.triggeredObjects[1][1]
			self.unloadRaycast.fillUnitIndex = self.triggeredObjects[1][2]
			self.unloadRaycast.distance = self.triggeredObjects[1][3]
			g_inputBinding:setActionEventText(self.eventIdActivateUnload, string.format(g_i18n:getText("action_setContainer"), self.unloadRaycast.object:getFullName()))
			g_inputBinding:setActionEventActive(self.eventIdActivateUnload, true)
			self.inputActionActive = true
		elseif #self.triggeredObjects == 0 and (self.inputActionActive or self.unloadRaycast.found) then
			g_inputBinding:setActionEventActive(self.eventIdActivateUnload, false)
			self.unloadRaycast.found = false
			self.unloadRaycast.object = nil
			self.unloadRaycast.fillUnitIndex = nil
			self.unloadRaycast.distance = 0
			self.inputActionActive = false
		elseif #self.triggeredObjects > 0 and self.yieldContainer.isSet and self.triggeredObjects[1][1] == self.yieldContainer.object and self.inputActionActive then
			g_inputBinding:setActionEventActive(self.eventIdActivateUnload, false)
		end
	end
end

function VineHandTool:getCanHarvest()
	if self.yieldContainer.isSet and self.yieldContainer.object:getFillUnitFreeCapacity(self.yieldContainer.fillUnitIndex, self.fillType, g_farmManager:getFarmById(self.player.farmId)) <= 0 then
		return false
	end
	if self.wasLastActivated then
		return false
	end
	return true
end

function VineHandTool:rayCastCallbackTrailerDetection(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId)
	if hitActorId ~= nil then
		local object = g_currentMission:getNodeObject(hitActorId)

		if VehicleDebug.state == VehicleDebug.DEBUG then
			DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, 0, 0, 1, 0, 1, 0, string.format("hitActorId %s (%s); hitShape %s (%s); object %s", getName(hitActorId), hitActorId, getName(hitShapeId), hitShapeId, tostring(object)))
		end

		local validObject = object ~= nil and object ~= self

		if validObject then
			if object.getFirstValidFillUnitToFill ~= nil then
				local fillUnitIndex = object:getFirstValidFillUnitToFill(self.fillType)

				if fillUnitIndex ~= nil then
					table.insert(self.triggeredObjects, {object, fillUnitIndex, distance})
				end
			end
		end

		return true
	end
end

function VineHandTool:setYieldContainer(object, fillUnitIndex, distance, noEventSend)
	self.yieldContainer.isSet = object ~= nil
	self.yieldContainer.object = object
	if object ~= nil and fillUnitIndex == nil then
		self.yieldContainer.fillUnitIndex = object:getFirstValidFillUnitToFill(self.fillType)
	else
		self.yieldContainer.fillUnitIndex = fillUnitIndex
	end
	self.yieldContainer.distance = distance
	--print("Set yieldContainer to "..tostring(object))
	VineHandToolStateEvent.sendEvent(self.player, self.yieldContainer.object, noEventSend)
end

function VineHandTool:raycastCallbackVineDetection(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
	if hitActorId ~= 0 then
		--if VehicleDebug.state == VehicleDebug.DEBUG then
		--	DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, 0, 0, 1, 0, 1, 0, string.format("hitActorId %s (%s); hitShape %s (%s)", getName(hitActorId), hitActorId, getName(hitShapeId), hitShapeId))
		--end

		if not self.raycast.isRaycasting then
			self.raycast.currentNode = nil
			self.raycast.placeable = nil
			self.raycast.isRaycasting = false

			return false
		end

		local placeable = g_currentMission.vineSystem:getPlaceable(hitActorId)

		if placeable == nil or g_currentMission.nodeToObject[hitActorId] == self then
			if isLast then
				self.raycast.currentNode = nil
				self.raycast.placeable = nil
				self.raycast.isRaycasting = false

				return false
			end

			return true
		end
		
		if self:handleVinePlaceable(hitActorId, placeable, x, y, z, distance) then
			self.raycast.isRaycasting = false

			return false
		end
		
		return true
	else
		self.raycast.currentNode = nil
		self.raycast.placeable = nil
		self.raycast.isRaycasting = false
	end
end

function VineHandTool:handleVinePlaceable(node, placeable, x, y, z)
	if placeable ~= nil and self.yieldContainer.isSet then -- check if yield container is set
		--local startX, startZ, widthX, widthZ, heightX, heightZ = placeable:getVineAreaByNode(node)
		--placeable:harvestVine(node, widthX, y, widthZ, heightX, y, heightZ, self.harvestCallback, self)
		placeable:harvestVine(node, x-0.3, y-0.1, z-0.3, x+0.3, y+0.1, z+0.3, self.harvestCallback, self)
	elseif placeable ~= nil and not self.yieldContainer.isSet then -- if not, try to prepare vine
		local area = placeable:prepareVine(node, x-0.4, y-0.1, z-0.4, x+0.4, y+0.1, z+0.4)
	end

	return true
end


function VineHandTool:harvestCallback(placeable, area, totalArea, weedFactor, sprayFactor, plowFactor, sectionLength)
	--print("harvestCallback")
	--local spec = self.spec_vineCutter
	local limeFactor = 1
	local stubbleTillageFactor = 1
	local rollerFactor = 1
	local beeYieldBonusPerc = 0
	local multiplier = g_currentMission:getHarvestScaleMultiplier(FruitType.GRAPE, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleTillageFactor, rollerFactor, beeYieldBonusPerc)*1.1
	local realArea = area * multiplier
	local farmId = placeable:getOwnerFarmId()

	--spec.currentCombineVehicle:addCutterArea(area, realArea, FruitType.GRAPE, spec.outputFillTypeIndex, 0, nil, farmId, 1)

	local stats = g_currentMission:farmStats(farmId)

	--if spec.inputFruitTypeIndex == FruitType.GRAPE then
	stats:updateStats("harvestedGrapes", sectionLength)
	--elseif spec.inputFruitTypeIndex == FruitType.OLIVE then
	--	stats:updateStats("harvestedOlives", sectionLength)
	--[[else
		local ha = MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm())

		stats:updateStats("threshedHectares", ha)
		stats:updateStats("workedHectares", ha)
	end]]
	self.yieldContainer.object:addFillUnitFillLevel(g_farmManager:getFarmById(self.player.farmId), self.yieldContainer.fillUnitIndex, realArea, self.fillType, ToolType.UNDEFINED, nil)
	self.wasLastActivated = true
	--local outputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(FruitType.GRAPE)
	--self.fillLevel = self.fillLevel + realArea
end

function VineHandTool:draw(dt)
	if self.yieldContainer.isSet then
		local x,y = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.BACKGROUND))
		local scale = g_gameSettings:getValue("uiScale")
		local textSize = g_currentMission.inGameMenu.hud.fillLevelsDisplay.fillLevelTextSize or 0.015
		local capacity = self.yieldContainer.object:getFillUnitCapacity(self.yieldContainer.fillUnitIndex)
		local fillLevel = self.yieldContainer.object:getFillUnitFillLevel(self.yieldContainer.fillUnitIndex)
		
		setTextBold(true)
		if self.yieldContainer.distance > self.containerMaxDistance*0.75 then
			setTextColor(1,0,0,1)
		end
		renderText(1 - g_safeFrameOffsetX - 2 * x * scale, g_safeFrameOffsetY + y * scale + textSize*1.1, textSize*1.1, string.format("%s (%d m)", self.yieldContainer.object:getName(), self.yieldContainer.distance))
		setTextColor(1,1,1,1)
		setTextBold(false)
		renderText(1 - g_safeFrameOffsetX - 2 * x * scale, g_safeFrameOffsetY + y * scale, textSize, string.format("%d (%d %%)", fillLevel, math.min(fillLevel/capacity, 1)*100))
	end
	return true
end

