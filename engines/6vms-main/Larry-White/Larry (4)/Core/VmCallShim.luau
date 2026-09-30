local VmCallShim = {}

local ReservedNames = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}

local function BuildPrelude()
	return [[
local __larry_vm_root = nil
do
	local existing = nil
	if type(_G) == "table" then
		local shared = rawget(_G, "__larry_vm")
		if type(shared) == "table" then
			existing = shared
		end
	end

	if type(existing) ~= "table" and type(_G) == "table" then
		local runtimeGetter = rawget(_G, "__larry_vm_get")
		if type(runtimeGetter) == "function" then
			local ok, vm = pcall(runtimeGetter)
			if ok and type(vm) == "table" then
				existing = vm
			end
		end
	end

	if type(existing) ~= "table" and type(__larry_vm_get) == "function" then
		local ok, vm = pcall(__larry_vm_get)
		if ok and type(vm) == "table" then
			existing = vm
		end
	end

	if type(existing) ~= "table" then
		existing = {
			hooks = setmetatable({}, { __mode = "k" }),
			constants = setmetatable({}, { __mode = "k" }),
			upvalues = setmetatable({}, { __mode = "k" }),
			force_return = setmetatable({}, { __mode = "k" }),
		}
	end

	if type(_G) == "table" then
		rawset(_G, "__larry_vm", existing)
	end

	__larry_vm_root = existing
end

local function __larry_call(__fn, ...)
	local __vm = __larry_vm_root
	if type(__vm) == "table" then
		local __hook = __vm.hooks and __vm.hooks[__fn] or nil
		if type(__hook) == "function" then
			return __hook(...)
		end

		local __upv = __vm.upvalues and __vm.upvalues[__fn] or nil
		if type(__upv) == "function" then
			return __upv(...)
		end
		if __upv ~= nil and type(__upv) ~= "table" then
			return __upv
		end
		if type(__upv) == "table" then
			local __selected = __upv[1]
			if __selected == nil then
				for __idx, __value in pairs(__upv) do
					if type(__idx) == "number" then
						__selected = __value
						break
					end
				end
			end
			if type(__selected) == "function" then
				return __selected(...)
			end
			if __selected ~= nil then
				return __selected
			end
		end
	end

	local __ret = table.pack(__fn(...))
	if type(__vm) == "table" then
		local __forced = __vm.force_return and __vm.force_return[__fn] or nil
		if __forced ~= nil then
			__vm.force_return[__fn] = nil
			__ret[1] = __forced
			if __ret.n < 1 then
				__ret.n = 1
			end
		end

		local __const = __vm.constants and __vm.constants[__fn] or nil
		if __const ~= nil then
			if type(__const) == "table" then
				local __selected = __const[1]
				if __selected == nil then
					for __idx, __value in pairs(__const) do
						if type(__idx) == "number" then
							__selected = __value
							break
						end
					end
				end
				__ret[1] = __selected
			else
			__ret[1] = __const
			end
			if __ret.n < 1 then
				__ret.n = 1
			end
		end
	end

	return table.unpack(__ret, 1, __ret.n)
end

local __larry_bind_cache = setmetatable({}, { __mode = "k" })
local function __larry_bind(__fn)
	local __cached = __larry_bind_cache[__fn]
	if type(__cached) == "function" then
		return __cached
	end
	local __wrapped = function(...)
		return __larry_call(__fn, ...)
	end
	__larry_bind_cache[__fn] = __wrapped
	return __wrapped
end
]]
end

local function CollectFunctionNames(Source)
	local Names = {}
	local Seen = {}
	local function AddName(Name)
		if typeof(Name) ~= "string" then
			return
		end
		if ReservedNames[Name] then
			return
		end
		if string.sub(Name, 1, 8) == "__larry_" then
			return
		end
		if Seen[Name] then
			return
		end

		Seen[Name] = true
		table.insert(Names, Name)
	end

	for Name in string.gmatch(Source, "local%s+function%s+([%a_][%w_]*)%s*%(") do
		AddName(Name)
	end

	for Name in string.gmatch(Source, "local%s+([%a_][%w_]*)%s*=%s*function%s*%(") do
		AddName(Name)
	end

	for Name in string.gmatch(Source, "\n%s*function%s+([%a_][%w_]*)%s*%(") do
		AddName(Name)
	end

	for Name in string.gmatch(Source, "^[ \t]*function%s+([%a_][%w_]*)%s*%(") do
		AddName(Name)
	end

	for LocalDecl in string.gmatch(Source, "local%s+([^\n;]+)") do
		local Head = string.match(LocalDecl, "^([^=]+)") or LocalDecl
		for Name in string.gmatch(Head, "([%a_][%w_]*)") do
			AddName(Name)
		end
	end

	for ParamBlock in string.gmatch(Source, "function%s*[%w_%.:]*%s*%(([^)]*)%)") do
		for Name in string.gmatch(ParamBlock, "([%a_][%w_]*)") do
			AddName(Name)
		end
	end

	return Names
end

local function RewriteLine(Line, Name)
	if string.find(Line, "function%s+" .. Name .. "%s*%(") then
		return Line
	end

	local Work = " " .. Line
	local Pattern = "([^%w_%.:])(" .. Name .. ")%s*%("
	Work = string.gsub(Work, Pattern, "%1__larry_bind(%2)(")
	return string.sub(Work, 2)
end

local function RewriteExpressionCalls(Line)
	if string.find(Line, "function", 1, true) ~= nil then
		return Line
	end

	local Work = " " .. Line
	local function Wrap(Prefix, Expr)
		if string.find(Expr, "__larry_bind", 1, true) ~= nil then
			return Prefix .. Expr .. "("
		end
		return Prefix .. "__larry_bind(" .. Expr .. ")("
	end

	Work = string.gsub(Work, "([^%w_%.:])([%a_][%w_]*%b[])%s*%(", Wrap)
	Work = string.gsub(Work, "([^%w_%.:])([%a_][%w_%.]*%.[%a_][%w_]*)%s*%(", Wrap)

	return string.sub(Work, 2)
end

local function RewriteCalls(Source, Names)
	local Out = {}
	for Line in string.gmatch(Source .. "\n", "(.-)\n") do
		local NewLine = Line
		for _, Name in ipairs(Names) do
			NewLine = RewriteLine(NewLine, Name)
		end
		NewLine = RewriteExpressionCalls(NewLine)
		table.insert(Out, NewLine)
	end
	return table.concat(Out, "\n")
end

function VmCallShim.Apply(Source)
	if typeof(Source) ~= "string" or Source == "" then
		return Source, false
	end

	local Names = CollectFunctionNames(Source)
	if #Names == 0 then
		return Source, false
	end

	local Rewritten = RewriteCalls(Source, Names)
	local Final = BuildPrelude() .. "\n" .. Rewritten
	return Final, true
end

return VmCallShim