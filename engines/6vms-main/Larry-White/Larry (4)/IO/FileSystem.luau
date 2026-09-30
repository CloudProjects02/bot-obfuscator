local fs = require("@lune/fs")

local FileSystem = {}

function FileSystem.Build(Proxy, State, Emitter, Beautifier, Scope)
	local function ValidatePath(Path)
		if typeof(Path) ~= "string" then
			error("invalid argument #1 to 'filesystem' (string expected)", 2)
		end
		if Path == "" then
			error("invalid path", 2)
		end
		local Normalized = string.gsub(Path, "\\", "/")
		if string.sub(Normalized, 1, 1) == "/" or string.match(Normalized, "^%a:") then
			error("path escapes workspace", 2)
		end
		for Part in string.gmatch(Normalized, "[^/]+") do
			if Part == ".." then
				error("path escapes workspace", 2)
			end
		end
		return Path
	end

	local function SpyReturn(FuncName, ...)
		local Value = `{FuncName}({Beautifier:BeautifyTuple(...)})`
		local Var = Scope:AddVar(FuncName, "fs", Value, "__call")
		return Proxy:Spy(Var)
	end

	local function HasInternal(...)
		local Args = table.pack(...)
		for I = 1, Args.n do
			if State:IsInternal(Args[I]) then
				return true
			end
		end
		return false
	end

	return {
		readfile = function(Path)
			if HasInternal(Path) then
				return SpyReturn("readfile", Path)
			end

			Path = ValidatePath(Path)

			local S, R = pcall(fs.readFile, Path)
			if S then return R end
			error(R, 0)
		end,

		writefile = function(Path, Content)
			if HasInternal(Path, Content) then
				return SpyReturn("writefile", Path, Content)
			end

			Path = ValidatePath(Path)
			if typeof(Content) ~= "string" then
				error("invalid argument #2 to 'writefile' (string expected)")
			end
			local S, E = pcall(fs.writeFile, Path, Content)
			if not S then
				error(E, 0)
			end
			Emitter:Append(`writefile({Beautifier:Beautify(Path)}, {Beautifier:Beautify(Content)})`)
		end,

		appendfile = function(Path, Content)
			if HasInternal(Path, Content) then
				return SpyReturn("appendfile", Path, Content)
			end

			Path = ValidatePath(Path)
			if typeof(Content) ~= "string" then
				error("invalid argument #2 to 'appendfile' (string expected)")
			end
			local Existing = ""
			local ReadOk, ReadValue = pcall(fs.readFile, Path)
			if ReadOk and typeof(ReadValue) == "string" then
				Existing = ReadValue
			end
			local S, E = pcall(fs.writeFile, Path, Existing .. Content)
			if not S then
				error(E, 0)
			end
			Emitter:Append(`appendfile({Beautifier:Beautify(Path)}, {Beautifier:Beautify(Content)})`)
		end,

		isfile = function(Path)
			if HasInternal(Path) then
				return SpyReturn("isfile", Path)
			end

			local Ok, Valid = pcall(ValidatePath, Path)
			if not Ok then return false end
			Path = Valid
			return fs.isFile(Path)
		end,

		isfolder = function(Path)
			if HasInternal(Path) then
				return SpyReturn("isfolder", Path)
			end

			local Ok, Valid = pcall(ValidatePath, Path)
			if not Ok then return false end
			Path = Valid
			return fs.isDir(Path)
		end,

		makefolder = function(Path)
			if HasInternal(Path) then
				return SpyReturn("makefolder", Path)
			end

			Path = ValidatePath(Path)
			local S, E = pcall(fs.writeDir, Path)
			if not S then
				error(E, 0)
			end
			Emitter:Append(`makefolder({Beautifier:Beautify(Path)})`)
		end,

		delfolder = function(Path)
			if HasInternal(Path) then
				return SpyReturn("delfolder", Path)
			end

			Path = ValidatePath(Path)
			if fs.isDir(Path) then
				local S, E = pcall(fs.removeDir, Path)
				if not S then
					error(E, 0)
				end
			end
			Emitter:Append(`delfolder({Beautifier:Beautify(Path)})`)
		end,

		delfile = function(Path)
			if HasInternal(Path) then
				return SpyReturn("delfile", Path)
			end

			Path = ValidatePath(Path)
			if fs.isFile(Path) then
				local S, E = pcall(fs.removeFile, Path)
				if not S then
					error(E, 0)
				end
			end
			Emitter:Append(`delfile({Beautifier:Beautify(Path)})`)
		end,

		listfiles = function(Path)
			if HasInternal(Path) then
				return SpyReturn("listfiles", Path)
			end

			Path = ValidatePath(Path)

			local S, R = pcall(fs.readDir, Path)
			if S then return R end
			return {}
		end,

		loadfile = function(Path, ...)
			if HasInternal(Path) then
				return SpyReturn("loadfile", Path, ...)
			end

			Path = ValidatePath(Path)

			local S, Content = pcall(fs.readFile, Path)
			if not S then
				return nil, Content
			end

			local luau = require("@lune/luau")
			local Func = luau.load(Content)
			if not Func then
				return nil, "Failed to load file"
			end

			return Func
		end,

		dofile = function(Path, ...)
			if HasInternal(Path) then
				return SpyReturn("dofile", Path, ...)
			end

			Path = ValidatePath(Path)

			local S, Content = pcall(fs.readFile, Path)
			if not S then error(Content) end

			local luau = require("@lune/luau")
			local Func = luau.load(Content)
			if not Func then error("Failed to load file") end

			return Func(...)
		end,
	}
end

return FileSystem