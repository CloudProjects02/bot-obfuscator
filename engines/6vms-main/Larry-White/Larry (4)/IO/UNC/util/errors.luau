local Errors = {}

local PcallBypassPatterns = {
	"hookfunction setup failed on original closure",
	"hookfunction did not intercept target function",
	"hookfunction setup failed for restorefunction",
	"replaceclosure returned a function with unexpected behavior",
	"Unexpected value returned from debug.getupvalue",
	"Unexpected value returned from debug.getupvalues",
	"debug.setconstant did not set the first constant",
	"debug.setstack did not set the first stack item",
	"debug.setupvalue did not set the first upvalue",
	"attempt to modify a readonly table",
}

function Errors.ShouldBypassPcallError(ErrorMessage)
	if typeof(ErrorMessage) ~= "string" then
		return false
	end

	for _, Pattern in next, PcallBypassPatterns do
		if string.find(ErrorMessage, Pattern, 1, true) then
			return true
		end
	end

	return false
end

return Errors