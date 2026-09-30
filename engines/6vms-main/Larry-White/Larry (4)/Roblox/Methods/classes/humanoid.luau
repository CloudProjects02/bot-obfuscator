local Humanoid = {}

local function createInternalInstance(Anchor, ClassName, Name)
	local InstanceMod = require("../../Instance")
	local Created = InstanceMod._new(
		ClassName,
		{},
		rawget(Anchor, "_Proxy"),
		rawget(Anchor, "_State"),
		rawget(Anchor, "_Emitter"),
		rawget(Anchor, "_Beautifier"),
		rawget(Anchor, "_Scope"),
		true
	)
	Created._Name = Name or ClassName
	return Created
end

local function EnumNameOf(Value)
	if typeof(Value) == "table" then
		local Name = rawget(Value, "_Name")
		if typeof(Name) == "string" then
			return Name
		end
	end
	return nil
end

local function GetCharacterRoot(HumanoidInst)
	local Character = HumanoidInst.Parent
	if typeof(Character) ~= "table" or typeof(Character.FindFirstChild) ~= "function" then
		return nil
	end
	return Character:FindFirstChild("HumanoidRootPart")
end

local function MakeLiftedVelocity(Root, MinimumY)
	local DataTypes = require("../../DataTypes")
	local Vector3Lib = DataTypes.Get("Vector3")
	if typeof(Vector3Lib) ~= "table" or typeof(Vector3Lib.new) ~= "function" then
		return nil
	end

	local CurrentVelocity = Root:GetProperty("AssemblyLinearVelocity") or Root:GetProperty("Velocity")
	local VX, VY, VZ = 0, 0, 0
	if typeof(CurrentVelocity) == "table" then
		VX = tonumber(rawget(CurrentVelocity, "X")) or 0
		VY = tonumber(rawget(CurrentVelocity, "Y")) or 0
		VZ = tonumber(rawget(CurrentVelocity, "Z")) or 0
	end

	return Vector3Lib.new(VX, math.max(VY, MinimumY), VZ)
end

local function ensureAnimator(HumanoidInst)
	local Animator = HumanoidInst:FindFirstChildOfClass("Animator")
	if Animator == nil then
		Animator = createInternalInstance(HumanoidInst, "Animator", "Animator")
		Animator:SetParent(HumanoidInst)
	end

	local Tracks = Animator:GetRawProperty("_LarryPlayingAnimationTracks")
	if typeof(Tracks) ~= "table" then
		Tracks = {}
		Animator:SetProperty("_LarryPlayingAnimationTracks", Tracks)
	end

	if #Tracks == 0 then
		local Animation = createInternalInstance(Animator, "Animation", "IdleAnimation")
		Animation:SetProperty("AnimationId", "rbxassetid://507766388")

		local Track = createInternalInstance(Animator, "AnimationTrack", "Idle")
		Track:SetProperty("Animation", Animation)
		Track:SetProperty("IsPlaying", true)
		Track:SetProperty("Looped", true)
		Track:SetProperty("Length", 1)
		Track:SetProperty("Speed", 1)
		Track:SetProperty("WeightCurrent", 1)
		Track:SetProperty("WeightTarget", 1)
		Tracks[1] = Track
	end

	return Animator, Tracks
end

function Humanoid.Register(Methods)
	Methods.Register("Humanoid", "GetState", function(Inst)
		local Enums = require("../../Enums")
		local Stored = Inst:GetRawProperty("_LarryHumanoidState")
		if Stored ~= nil then
			return Stored
		end
		return Enums.Get("HumanoidStateType", "Running") or "Running"
	end)

	Methods.Register("Humanoid", "ChangeState", function(Inst, NewState)
		local Enums = require("../../Enums")
		local StateValue = NewState or Enums.Get("HumanoidStateType", "Running")
		local StateName = EnumNameOf(StateValue)

		Inst:SetProperty("_LarryHumanoidState", StateValue)

		if StateName == "Jumping" or StateName == "Jump" then
			Inst:SetProperty("Jump", true)

			local Root = GetCharacterRoot(Inst)
			if typeof(Root) == "table" and typeof(Root.GetProperty) == "function" and typeof(Root.SetProperty) == "function" then
				local Lifted = MakeLiftedVelocity(Root, 50)
				if Lifted ~= nil then
					Root:SetProperty("AssemblyLinearVelocity", Lifted)
					Root:SetProperty("Velocity", Lifted)
				end
			end
		end

		return nil
	end)

	Methods.Register("Animator", "GetPlayingAnimationTracks", function(Inst)
		local Tracks = Inst:GetRawProperty("_LarryPlayingAnimationTracks")
		if typeof(Tracks) == "table" then
			return Tracks
		end
		return {}
	end)

	Methods.Register("Humanoid", "GetPlayingAnimationTracks", function(Inst)
		local Animator = ensureAnimator(Inst)
		return Animator:GetPlayingAnimationTracks()
	end)

	Methods.Register("Animator", "LoadAnimation", function(Inst, Animation)
		local Tracks = Inst:GetRawProperty("_LarryPlayingAnimationTracks")
		if typeof(Tracks) ~= "table" then
			Tracks = {}
			Inst:SetProperty("_LarryPlayingAnimationTracks", Tracks)
		end

		local Track = createInternalInstance(Inst, "AnimationTrack", "AnimationTrack")
		Track:SetProperty("Animation", Animation)
		Track:SetProperty("IsPlaying", false)
		Track:SetProperty("Looped", false)
		Track:SetProperty("Length", 1)
		Track:SetProperty("Speed", 1)
		Track:SetProperty("WeightCurrent", 1)
		Track:SetProperty("WeightTarget", 1)
		Tracks[#Tracks + 1] = Track
		return Track
	end)

	Methods.Register("Humanoid", "LoadAnimation", function(Inst, Animation)
		local Animator = ensureAnimator(Inst)
		return Animator:LoadAnimation(Animation)
	end)

	Methods.Register("AnimationTrack", "Play", function(Inst, _FadeTime, _Weight, Speed)
		Inst:SetProperty("IsPlaying", true)
		if typeof(Speed) == "number" then
			Inst:SetProperty("Speed", Speed)
		end
	end)

	Methods.Register("AnimationTrack", "Stop", function(Inst, _FadeTime)
		Inst:SetProperty("IsPlaying", false)
	end)

	Methods.Register("AnimationTrack", "AdjustSpeed", function(Inst, Speed)
		Inst:SetProperty("Speed", tonumber(Speed) or 1)
	end)
end

return Humanoid