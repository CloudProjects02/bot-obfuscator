local RunService = {}

function RunService.Register(Methods)
	Methods.Register("RunService", "IsStudio", function(_Inst)
		return false
	end)

	Methods.Register("RunService", "IsClient", function(_Inst)
		return true
	end)

	Methods.Register("RunService", "IsServer", function(_Inst)
		return false
	end)

	Methods.Register("RunService", "IsRunning", function(Inst)
		local Running = Inst:GetProperty("IsRunning")
		if typeof(Running) == "boolean" then
			return Running
		end
		return true
	end)

	Methods.Register("RunService", "GetRobloxVersion", function(_Inst)
		local Version = require("../../Version")
		return Version.Get().version
	end)

	Methods.Register("RunService", "GetCoreScriptVersion", function(_Inst)
		return string.rep("0", 40)
	end)

	Methods.Register("RunService", "GetRealPhysicsFPS", function(_Inst)
		local Services = require("../../Services")
		local Workspace = Services.GetOrNil("Workspace")
		if Workspace and Workspace.GetProperty then
			local Fps = Workspace:GetProperty("RealPhysicsFPS")
			if typeof(Fps) == "number" then
				return Fps
			end
		end
		return 60
	end)
end

return RunService