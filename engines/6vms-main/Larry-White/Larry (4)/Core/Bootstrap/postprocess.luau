local PostProcess = {}

function PostProcess.Finalize(SessionState, Cfg, CleanupMod, MinifierMod, RenamerMod, CollectionMod, SessionBeautifier, UncFuncs)
	local SessionCleanup = CleanupMod.new(SessionState, Cfg)
	local CleanedOutput = SessionCleanup:Run(SessionState.Output)

	local FinalSource

	if Cfg.minifier then
		local SessionMinifier = MinifierMod.new(SessionState, Cfg)
		local SessionRenamer = RenamerMod.new(SessionState, Cfg)
		SessionMinifier:SetRenamer(SessionRenamer)
		FinalSource = SessionMinifier:Run(CleanedOutput)

		if Cfg.varRenamer then
			FinalSource = SessionRenamer:ApplyToSource(FinalSource)
		end
	else
		local Filtered = {}
		for _, Line in CleanedOutput do
			if Line ~= nil then
				Filtered[#Filtered + 1] = Line
			end
		end
		FinalSource = table.concat(Filtered, "\n")
	end

	FinalSource = SessionCleanup:PostProcess(FinalSource)

	if Cfg.constant_collection then
		local SessionCollection = CollectionMod.new(SessionState, Cfg)
		local GetGc = UncFuncs and UncFuncs.getgc
		local GcItems = GetGc and GetGc(true) or {}
		SessionCollection:ScanGc(GcItems)
		if Cfg.constant_source_scan ~= false then
			SessionCollection:ScanSource(FinalSource)
		end
		if Cfg.constant_aliases ~= false then
			FinalSource = SessionCollection:AliasSource(FinalSource)
		else
			local CollectionStr = SessionCollection:Generate(SessionBeautifier)
			if #CollectionStr > 0 then
				FinalSource = CollectionStr .. "\n\n" .. FinalSource
			end
		end
	end

	return FinalSource
end

return PostProcess