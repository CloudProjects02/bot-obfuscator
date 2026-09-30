local fs = require("@lune/fs")
local net = require("@lune/net")

local Version = {}
local Cache = nil

function Version.Get()
	if Cache then
		return Cache
	end

	local Success, Content = pcall(fs.readFile, "Data/version.json")
	if Success then
		local Ok, Decoded = pcall(net.jsonDecode, Content)
		if Ok then
			Cache = Decoded
			return Cache
		end
	end

	Cache = {
		version = "0.712.0.7120919",
		clientVersionUpload = "version-b130242ed064436f",
		bootstrapperVersion = "1, 6, 0, 7120919",
	}
	return Cache
end

return Version