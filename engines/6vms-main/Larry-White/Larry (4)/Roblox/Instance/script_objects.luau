local ScriptObjects = {}

function ScriptObjects.HttpGet(Inst, Url, NoCache)
	return Inst:HttpGet(Url, NoCache)
end

function ScriptObjects.HttpGetAsync(Inst, Url, NoCache)
	return Inst:HttpGetAsync(Url, NoCache)
end

function ScriptObjects.GetService(Inst, Name)
	return Inst:GetService(Name)
end

function ScriptObjects.WaitForChild(Inst, Name, Timeout)
	return Inst:WaitForChild(Name, Timeout)
end

return ScriptObjects