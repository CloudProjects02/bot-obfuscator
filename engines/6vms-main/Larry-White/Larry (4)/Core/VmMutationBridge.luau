local VmMutationBridge = {}
local NativePcall = pcall

local Shared = nil

local function EnsureWeakTable(T)
	if typeof(T) == "table" then
		return T
	end

	return setmetatable({}, { __mode = "k" })
end

function VmMutationBridge.Ensure(Vm)
	if typeof(Vm) ~= "table" then
		Vm = {}
	end

	Vm.hooks = EnsureWeakTable(Vm.hooks)
	Vm.constants = EnsureWeakTable(Vm.constants)
	Vm.upvalues = EnsureWeakTable(Vm.upvalues)
	Vm.force_return = EnsureWeakTable(Vm.force_return)

	return Vm
end

function VmMutationBridge.BindGlobal(Vm, Root)
	Root = Root or _G
	if typeof(Root) == "table" then
		rawset(Root, "__larry_vm", Vm)
	end

	return Vm
end

function VmMutationBridge.SetShared(Vm)
	Shared = VmMutationBridge.Ensure(Vm)
	VmMutationBridge.BindGlobal(Shared)
	return Shared
end

function VmMutationBridge.GetShared()
	if typeof(Shared) ~= "table" then
		Shared = VmMutationBridge.Ensure(nil)
	end

	VmMutationBridge.BindGlobal(Shared)
	return Shared
end

function VmMutationBridge.Resolve()
	local Root = _G

	if typeof(Root) == "table" then
		local RuntimeGetter = rawget(Root, "__larry_vm_get")
		if typeof(RuntimeGetter) == "function" then
			local Ok, Vm = NativePcall(RuntimeGetter)
			if Ok and typeof(Vm) == "table" then
				return VmMutationBridge.SetShared(Vm)
			end
		end
	end

	if typeof(__larry_vm_get) == "function" then
		local Ok, Vm = NativePcall(__larry_vm_get)
		if Ok and typeof(Vm) == "table" then
			return VmMutationBridge.SetShared(Vm)
		end
	end

	if typeof(Root) == "table" then
		local Existing = rawget(Root, "__larry_vm")
		if typeof(Existing) == "table" then
			return VmMutationBridge.SetShared(Existing)
		end
	end

	return VmMutationBridge.GetShared()
end

return VmMutationBridge