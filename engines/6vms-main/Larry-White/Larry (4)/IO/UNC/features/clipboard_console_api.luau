local ClipboardConsoleApi = {}

function ClipboardConsoleApi.Build(Ctx, Emitter, Beautifier)
	local noop = Ctx.noop

	return {
		setclipboard = function(Content)
			if typeof(Content) ~= "string" then Content = tostring(Content) end
			Ctx.ClipboardContent = Content
			Emitter:Append(`setclipboard({Beautifier:Beautify(Content)})`)
		end,

		setrbxclipboard = function(Content)
			if typeof(Content) ~= "string" then Content = tostring(Content) end
			Ctx.ClipboardContent = Content
			Emitter:Append(`setrbxclipboard({Beautifier:Beautify(Content)})`)
		end,

		getclipboard = function()
			return Ctx.ClipboardContent
		end,

		rconsoleprint = function(...)
			Emitter:Append(`rconsoleprint({Beautifier:BeautifyTuple(...)})`)
		end,

		rconsoleinfo = function(...)
			Emitter:Append(`rconsoleinfo({Beautifier:BeautifyTuple(...)})`)
		end,

		rconsolewarn = function(...)
			Emitter:Append(`rconsolewarn({Beautifier:BeautifyTuple(...)})`)
		end,

		rconsoleerr = function(...)
			Emitter:Append(`rconsoleerr({Beautifier:BeautifyTuple(...)})`)
		end,

		rconsoleclear = function()
			Emitter:Append("rconsoleclear()")
		end,

		rconsoleinput = function()
			return ""
		end,

		rconsoleclose = function()
			Emitter:Append("rconsoleclose()")
		end,

		rconsolecreate = noop,
		rconsolesettitle = function(Title) end,
		rconsoledestroy = noop,
	}
end

return ClipboardConsoleApi