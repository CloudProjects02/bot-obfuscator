local StringUtil = require("../Utils/String")

local CoroutineLib = {}
local MaxWrapDepth = 198
local WrapDepthMap = setmetatable({}, { __mode = "k" })

function CoroutineLib.Build(Proxy, State, Emitter, Beautifier, Scope, Config, LockedEnv)
	local function SpyReturn(Method, ...)
		local Value = `coroutine.{Method}({Beautifier:BeautifyTuple(...)})`
		local Var = Scope:GenerateName("co", Method)
		return Proxy:MultiSpy(Var, Value, 2)
	end

	local function WrapFunc(Func)
		if typeof(Func) ~= "function" then return Func end
		if LockedEnv and typeof(setfenv) == "function" then
			local Ok, Wrapped = pcall(setfenv, Func, LockedEnv)
			if Ok and typeof(Wrapped) == "function" then
				return Wrapped
			end
		end
		return Func
	end

	local Lib = {}

	Lib.create = function(Func)
		if State:IsInternal(Func) then
			return SpyReturn("create", Func)
		end

		if typeof(Func) ~= "function" then
			error("invalid argument #1 to 'coroutine.create' (function expected)")
		end

		local Var = Scope:AddVar("co", "create", `coroutine.create({Beautifier:Beautify(Func)})`, "__call")
		return coroutine.create(WrapFunc(Func))
	end

	Lib.wrap = function(Func)
		if State:IsInternal(Func) and typeof(Func) ~= "function" then
			return SpyReturn("wrap", Func)
		end

		if typeof(Func) ~= "function" then
			error("invalid argument #1 to 'coroutine.wrap' (function expected)")
		end

		local ParentDepth = tonumber(WrapDepthMap[Func]) or 0
		local Depth = ParentDepth + 1
		local Thread = coroutine.create(WrapFunc(Func))
		local Wrapped = function(...)
			if Depth > MaxWrapDepth then
				error("C stack overflow", 0)
			end

			local ResumeResult = table.pack(coroutine.resume(Thread, ...))
			local Success = ResumeResult[1]
			if not Success then
				error(ResumeResult[2], 0)
			end
			return table.unpack(ResumeResult, 2, ResumeResult.n)
		end
		WrapDepthMap[Wrapped] = Depth
		return Wrapped
	end

	Lib.resume = function(Thread, ...)
		if State:IsInternal(Thread) then
			return SpyReturn("resume", Thread, ...)
		end

		if typeof(Thread) ~= "thread" then
			error("invalid argument #1 to 'coroutine.resume' (thread expected)")
		end

		return coroutine.resume(Thread, ...)
	end

	Lib.yield = function(...)
		return coroutine.yield(...)
	end

	Lib.status = function(Thread)
		if State:IsInternal(Thread) then
			return SpyReturn("status", Thread)
		end

		if typeof(Thread) ~= "thread" then
			error("invalid argument #1 to 'coroutine.status' (thread expected)")
		end

		return coroutine.status(Thread)
	end

	Lib.running = function()
		return coroutine.running()
	end

	Lib.isyieldable = function()
		return coroutine.isyieldable()
	end

	Lib.close = function(Thread)
		if State:IsInternal(Thread) then
			return SpyReturn("close", Thread)
		end

		return coroutine.close(Thread)
	end

	return Lib
end

return CoroutineLib