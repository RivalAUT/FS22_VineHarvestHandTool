VineHandToolActivateEvent = {}
local VineHandToolActivateEvent_mt = Class(VineHandToolActivateEvent, Event)

EventIds.assignEventObjectId(VineHandToolActivateEvent, "VineHandToolActivateEvent", 476)

function VineHandToolActivateEvent.emptyNew()
	local self = Event.new(VineHandToolActivateEvent_mt)

	return self
end

function VineHandToolActivateEvent.new(player, isActive)
	local self = VineHandToolActivateEvent.emptyNew()
	self.player = player
	self.isActive = isActive

	return self
end

function VineHandToolActivateEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.isActive = streamReadBool(streamId)
	self:run(connection)
end

function VineHandToolActivateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.isActive)
end

function VineHandToolActivateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	local currentTool = self.player.baseInformation.currentHandtool
	if currentTool ~= nil and currentTool.activatePressed ~= nil then
		currentTool.activatePressed = self.isActive
		--print("set active to ".. tostring(self.isActive))
	end
end

function VineHandToolActivateEvent.sendEvent(player, isActive, noEventSend)
	local currentTool = player.baseInformation.currentHandtool
	--print("sendActivateEvent 1")
	if currentTool ~= nil and (noEventSend == nil or noEventSend == false) then
		--print("sendActivateEvent 2")
		if g_server ~= nil then
			g_server:broadcastEvent(VineHandToolActivateEvent.new(player, isActive), nil, nil, player)
			--print("broadcastActivateEvent")
		else
			g_client:getServerConnection():sendEvent(VineHandToolActivateEvent.new(player, isActive))
			--print("g_client:sendActivateEvent")
		end
	end
end
