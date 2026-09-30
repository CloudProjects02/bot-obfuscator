local fs = require("@lune/fs")

local Config = require("../Config")
local Tracer = require("./Tracer")
local VmCallShim = require("./VmCallShim")
local Unparser = require("../CodeGen/Unparser")
local Beautifier = require("../CodeGen/Beautifier")
local Logger = require("../Utils/Logger")
local StringUtil = require("../Utils/String")
local LuauErrorFormatter = require("../Utils/LuauErrorFormatter")

local Decoder = {}

local StageOrder = {
	"read_source",
	"unparse",
	"vm_shim",
	"tracer",
	"retry_tracer",
	"sanitize_error",
	"write_output",
}

local function CloneConfig(SourceCfg)
	local Out = {}
	for Key, Value in next, SourceCfg do
		if typeof(Value) == "table" then
			local Sub = {}
			for SubKey, SubValue in next, Value do
				Sub[SubKey] = SubValue
			end
			Out[Key] = Sub
		else
			Out[Key] = Value
		end
	end
	return Out
end

local function HasRetryErrorSignature(Msg)
	return string.find(Msg, "attempt to call a nil value", 1, true) ~= nil
		or string.find(Msg, "invalid 'for' limit", 1, true) ~= nil
end

local function StripTracerRuntimeError(Code)
	if typeof(Code) ~= "string" then
		return Code, false
	end

	local LowerCode = string.lower(Code)
	local Start = string.find(LowerCode, "\nerror(\"[string \\\"", 1, true)
	local Offset = 1

	if not Start then
		Start = string.find(LowerCode, "error(\"[string \\\"", 1, true)
		Offset = 0
	end

	if not Start then
		return Code, false
	end

	local TailStart = Start + Offset
	local Prefix = string.sub(Code, 1, TailStart - 1)
	local Tail = string.sub(LowerCode, TailStart)

	if StringUtil.Strip(Prefix) == "" then
		return Code, false
	end

	if string.find(Tail, "core/tracer:", 1, true) == nil then
		return Code, false
	end

	return StringUtil.Strip(Prefix, true), true
end

local function NeedsSpyExecRetry(RunSuccess, Code, UsedSpyExecOnly)
	if not UsedSpyExecOnly then
		return false
	end

	if not RunSuccess then
		if typeof(Code) ~= "string" then
			return false
		end
		local Msg = string.lower(Code)
		return HasRetryErrorSignature(Msg)
	end

	if typeof(Code) ~= "string" then
		return false
	end

	local Msg = string.lower(Code)
	if string.sub(Code, 1, 6) == "error(" then
		return HasRetryErrorSignature(Msg)
	end

	if string.find(Msg, "error(\"[string \\\"", 1, true) == nil then
		return false
	end

	return HasRetryErrorSignature(Msg)
end

local function ShouldApplyVmShim(Cfg)
	if Cfg.experimental_vm_shim then
		return true
	end

	local Mode = string.lower(tostring(Cfg.vm_mutation_mode or ""))
	if Mode == "off" or Mode == "disabled" or Mode == "none" then
		return false
	end
	if Mode == "strict" or Mode == "compat" then
		return true
	end

	local Profile = string.lower(tostring(Cfg.profile or ""))
	return Profile == "fidelity"
end

local function BeginStage()
	return os.clock()
end

local function EndStage(Timings, Key, StartedAt)
	Timings[Key] = (Timings[Key] or 0) + (os.clock() - StartedAt)
end

local function PrintTimingsIfEnabled(Cfg, Timings)
	if not Cfg.diagnostics then
		return
	end

	for _, Key in ipairs(StageOrder) do
		local Duration = Timings[Key]
		if Duration and Duration > 0 then
			Logger.Print(`[{Key}]`, string.format("%.6fs", Duration))
		end
	end
end

function Decoder.Decode(File, Cfg)
	Cfg = Cfg or Config.Settings
	local Timings = {}

	local OutFile = Cfg.outfile or "out2.lua"

	local ReadStart = BeginStage()
	local Source = fs.readFile(File)
	EndStage(Timings, "read_source", ReadStart)

	local ProcessedSource = Source
	local RuntimeCfg = CloneConfig(Cfg)
	RuntimeCfg.__original_source = Source

	if not Cfg.raw then
		local UnparseStart = BeginStage()
		local SessionUnparser = Unparser.new(Cfg)
		local Obfuscated = SessionUnparser:Obfuscate(ProcessedSource)

		if Obfuscated then
			ProcessedSource = Obfuscated
		end
		EndStage(Timings, "unparse", UnparseStart)
	end

	if ShouldApplyVmShim(Cfg) then
		local ShimStart = BeginStage()
		local Shimmed, Changed = VmCallShim.Apply(ProcessedSource)
		if Changed then
			ProcessedSource = Shimmed
		end
		EndStage(Timings, "vm_shim", ShimStart)
	end

	local Start = os.clock()
	local Success, Code = pcall(Tracer.Run, ProcessedSource, RuntimeCfg, true)
	local Elapsed = os.clock() - Start
	Timings.tracer = Elapsed

	if NeedsSpyExecRetry(Success, Code, Cfg.spy_exec_only ~= false) then
		local RetryCfg = CloneConfig(RuntimeCfg)
		RetryCfg.spy_exec_only = false
		local RetryStart = os.clock()
		local RetrySuccess, RetryCode = pcall(Tracer.Run, ProcessedSource, RetryCfg, true)
		local RetryElapsed = os.clock() - RetryStart
		if RetrySuccess and typeof(RetryCode) == "string" then
			Success = RetrySuccess
			Code = RetryCode
			Elapsed = RetryElapsed
		end
		EndStage(Timings, "retry_tracer", RetryStart)
	end

	Code = StripTracerRuntimeError(Code)

	Logger.Print("Took", Elapsed, "seconds to process.", Success)

	if not Success or typeof(Code) == "userdata" then
		local SanitizeStart = BeginStage()
		if typeof(Code) ~= "string" then
			Code = tostring(Code)
		end
		Code = LuauErrorFormatter.Format(Code, Cfg.debug, {
			defaultFile = File,
		})

		local TempState = require("./State").new()
		local TempEmitter = require("../CodeGen/Emitter").new(TempState, Cfg)
		local TempBeautifier = Beautifier.new(TempState, TempEmitter, Cfg)

		Code = `error({TempBeautifier:Beautify(Code)})`
		EndStage(Timings, "sanitize_error", SanitizeStart)
	end

	local Final = Code or ""

	pcall(function()
		if fs.isFile("input.lua") then
			fs.removeFile("input.lua")
		end
	end)

	local WriteStart = BeginStage()
	fs.writeFile(OutFile, Final)
	EndStage(Timings, "write_output", WriteStart)

	PrintTimingsIfEnabled(Cfg, Timings)

	return Final, Elapsed, Success
end

function Decoder.DecodeString(Source, Cfg)
	Cfg = Cfg or Config.Settings
	local Timings = {}
	local OriginalSource = Source

	if not Cfg.raw then
		local UnparseStart = BeginStage()
		local SessionUnparser = Unparser.new(Cfg)
		local Obfuscated = SessionUnparser:Obfuscate(Source)

		if Obfuscated then
			Source = Obfuscated
		end
		EndStage(Timings, "unparse", UnparseStart)
	end

	if ShouldApplyVmShim(Cfg) then
		local ShimStart = BeginStage()
		local Shimmed, Changed = VmCallShim.Apply(Source)
		if Changed then
			Source = Shimmed
		end
		EndStage(Timings, "vm_shim", ShimStart)
	end

	local RuntimeCfg = CloneConfig(Cfg)
	RuntimeCfg.__original_source = OriginalSource

	local Start = os.clock()
	local Success, Code = pcall(Tracer.Run, Source, RuntimeCfg, true)
	local Elapsed = os.clock() - Start
	Timings.tracer = Elapsed

	if NeedsSpyExecRetry(Success, Code, Cfg.spy_exec_only ~= false) then
		local RetryCfg = CloneConfig(RuntimeCfg)
		RetryCfg.spy_exec_only = false
		local RetryStart = os.clock()
		local RetrySuccess, RetryCode = pcall(Tracer.Run, Source, RetryCfg, true)
		local RetryElapsed = os.clock() - RetryStart
		if RetrySuccess and typeof(RetryCode) == "string" then
			Success = RetrySuccess
			Code = RetryCode
			Elapsed = RetryElapsed
		end
		EndStage(Timings, "retry_tracer", RetryStart)
	end

	Code = StripTracerRuntimeError(Code)

	if not Success and typeof(Code) == "string" then
		local SanitizeStart = BeginStage()
		Code = LuauErrorFormatter.Format(Code, Cfg.debug)
		EndStage(Timings, "sanitize_error", SanitizeStart)
	end

	PrintTimingsIfEnabled(Cfg, Timings)

	return Code, Elapsed, Success
end

return Decoder