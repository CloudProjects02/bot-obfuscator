local Tags = {}

function Tags.AddTag(Inst, TagName)
	return Inst:AddTag(TagName)
end

function Tags.RemoveTag(Inst, TagName)
	return Inst:RemoveTag(TagName)
end

function Tags.HasTag(Inst, TagName)
	return Inst:HasTag(TagName)
end

function Tags.GetTags(Inst)
	return Inst:GetTags()
end

function Tags.SetAttribute(Inst, Name, Value)
	return Inst:SetAttribute(Name, Value)
end

function Tags.GetAttribute(Inst, Name)
	return Inst:GetAttribute(Name)
end

return Tags