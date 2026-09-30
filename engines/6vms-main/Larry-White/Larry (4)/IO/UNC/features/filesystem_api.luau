local TypeGuards = require("../util/typeguards")

local FilesystemApi = {}

function FilesystemApi.Build(Ctx)
	local FileContents = Ctx.FileContents
	local Folders = Ctx.Folders

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
		return Normalized
	end

	return {
		readfile = function(Path)
			Path = ValidatePath(Path)
			if FileContents[Path] then
				return FileContents[Path]
			end
			error("File not found: " .. tostring(Path))
		end,

		writefile = function(Path, Content)
			Path = ValidatePath(Path)
			if typeof(Content) ~= "string" then error("invalid argument #2 to 'writefile' (string expected)") end
			FileContents[Path] = Content
		end,

		appendfile = function(Path, Content)
			Path = ValidatePath(Path)
			if typeof(Content) ~= "string" then error("invalid argument #2 to 'appendfile' (string expected)") end
			FileContents[Path] = (FileContents[Path] or "") .. Content
		end,

		loadfile = function(Path)
			local OkPath, ValidPath = pcall(ValidatePath, Path)
			if not OkPath then return nil, "invalid path" end
			Path = ValidPath
			if FileContents[Path] then
				local ok1, luau = pcall(require, "@lune/luau")
				if not ok1 then return nil, "loadfile not available" end
				local s, c = pcall(luau.compile, FileContents[Path])
				if s then
					local CallerEnv = TypeGuards.GetCallerEnv()
					local s2, f = pcall(luau.load, c, { environment = CallerEnv })
					if s2 then return f end
					return nil, "failed to load"
				end
				return nil, "failed to compile"
			end
			return nil, "File not found: " .. tostring(Path)
		end,

		dofile = function(Path)
			Path = ValidatePath(Path)
			if FileContents[Path] then
				local ok1, luau = pcall(require, "@lune/luau")
				if not ok1 then error("dofile not available") end
				local s, c = pcall(luau.compile, FileContents[Path])
				if s then
					local CallerEnv = TypeGuards.GetCallerEnv()
					local s2, f = pcall(luau.load, c, { environment = CallerEnv })
					if s2 then return f() end
					error("failed to load: " .. tostring(Path))
				end
				error("failed to compile: " .. tostring(Path))
			end
			error("File not found: " .. tostring(Path))
		end,

		listfiles = function(Folder)
			local OkPath, ValidPath = pcall(ValidatePath, Folder)
			if not OkPath then return {} end
			Folder = ValidPath
			local Result = {}
			local Prefix = Folder
			if string.sub(Prefix, -1) ~= "/" and Prefix ~= "." then
				Prefix = Prefix .. "/"
			end
			if Prefix == "./" or Prefix == "." then
				Prefix = ""
			end
			local seen = {}
			for Path in FileContents do
				if Prefix == "" or string.sub(Path, 1, #Prefix) == Prefix then
					if not seen[Path] then
						table.insert(Result, Path)
						seen[Path] = true
					end
				end
			end
			for FolderPath in Folders do
				if Prefix == "" or string.sub(FolderPath, 1, #Prefix) == Prefix then
					if not seen[FolderPath] then
						table.insert(Result, FolderPath)
						seen[FolderPath] = true
					end
				end
			end
			return Result
		end,

		isfile = function(Path)
			local OkPath, ValidPath = pcall(ValidatePath, Path)
			if not OkPath then return false end
			Path = ValidPath
			return FileContents[Path] ~= nil
		end,

		isfolder = function(Path)
			local OkPath, ValidPath = pcall(ValidatePath, Path)
			if not OkPath then return false end
			Path = ValidPath
			return Folders[Path] ~= nil
		end,

		makefolder = function(Path)
			local Normalized = ValidatePath(Path)
			local Current = ""
			for Part in string.gmatch(Normalized, "[^/]+") do
				if Current == "" then
					Current = Part
				else
					Current ..= "/" .. Part
				end
				Folders[Current] = true
			end
			Folders[Normalized] = true
		end,

		delfolder = function(Path)
			Path = ValidatePath(Path)
			Folders[Path] = nil
		end,

		delfile = function(Path)
			Path = ValidatePath(Path)
			FileContents[Path] = nil
		end,
	}
end

return FilesystemApi