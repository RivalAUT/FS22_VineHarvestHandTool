VineHandToolStateEvent = {}
local VineHandToolStateEvent_mt = Class(VineHandToolStateEvent, Event)

EventIds.assignEventObjectId(VineHandToolStateEvent, "VineHandToolStateEvent", 475)

function VineHandToolStateEvent.emptyNew()
	local self = Event.new(VineHandToolStateEvent_mt)

	return self
end

function VineHandToolStateEvent.new(player, targetObject)
	local self = VineHandToolStateEvent.emptyNew()
	self.player = player
	self.targetObject = targetObject

	return self
end

function VineHandToolStateEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	if streamReadBool(streamId) then
		self.targetObject = NetworkUtil.readNodeObject(streamId)
	else
		self.targetObject = nil
	end
	self:run(connection)
end

function VineHandToolStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.targetObject ~= nil)
	if self.targetObject ~= nil then
		NetworkUtil.writeNodeObject(streamId, self.targetObject)
	end
end

function VineHandToolStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool
	if currentTool ~= nil and currentTool.setYieldContainer ~= nil then
		currentTool:setYieldContainer(self.targetObject, nil, 0, true)
	end
end

function VineHandToolStateEvent.sendEvent(player, targetObject, noEventSend)
	local currentTool = player.baseInformation.currentHandtool
	--print("sendEvent 1")
	if currentTool ~= nil and (noEventSend == nil or noEventSend == false) then -- and currentTool.yieldContainer.object ~= targetObject
		--print("sendEvent 2")
		if g_server ~= nil then
			g_server:broadcastEvent(VineHandToolStateEvent.new(player, targetObject), nil, nil, player)
			--print("broadcastEvent")
		else
			g_client:getServerConnection():sendEvent(VineHandToolStateEvent.new(player, targetObject))
			--print("g_client:sendEvent")
		end
	end
end
