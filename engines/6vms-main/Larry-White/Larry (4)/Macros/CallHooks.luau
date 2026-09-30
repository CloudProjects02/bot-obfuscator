local CallHooks = {}

function CallHooks.new(State, Config)
	local Self = setmetatable({}, { __index = CallHooks })
	Self.State = State
	Self.Config = Config
	Self.AllCallsHook = nil
	Self.AllNamecallsHook = nil
	return Self
end

function CallHooks:HookAllCalls(Callback)
	if typeof(Callback) ~= "function" then
		error("invalid argument #1 to 'hookallcalls' (function expected)")
	end

	self.AllCallsHook = Callback
end

function CallHooks:HookAllNamecalls(Callback)
	if typeof(Callback) ~= "function" then
		error("invalid argument #1 to 'hookallnamecalls' (function expected)")
	end

	self.AllNamecallsHook = Callback
end

function CallHooks:InterceptCall(OldFunc, Path, ...)
	if not self.AllCallsHook then
		return nil, false
	end

	local S, Result = pcall(function(...)
		return table.pack(self.AllCallsHook(OldFunc, Path, ...))
	end, ...)

	if S and Result.n > 0 then
		return Result, true
	end

	return nil, false
end

function CallHooks:InterceptNamecall(Path, Method, ...)
	if not self.AllNamecallsHook then return end

	pcall(self.AllNamecallsHook, Path, Method, ...)
end

function CallHooks:HasCallHook()
	return self.AllCallsHook ~= nil
end

function CallHooks:HasNamecallHook()
	return self.AllNamecallsHook ~= nil
end

function CallHooks:CreateHandlers(MacroSystem)
	MacroSystem:Register("hookallcalls", function(Callback)
		self:HookAllCalls(Callback)
	end)

	MacroSystem:Register("hookallnamecalls", function(Callback)
		self:HookAllNamecalls(Callback)
	end)
end

function CallHooks:Clear()
	self.AllCallsHook = nil
	self.AllNamecallsHook = nil
end

return CallHooks