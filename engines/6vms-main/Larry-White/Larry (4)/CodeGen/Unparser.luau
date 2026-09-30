local fs = require("@lune/fs")
local Process = require("@lune/process")

local IdentityUtil = require("../Utils/Identity")

local Unparser = {}

function Unparser.new(Config)
	local Self = setmetatable({}, { __index = Unparser })
	Self.Config = Config
	return Self
end

function Unparser:Obfuscate(Source)
	local TempFile = "temp/" .. IdentityUtil.Generate(6)

	pcall(fs.writeDir, "temp")
	fs.writeFile(TempFile, Source)

	local S, Result = pcall(function()
		return self:ObfuscateFile(TempFile)
	end)

	pcall(fs.removeFile, TempFile)

	if S then return Result end
	return nil, Result
end

function Unparser:ObfuscateFile(Path)
	local Config = self.Config

	local Args = {
		"testing/prom/src/cli.lua",
		"
		"
	}

	table.insert(Args, Path)

	local S, Output = pcall(Process.exec, "lua", Args)

	if not S then
		return nil, "Unparser tool not available"
	end

	local Parts = string.split(Path, ".")
	local BasePath = Path

	if Parts[#Parts] == "lua" then
		BasePath = table.concat(table.move(Parts, 1, #Parts - 1, 1, {}), ".")
	end

	local OutputPath = `{BasePath}.obfuscated.lua`

	local ReadOk, Content = pcall(fs.readFile, OutputPath)

	if ReadOk then
		pcall(fs.removeFile, OutputPath)
		return Content
	end

	return nil, "Failed to read obfuscated output"
end

function Unparser:ObfuscateCode(Code)
	local TempFile = "temp/" .. IdentityUtil.Generate(6) .. ".lua"

	pcall(fs.writeDir, "temp")

	local WriteOk = pcall(fs.writeFile, TempFile, Code)
	if not WriteOk then return nil, "Failed to write temp file" end

	local S, Result = pcall(function()
		return self:ObfuscateFile(TempFile)
	end)

	pcall(fs.removeFile, TempFile)

	if S and Result then
		return Result
	end

	return nil, typeof(Result) == "string" and Result or "Obfuscation failed"
end

return Unparser