local Legacy = require("./DataTypes/legacy_impl")

local Constructors = {
	vector = require("./DataTypes/constructors/vector"),
	cframe = require("./DataTypes/constructors/cframe"),
	color = require("./DataTypes/constructors/color"),
	udim_rect = require("./DataTypes/constructors/udim_rect"),
	ranges_sequences = require("./DataTypes/constructors/ranges_sequences"),
	random = require("./DataTypes/constructors/random"),
	datetime = require("./DataTypes/constructors/datetime"),
	path_security = require("./DataTypes/constructors/path_security"),
	misc = require("./DataTypes/constructors/misc"),
}

Legacy.Tags = require("./DataTypes/tags")
Legacy.Serialize = require("./DataTypes/serialize")
Legacy.Fallbacks = require("./DataTypes/fallbacks")
Legacy.Constructors = Constructors

function Legacy.GetConstructorGroups()
	local Groups = {}
	for Name, Module in next, Constructors do
		Groups[Name] = Module.Build()
	end
	return Groups
end

return Legacy