local Ops = {}

function Ops.SetParent(Inst, Parent)
	return Inst:SetParent(Parent)
end

function Ops.Clone(Inst)
	return Inst:Clone()
end

function Ops.Destroy(Inst)
	return Inst:Destroy()
end

return Ops