local Players = {}

local function MakeMouse()
	local Instance = require("../../Instance")
	local Mouse = Instance._new("PlayerMouse", {}, nil, nil, nil, nil, nil, true)
	Mouse._Name = "Mouse"
	Mouse._Properties["X"] = 960
	Mouse._Properties["Y"] = 540
	Mouse._Properties["Target"] = nil
	Mouse._Properties["Hit"] = nil
	Mouse._Properties["UnitRay"] = nil
	Mouse._Properties["Origin"] = nil
	Mouse._Properties["Icon"] = ""
	Mouse._Properties["ViewSizeX"] = 1920
	Mouse._Properties["ViewSizeY"] = 1080
	return Mouse
end

function Players.Register(Methods)
	Methods.Register("Players", "GetPlayers", function(Inst)
		local Out = {}
		for _, Child in ipairs(Inst:GetChildren()) do
			if typeof(Child) == "table" and Child.IsA and Child:IsA("Player") then
				Out[#Out + 1] = Child
			end
		end
		return Out
	end)

	Methods.Register("Players", "GetPlayerByUserId", function(Inst, UserId)
		local NumericId = tonumber(UserId)
		if NumericId == nil then
			return nil
		end
		NumericId = math.floor(NumericId)
		if NumericId < 0 then
			return nil
		end

		for _, Child in ipairs(Inst:GetChildren()) do
			if typeof(Child) == "table" and Child.IsA and Child:IsA("Player") then
				local ChildUserId = tonumber(Child.UserId)
				if ChildUserId and math.floor(ChildUserId) == NumericId then
					return Child
				end
			end
		end

		return nil
	end)

	Methods.Register("Player", "GetMouse", function(Inst)
		local Existing = Inst:GetRawProperty("_LarryMouse")
		if Existing ~= nil then
			return Existing
		end

		local Mouse = MakeMouse()
		Inst:SetProperty("_LarryMouse", Mouse)
		return Mouse
	end)

	Methods.Register("Player", "GetNetworkPing", function(_Inst)
		return 0.036
	end)

	Methods.Register("Players", "GetNetworkPing", function(_Inst, _Player)
		return 0.036
	end)

	Methods.Register("Players", "GetNameFromUserIdAsync", function(Inst, UserId)
		local NumericId = tonumber(UserId)
		if NumericId == nil then
			error("Players:GetNameFromUserIdAsync() userId must be a number", 0)
		end

		NumericId = math.max(1, math.floor(math.abs(NumericId)))

		for _, Child in Inst:GetChildren() do
			if typeof(Child) == "table" and Child.IsA and Child:IsA("Player") then
				local ChildUserId = tonumber(Child.UserId)
				if ChildUserId and math.floor(ChildUserId) == NumericId then
					return tostring(Child.Name)
				end
			end
		end

		return `Player{NumericId}`
	end)

	Methods.Register("Players", "GetUserIdFromNameAsync", function(Inst, Name)
		if typeof(Name) ~= "string" or Name == "" then
			error("Players:GetUserIdFromNameAsync() name must be a non-empty string", 0)
		end

		for _, Child in Inst:GetChildren() do
			if typeof(Child) == "table" and Child.IsA and Child:IsA("Player") and Child.Name == Name then
				local ChildUserId = tonumber(Child.UserId)
				if ChildUserId then
					return math.floor(ChildUserId)
				end
			end
		end

		return 1
	end)

	Methods.Register("Players", "GetPlayerFromCharacter", function(Inst, Character)
		if typeof(Character) ~= "table" or not Character.IsA or not Character:IsA("Model") then
			return nil
		end

		for _, Child in Inst:GetChildren() do
			if typeof(Child) == "table" and Child.IsA and Child:IsA("Player") and Child.Character == Character then
				return Child
			end
		end

		return nil
	end)

	Methods.Register("Players", "GetCharacterAppearanceInfoAsync", function(_Inst, UserId)
		local NumericId = tonumber(UserId)
		if NumericId == nil then
			error("Players:GetCharacterAppearanceInfoAsync() userId must be a number", 0)
		end

		NumericId = math.max(1, math.floor(math.abs(NumericId)))
		return {
			userId = NumericId,
			assets = {
				{
					id = 1029025,
					name = "Default Shirt",
					assetType = {
						name = "Shirt",
					},
				},
			},
			bodyColors = {
				leftArmColorId = 194,
				torsoColorId = 194,
				rightArmColorId = 194,
				headColorId = 194,
				leftLegColorId = 194,
				rightLegColorId = 194,
			},
			scales = {
				bodyType = 0,
				head = 1,
				height = 1,
				proportion = 0,
				depth = 1,
				width = 1,
			},
		}
	end)

	Methods.Register("Players", "GetHumanoidDescriptionFromUserId", function(_Inst, UserId)
		local NumericId = tonumber(UserId)
		if NumericId == nil then
			error("Players:GetHumanoidDescriptionFromUserId() userId must be a number", 0)
		end
		local Instance = require("../../Instance")
		local Description = Instance._new("HumanoidDescription", {}, nil, nil, nil, nil, nil, true)
		Description._Name = "HumanoidDescription"
		Description:SetProperty("_LarryEmotes", {
			Wave = { 507770239 },
		})
		return Description
	end)

	Methods.Register("HumanoidDescription", "GetEmotes", function(Inst)
		local Emotes = Inst:GetProperty("_LarryEmotes")
		if typeof(Emotes) == "table" and next(Emotes) ~= nil then
			return Emotes
		end
		return {
			Wave = { 507770239 },
		}
	end)

	Methods.Register("Teams", "GetTeams", function(Inst)
		return Inst:GetChildren()
	end)
end

return Players