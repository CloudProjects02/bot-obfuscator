local Module = {}

function Module.Register(Methods)
	Methods.Register("BindableEvent", "Fire", function(Inst, ...)
		local Event = Inst.Event
		if typeof(Event) == "table" and typeof(Event.Fire) == "function" then
			Event:Fire(...)
		end
	end)

	Methods.Register("BindableEvent", "Destroy", function(Inst)
		local Event = Inst.Event
		if typeof(Event) == "table" and typeof(Event.GetConnections) == "function" then
			for _, Connection in ipairs(Event:GetConnections()) do
				Connection:Disconnect()
			end
		end
		Inst:SetParent(nil)
	end)

	Methods.Register("BindableFunction", "Invoke", function(Inst, ...)
		local Callback = Inst:GetProperty("OnInvoke")
		if typeof(Callback) == "function" then
			return Callback(...)
		end
		return nil
	end)

	Methods.Register("BindableFunction", "Destroy", function(Inst)
		Inst:SetParent(nil)
	end)
end

return Module