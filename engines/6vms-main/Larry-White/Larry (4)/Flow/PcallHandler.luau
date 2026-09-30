local Constants = require("../Data/Constants")
local AntiTamper = require("../Env/AntiTamper")
local IdentityUtil = require("../Utils/Identity")
local ErrorSanitizer = require("../Utils/ErrorSanitizer")
local DataTypes = require("../Roblox/DataTypes")
local VmMutationBridge = require("../Core/VmMutationBridge")

local PcallHandler = {}

local function ConsumeReadonlyViolationFromEnv(Func)
	if typeof(Func) ~= "function" or typeof(getfenv) ~= "function" then
		return nil
	end

	local Ok, FuncEnv = pcall(getfenv, Func)
	if not Ok or typeof(FuncEnv) ~= "table" then
		return nil
	end

	local Game = rawget(FuncEnv, "game")
	if typeof(Game) ~= "table" or typeof(Game.GetService) ~= "function" then
		return nil
	end

	local ServiceOk, LogService = pcall(Game.GetService, Game, "LogService")
	if not ServiceOk or typeof(LogService) ~= "table" or typeof(LogService.GetProperty) ~= "function" then
		return nil
	end

	local Message = LogService:GetProperty("_LarryReadonlyViolation")
	if typeof(Message) ~= "string" then
		return nil
	end

	if typeof(LogService.SetProperty) == "function" then
		LogService:SetProperty("_LarryReadonlyViolation", nil)
	end

	return Message
end

local function ShouldSimulateStackOverflow(Func, CallArgs, Results)
	if typeof(Func) ~= "function" then
		return false
	end

	if typeof(CallArgs) ~= "table" or CallArgs.n ~= 1 then
		return false
	end

	local RequestedDepth = CallArgs[1]
	if typeof(RequestedDepth) ~= "number" or RequestedDepth % 1 ~= 0 then
		return false
	end
	if RequestedDepth < 1400 then
		return false
	end

	if typeof(Results) ~= "table" or Results[1] ~= true then
		return false
	end
	if Results.n < 2 or Results[2] ~= 0 then
		return false
	end

	local OkArity, ParamCount, HasVarargs = pcall(debug.info, Func, "a")
	if not OkArity or ParamCount ~= 1 or HasVarargs then
		return false
	end

	local OkSource, Source = pcall(debug.info, Func, "s")
	if not OkSource or typeof(Source) ~= "string" then
		return false
	end
	if Source == "[C]" then
		return false
	end
	if string.find(Source, "LocalScript", 1, true) == nil then
		return false
	end

	return true
end

function PcallHandler.new(Proxy, State, Emitter, Beautifier, Scope, Config)
	local Self = setmetatable({}, { __index = PcallHandler })
	Self.Proxy = Proxy
	Self.State = State
	Self.Emitter = Emitter
	Self.Beautifier = Beautifier
	Self.Scope = Scope
	Self.Config = Config
	Self.PreventedErrors = {}
	Self.ForcedErrors = {}
	Self.PcallCounter = 0
	local EmitLimit = tonumber(Config.max_pcall_emits)
	if EmitLimit == nil then
		EmitLimit = 12
	end
	Self.MaxPcallEmits = math.max(0, math.floor(EmitLimit))
	return Self
end

function PcallHandler:NextPcallId()
	self.PcallCounter += 1
	return self.PcallCounter
end

function PcallHandler:PreventError(PcallId)
	self.PreventedErrors[PcallId] = true
end

function PcallHandler:ForceError(PcallId, Message)
	self.ForcedErrors[PcallId] = Message or "forced error"
end

function PcallHandler:Execute(Func, ...)
	local State = self.State
	local Proxy = self.Proxy
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier
	local Scope = self.Scope
	local Config = self.Config

	local PcallId = self:NextPcallId()

	local InternalPath = State:IsInternal(Func)
	local TracePcall = not (typeof(InternalPath) == "string" and string.sub(InternalPath, 1, 7) == "__larry")
	local FuncStr = InternalPath
	if FuncStr == nil then
		local Reconstruction = State.AstReconstruction
		if typeof(Reconstruction) == "table" and typeof(Reconstruction.TakePcallCallback) == "function" then
			FuncStr = Reconstruction:TakePcallCallback()
		end
	end
	if FuncStr == nil then
		FuncStr = Beautifier:Beautify(Func, State.CurrentIndent + 1, {
			ShallowAsync = true,
		})
	end
	if typeof(FuncStr) == "string" and string.sub(FuncStr, 1, 7) == "__larry" then
		TracePcall = false
	end
	local ArgStr = Beautifier:BeautifyTuple(...)
	local CallValue = ArgStr ~= "" and `pcall({FuncStr}, {ArgStr})` or `pcall({FuncStr})`
	if TracePcall then
		local SuccessTrace = Scope:GenerateName("pcall", "pcallSuccess")
		local ResultTrace = Scope:GenerateName("pcall", "pcallResult")
		Emitter:Append(`local {SuccessTrace}, {ResultTrace} = {CallValue}`)
		State:Define(SuccessTrace, `select(1, {CallValue})`, "__call")
		State:Define(ResultTrace, `select(2, {CallValue})`, "__call")
	end

	local BlockStart = #State.Output + 1

	local Forced = self.ForcedErrors[PcallId]
	if Forced then
		local SuccessVar = Scope:AddVar("pcall", "success", "false", "__call")
		local ErrVar = Scope:AddVar("pcall", "err", Beautifier:Beautify(Forced), "__call")

		return false, Forced
	end

	local CallArgs = table.pack(...)

	local function ExecuteWithVmMutation(Target, ...)
		if typeof(Target) ~= "function" then
			return pcall(Target, ...)
		end

		local Args = table.pack(...)

		local Vm = VmMutationBridge.Resolve()
		if Vm == nil then
			return pcall(Target, table.unpack(Args, 1, Args.n))
		end

		local Hook = Vm.hooks and Vm.hooks[Target] or nil
		if typeof(Hook) == "function" then
			return pcall(Hook, table.unpack(Args, 1, Args.n))
		end

		local UpvalueOverride = Vm.upvalues and Vm.upvalues[Target] or nil
		if typeof(UpvalueOverride) == "function" then
			return pcall(UpvalueOverride, table.unpack(Args, 1, Args.n))
		end
		if UpvalueOverride ~= nil and typeof(UpvalueOverride) ~= "table" then
			return true, UpvalueOverride
		end
		if typeof(UpvalueOverride) == "table" then
			local Candidate = UpvalueOverride[1]
			if Candidate == nil then
				for Key, Value in next, UpvalueOverride do
					if typeof(Key) == "number" then
						Candidate = Value
						break
					end
				end
			end
			if typeof(Candidate) == "function" then
				return pcall(Candidate, table.unpack(Args, 1, Args.n))
			end
			if Candidate ~= nil then
				return true, Candidate
			end
		end

		local Success, Packed = pcall(function()
			local Ret = table.pack(Target(table.unpack(Args, 1, Args.n)))

			local Forced = Vm.force_return and Vm.force_return[Target] or nil
			if Forced ~= nil then
				Vm.force_return[Target] = nil
				Ret[1] = Forced
				if Ret.n < 1 then
					Ret.n = 1
				end
			end

			local ConstantOverride = Vm.constants and Vm.constants[Target] or nil
			if ConstantOverride ~= nil then
				if typeof(ConstantOverride) == "table" then
					local Candidate = ConstantOverride[1]
					if Candidate == nil then
						for Key, Value in next, ConstantOverride do
							if typeof(Key) == "number" then
								Candidate = Value
								break
							end
						end
					end
					Ret[1] = Candidate
				else
					Ret[1] = ConstantOverride
				end
				if Ret.n < 1 then
					Ret.n = 1
				end
			end

			return Ret
		end)

		if not Success then
			return false, Packed
		end

		return true, table.unpack(Packed, 1, Packed.n)
	end

	local Results = table.pack(ExecuteWithVmMutation(Func, table.unpack(CallArgs, 1, CallArgs.n)))
	if ShouldSimulateStackOverflow(Func, CallArgs, Results) then
		Results[1] = false
		Results[2] = "stack overflow"
		Results.n = 2
	end
	local ReadonlyViolation = typeof(DataTypes.ConsumeReadonlyViolation) == "function" and DataTypes.ConsumeReadonlyViolation() or nil
	if typeof(ReadonlyViolation) ~= "string" then
		ReadonlyViolation = ConsumeReadonlyViolationFromEnv(Func)
	end
	if Results[1] == true and typeof(ReadonlyViolation) == "string" then
		Results[1] = false
		Results[2] = ReadonlyViolation
		Results.n = 2
	end

	local Success = Results[1]
	local Prevented = self.PreventedErrors[PcallId]

	if not Success and Prevented then
		Success = true
		Results[1] = true
		Results[2] = nil
	end

	if not TracePcall then
		return table.unpack(Results, 1, Results.n)
	end

	if not Success then
		local ErrMsg = Results[2]

		if typeof(ErrMsg) ~= "string" then
			ErrMsg = tostring(ErrMsg)
		end

		ErrMsg = AntiTamper.WrapPcallError(ErrMsg, IdentityUtil.TraceId)
		ErrMsg = ErrorSanitizer.Sanitize(ErrMsg)

		local IsTooManyOps = typeof(ErrMsg) == "string" and string.find(ErrMsg, "Too many operations")

		if IsTooManyOps then
			Results[1] = true
		end

		local ErrVar = Scope:AddVar("pcall", "err", Beautifier:Beautify(ErrMsg), "__call")

		return Results[1], ErrMsg
	end

	local Out = { true }
	local EmitLimit = self.MaxPcallEmits or 0
	local TotalValues = math.max(0, Results.n - 1)
	local EmittedValues = 0

	for I = 2, Results.n do
		local Val = Results[I]
		if EmittedValues < EmitLimit then
			if Val ~= nil then
				EmittedValues += 1
				local VarName = Scope:AddVar("pcall", "ret", Beautifier:Beautify(Val), "__call")
				State:RegisterInternal(Val, VarName)
			end
		end

		table.insert(Out, Val)
	end

	local BlockEnd = #State.Output

	Scope:FixScopes(BlockStart, BlockEnd)

	return unpack(Out)
end

function PcallHandler:ExecuteXpcall(Func, ErrHandler, ...)

	local State = self.State
	local Proxy = self.Proxy
	local Emitter = self.Emitter
	local Beautifier = self.Beautifier
	local Scope = self.Scope

	local FuncStr = State:IsInternal(Func) or Beautifier:Beautify(Func)
	local HandlerStr = State:IsInternal(ErrHandler) or Beautifier:Beautify(ErrHandler)

	local Results = table.pack(xpcall(Func, ErrHandler, ...))

	local Out = {}
	local EmitLimit = self.MaxPcallEmits or 0
	if Results.n > EmitLimit and typeof(Emitter) == "table" and typeof(Emitter.Append) == "function" then
		Emitter:Append(``)
	end

	for I = 1, Results.n do
		local Val = Results[I]
		if I <= EmitLimit then
			local VarName = Scope:AddVar("xpcall", "ret", Beautifier:Beautify(Val), "__call")
			if Val ~= nil then
				State:RegisterInternal(Val, VarName)
			end
		end

		table.insert(Out, Val)
	end

	return unpack(Out)
end

function PcallHandler:Build()
	return {
		pcall = function(F, ...) return self:Execute(F, ...) end,
		xpcall = function(F, H, ...) return self:ExecuteXpcall(F, H, ...) end,
	}
end

return PcallHandler