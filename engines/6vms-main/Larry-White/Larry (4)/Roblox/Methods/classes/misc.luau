local HTTP = require("../../../IO/HTTP")
local BufferAndCrypto = require("../../../Libs/BufferAndCrypto")
local Config = require("../../../Config")

local Misc = {}

local function GetConstructor(TypeName)
	local DataTypes = require("../../DataTypes")
	local Lib = DataTypes.Get(TypeName)
	if typeof(Lib) == "table" and typeof(Lib.new) == "function" then
		return Lib.new
	end
	return nil
end

local function MakeVector2(X, Y)
	local New = GetConstructor("Vector2")
	if New then
		return New(X, Y)
	end
	return { X = X, Y = Y }
end

local function MakeVector3(X, Y, Z)
	local New = GetConstructor("Vector3")
	if New then
		return New(X, Y, Z)
	end
	return { X = X, Y = Y, Z = Z }
end

local function MakeRay(Origin, Direction)
	local New = GetConstructor("Ray")
	if New then
		return New(Origin, Direction)
	end
	return {
		Origin = Origin,
		Direction = Direction,
	}
end

local function MakeSecret(Value)
	local SecretValue = tostring(Value or "")
	local Secret = {}
	Secret.__index = Secret

	function Secret:AddPrefix(Prefix)
		return MakeSecret(tostring(Prefix or "") .. SecretValue)
	end

	function Secret:AddSuffix(Suffix)
		return MakeSecret(SecretValue .. tostring(Suffix or ""))
	end

	function Secret:ToString()
		return SecretValue
	end

	local Obj = setmetatable({
		Value = SecretValue,
	}, {
		__index = Secret,
		__tostring = function()
			return "Secret"
		end,
	})
	return Obj
end

function Misc.Register(Methods)
	Methods.RegisterGlobal("IsA", function(Inst, ClassName)
		return Inst:IsA(ClassName)
	end)

	Methods.RegisterGlobal("FindFirstChild", function(Inst, Name, Recursive)
		return Inst:FindFirstChild(Name, Recursive)
	end)

	Methods.RegisterGlobal("FindFirstChildOfClass", function(Inst, ClassName)
		return Inst:FindFirstChildOfClass(ClassName)
	end)

	Methods.RegisterGlobal("FindFirstChildWhichIsA", function(Inst, ClassName)
		return Inst:FindFirstChildWhichIsA(ClassName)
	end)

	Methods.RegisterGlobal("FindFirstAncestorOfClass", function(Inst, ClassName)
		return Inst:FindFirstAncestorOfClass(ClassName)
	end)

	Methods.RegisterGlobal("GetChildren", function(Inst)
		return Inst:GetChildren()
	end)

	Methods.RegisterGlobal("GetDescendants", function(Inst)
		return Inst:GetDescendants()
	end)

	Methods.RegisterGlobal("Clone", function(Inst)
		return Inst:Clone()
	end)

	Methods.RegisterGlobal("Destroy", function(Inst)
		Inst:Destroy()
	end)

	Methods.RegisterGlobal("SetAttribute", function(Inst, Name, Value)
		Inst:SetAttribute(Name, Value)
	end)

	Methods.RegisterGlobal("GetAttribute", function(Inst, Name)
		return Inst:GetAttribute(Name)
	end)

	Methods.RegisterGlobal("WaitForChild", function(Inst, Name, Timeout)
		return Inst:WaitForChild(Name, Timeout)
	end)

	Methods.RegisterGlobal("ClearAllChildren", function(Inst)
		local Children = Inst:GetChildren()
		for I = #Children, 1, -1 do
			Children[I]:Destroy()
		end
	end)

	Methods.RegisterGlobal("GetFullName", function(Inst)
		local Parts = {}
		local Current = Inst

		while Current do
			table.insert(Parts, 1, Current:GetName())
			local Parent = Current:GetParent()
			if typeof(Parent) ~= "table" or not Parent.GetName then break end
			if Parent.GetClassName and Parent:GetClassName() == "DataModel" then
				break
			end
			Current = Parent
		end

		return table.concat(Parts, ".")
	end)

	Methods.RegisterGlobal("GetPropertyChangedSignal", function(Inst, PropName)
		if typeof(PropName) ~= "string" then
			error("invalid argument #1 to 'GetPropertyChangedSignal' (string expected)", 2)
		end

		local ApiDumpIndex = require("../../ApiCatalog")
		local ClassName = typeof(Inst) == "table" and Inst.ClassName or nil
		local IsValidProperty = typeof(ClassName) == "string" and ApiDumpIndex.HasProperty(ClassName, PropName)
		if not IsValidProperty then
			error(`{PropName} is not a valid member of {tostring(ClassName or "Instance")}`, 2)
		end

		local Signals = require("../../Signals")
		return Signals.ForInstance(Inst, PropName .. "_Changed")
	end)

	Methods.RegisterGlobal("GetDebugId", function(Inst, ScopeLength)
		local Cached = nil
		if typeof(Inst) == "table" and typeof(Inst.GetRawProperty) == "function" then
			Cached = Inst:GetRawProperty("_LarryDebugId")
			if typeof(Cached) ~= "string" or Cached == "" then
				local UniqueId = Inst:GetRawProperty("UniqueId")
				if typeof(UniqueId) ~= "string" or UniqueId == "" then
					UniqueId = tostring(rawget(Inst, "_Id") or Inst)
				end
				Cached = "DBG_" .. tostring(UniqueId)
				if typeof(Inst.SetProperty) == "function" then
					Inst:SetProperty("_LarryDebugId", Cached)
				end
			end
		end

		if typeof(Cached) ~= "string" or Cached == "" then
			Cached = "DBG_" .. tostring(Inst)
		end

		if typeof(ScopeLength) == "number" and ScopeLength > 0 and ScopeLength < #Cached then
			return string.sub(Cached, 1, ScopeLength)
		end

		return Cached
	end)

	Methods.RegisterGlobal("JSONDecode", function(_Inst, Str)
		return HTTP.JSONDecode(Str)
	end)

	Methods.RegisterGlobal("JSONEncode", function(_Inst, Data)
		return HTTP.JSONEncode(Data)
	end)

	Methods.Register("HttpService", "GenerateGUID", function(_Inst, WrapInCurlyBraces)
		return HTTP.GenerateGUID(WrapInCurlyBraces)
	end)

	Methods.Register("HttpService", "UrlEncode", function(_Inst, Input)
		return HTTP.UrlEncode(Input)
	end)

	Methods.Register("HttpService", "GetSecret", function(_Inst, Key)
		return MakeSecret(`secret:{tostring(Key or "")}`)
	end)

	Methods.Register("EncodingService", "Base64Encode", function(_Inst, Input)
		return BufferAndCrypto.Base64EncodeBuffer(Input)
	end)

	Methods.Register("EncodingService", "Base64Decode", function(_Inst, Input)
		return BufferAndCrypto.Base64DecodeBuffer(Input)
	end)

	local function ResolveCompressionAlg(MethodName, Alg)
		local Name = BufferAndCrypto.ResolveCompressionAlgorithm(Alg)
		if Name == nil then
			error(`EncodingService:{MethodName}() invalid CompressionAlgorithm`, 0)
		end
		return Name
	end

	local function ResolveHashAlg(MethodName, Alg)
		local Name = BufferAndCrypto.ResolveHashAlgorithm(Alg)
		if Name == nil then
			error(`EncodingService:{MethodName}() invalid HashAlgorithm`, 0)
		end
		return Name
	end

	Methods.Register("EncodingService", "CompressBuffer", function(_Inst, Input, Algorithm, CompressionLevel)
		local AlgName = ResolveCompressionAlg("CompressBuffer", Algorithm)
		local Level = CompressionLevel
		if Level == nil then
			Level = 1
		end
		if typeof(Level) ~= "number" then
			error("EncodingService:CompressBuffer() compressionLevel must be a number", 0)
		end
		if Level % 1 ~= 0 then
			error("EncodingService:CompressBuffer() compressionLevel must be an integer", 0)
		end
		if AlgName == "Zstd" and (Level < -7 or Level > 22) then
			error("EncodingService:CompressBuffer() compressionLevel out of range", 0)
		end
		local Data = BufferAndCrypto.RequireBufferToString(Input, "CompressBuffer", 1)
		local Encoded = BufferAndCrypto.CompressZstdString(Data, Level)
		return BufferAndCrypto.StringToBuffer(Encoded, "CompressBuffer")
	end)

	Methods.Register("EncodingService", "DecompressBuffer", function(_Inst, Input, Algorithm)
		ResolveCompressionAlg("DecompressBuffer", Algorithm)
		local Data = BufferAndCrypto.RequireBufferToString(Input, "DecompressBuffer", 1)
		local Ok, Decoded = pcall(BufferAndCrypto.DecompressZstdString, Data)
		if not Ok then
			if Config and Config.Settings and Config.Settings.spy_exec_only then
				return Input
			end
			error(Decoded, 0)
		end
		return BufferAndCrypto.StringToBuffer(Decoded, "DecompressBuffer")
	end)

	Methods.Register("EncodingService", "GetDecompressedBufferSize", function(_Inst, Input, Algorithm)
		ResolveCompressionAlg("GetDecompressedBufferSize", Algorithm)
		local Data = BufferAndCrypto.RequireBufferToString(Input, "GetDecompressedBufferSize", 1)
		return BufferAndCrypto.GetZstdDecompressedSizeString(Data)
	end)

	Methods.Register("EncodingService", "ComputeBufferHash", function(_Inst, Input, Algorithm)
		local AlgName = ResolveHashAlg("ComputeBufferHash", Algorithm)
		local Data = BufferAndCrypto.RequireBufferToString(Input, "ComputeBufferHash", 1)
		local Digest = BufferAndCrypto.ComputeHashString(Data, AlgName)
		return BufferAndCrypto.StringToBuffer(Digest, "ComputeBufferHash")
	end)

	Methods.Register("EncodingService", "ComputeStringHash", function(_Inst, Input, Algorithm)
		if typeof(Input) ~= "string" then
			error("EncodingService:ComputeStringHash() input must be a string", 0)
		end
		local AlgName = ResolveHashAlg("ComputeStringHash", Algorithm)
		return BufferAndCrypto.ComputeHashString(Input, AlgName)
	end)

	Methods.Register("MarketplaceService", "GetProductInfo", function(_Inst, AssetId, _InfoType, ...)
		if select("#", ...) > 0 then
			error("MarketplaceService:GetProductInfo() expected at most 2 argument(s)", 0)
		end

		local Id = tonumber(AssetId)
		if Id == nil or Id ~= Id or Id == math.huge or Id == -math.huge or math.floor(Id) ~= Id or Id <= 0 then
			error("MarketplaceService:GetProductInfo() assetId must be a positive integer", 0)
		end

		local CreatorId = 1

		return {
			AssetId = Id,
			ProductId = Id,
			Name = `Asset {Id}`,
			Description = "",
			AssetTypeId = 10,
			Creator = {
				Id = CreatorId,
				Name = "Roblox",
				CreatorType = "User",
				CreatorTargetId = CreatorId,
			},
			IconImageAssetId = 0,
			Created = "2024-01-01T00:00:00Z",
			Updated = "2024-01-01T00:00:00Z",
			PriceInRobux = 0,
			IsForSale = false,
			IsLimited = false,
			IsLimitedUnique = false,
			MinimumMembershipLevel = 0,
			ContentRatingTypeId = 0,
		}
	end)

	Methods.Register("MarketplaceService", "UserOwnsGamePassAsync", function(_Inst, _UserId, _GamePassId)
		return false
	end)

	Methods.Register("MarketplaceService", "PlayerOwnsAsset", function(_Inst, _Player, _AssetId)
		return false
	end)

	Methods.Register("UserInputService", "GetMouseLocation", function(_Inst)
		return MakeVector2(960, 540)
	end)

	Methods.Register("GuiService", "GetGuiInset", function(_Inst)
		return MakeVector2(0, 36), MakeVector2(0, 0)
	end)

	Methods.Register("ContentProvider", "GetRequestQueueSize", function(_Inst)
		return 0
	end)

	local function ValidatePreloadList(ContentList, Seen)
		if typeof(ContentList) ~= "table" then
			error("ContentProvider:PreloadAsync contentIdList must be an array", 0)
		end
		Seen = Seen or setmetatable({}, { __mode = "k" })
		if Seen[ContentList] then
			error("ContentProvider:PreloadAsync contentIdList cannot contain cycles", 0)
		end
		Seen[ContentList] = true
		for Key, Value in next, ContentList do
			if typeof(Key) ~= "number" or Key % 1 ~= 0 or Key < 1 then
				error("ContentProvider:PreloadAsync contentIdList must be an array", 0)
			end
			local Kind = typeof(Value)
			if Kind == "table" then
				if rawget(Value, "_ClassName") == nil and typeof(Value.GetClassName) ~= "function" then
					ValidatePreloadList(Value, Seen)
				end
			elseif Kind ~= "string" then
				error("ContentProvider:PreloadAsync contentIdList entries must be content strings or Instances", 0)
			end
		end
	end

	Methods.Register("ContentProvider", "GetAsync", function()
		error("GetAsync is not a valid member of ContentProvider", 0)
	end)

	Methods.Register("ContentProvider", "PreloadAsync", function(_Inst, ContentList, Callback)
		ValidatePreloadList(ContentList)
		if typeof(Callback) == "function" then
			local Enums = require("../../Enums")
			pcall(Callback, "", Enums.Get("AssetFetchStatus", "Success") or "Success")
		end
	end)

	Methods.Register("VirtualInputManager", "SendKeyEvent", function() end)

	Methods.Register("HapticService", "IsVibrationSupported", function(_Inst, _InputType)
		return false
	end)

	Methods.Register("AnimationClipProvider", "GetMemStats", function(_Inst)
		return {
			AnimationClipCount = 4,
			AnimationClipBytes = 8192,
			KeyframeSequenceCount = 2,
			KeyframeSequenceBytes = 4096,
		}
	end)

	Methods.Register("Camera", "WorldToScreenPoint", function(_Inst, WorldPoint)
		local X = typeof(WorldPoint) == "table" and (rawget(WorldPoint, "X") or 0) or 0
		local Y = typeof(WorldPoint) == "table" and (rawget(WorldPoint, "Y") or 0) or 0
		local Z = typeof(WorldPoint) == "table" and (rawget(WorldPoint, "Z") or 0) or 0
		return MakeVector3(960 + X, 540 - Y, Z), true
	end)

	Methods.Register("Camera", "WorldToViewportPoint", function(_Inst, WorldPoint)
		local X = typeof(WorldPoint) == "table" and (rawget(WorldPoint, "X") or 0) or 0
		local Y = typeof(WorldPoint) == "table" and (rawget(WorldPoint, "Y") or 0) or 0
		local Z = typeof(WorldPoint) == "table" and (rawget(WorldPoint, "Z") or 0) or 0
		return MakeVector3(960 + X, 540 - Y, Z), true
	end)

	Methods.Register("Camera", "ScreenPointToRay", function(_Inst, _X, _Y, _Depth)
		return MakeRay(MakeVector3(0, 5, 0), MakeVector3(0, -1, 0))
	end)

	Methods.Register("Camera", "ViewportPointToRay", function(_Inst, _X, _Y, _Depth)
		return MakeRay(MakeVector3(0, 5, 0), MakeVector3(0, -1, 0))
	end)

	Methods.Register("Model", "GetExtentsSize", function(_Inst)
		return MakeVector3(4, 4, 4)
	end)
end

return Misc