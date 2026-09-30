local Tags = {}

function Tags.TagDataType(TypeName, Value)
	if typeof(Value) == "table" then
		rawset(Value, "__larryType", TypeName)
	end
	return Value
end

function Tags.IsTypeTag(Value, TypeName)
	return typeof(Value) == "table" and rawget(Value, "__larryType") == TypeName
end

return Tags