local HttpApi = {}

function HttpApi.Build(Ctx, Emitter, Beautifier)
	local function EscapeJson(Value)
		local Text = tostring(Value or "")
		Text = string.gsub(Text, "\\", "\\\\")
		Text = string.gsub(Text, "\"", "\\\"")
		Text = string.gsub(Text, "\r", "\\r")
		Text = string.gsub(Text, "\n", "\\n")
		Text = string.gsub(Text, "\t", "\\t")
		return Text
	end

	local function NormalizeHeaders(Headers)
		local Out = {}
		if typeof(Headers) ~= "table" then
			return Out
		end
		for Key, Value in next, Headers do
			Out[tostring(Key)] = tostring(Value)
		end
		return Out
	end

	local function HeadersToJson(Headers)
		local Parts = {}
		for Key, Value in next, Headers do
			Parts[#Parts + 1] = `"{EscapeJson(Key)}":"{EscapeJson(Value)}"`
		end
		table.sort(Parts)
		return "{" .. table.concat(Parts, ",") .. "}"
	end

	local function ResolveUserAgent(Headers)
		for Key, Value in next, Headers do
			if string.lower(tostring(Key)) == "user-agent" then
				return tostring(Value)
			end
		end
		return "Roblox/WinInet"
	end

	local function BuildBodyPayload(Url, Method, Headers, BodyValue)
		local BodyString = ""
		if BodyValue ~= nil then
			BodyString = tostring(BodyValue)
		end
		local NormalizedHeaders = NormalizeHeaders(Headers)
		local HeadersJson = HeadersToJson(NormalizedHeaders)
		local UserAgent = ResolveUserAgent(NormalizedHeaders)
		return string.format(
			'{"user-agent":"%s","url":"%s","method":"%s","headers":%s,"body":"%s"}',
			EscapeJson(UserAgent),
			EscapeJson(Url),
			EscapeJson(Method),
			HeadersJson,
			EscapeJson(BodyString)
		)
	end

	local function BuildHttpResponse(Url, Method, Headers, BodyValue)
		return {
			Success = true,
			StatusCode = 200,
			StatusMessage = "OK",
			Headers = {
				["Content-Type"] = "application/json",
				["content-type"] = "application/json",
			},
			Body = BuildBodyPayload(Url, Method, Headers, BodyValue),
		}
	end

	local HttpLib = {
		get = function(Url, Headers)
			if typeof(Url) ~= "string" then error("invalid argument #1 to 'get' (string expected)") end
			return BuildHttpResponse(Url, "GET", Headers, nil)
		end,
		post = function(Url, Body, ContentType, Headers)
			if typeof(Url) ~= "string" then error("invalid argument #1 to 'post' (string expected)") end
			return BuildHttpResponse(Url, "POST", Headers, Body)
		end,
		request = function(Options, MaybeOptions)
			local Payload = Options
			if typeof(Payload) == "table" and Payload.Url == nil and Payload.URL == nil and Payload.url == nil and typeof(MaybeOptions) == "table" then
				Payload = MaybeOptions
			end
			if typeof(Payload) ~= "table" then
				error("invalid argument #1 to 'request' (table expected)")
			end
			local Url = Payload.Url or Payload.URL or Payload.url
			if typeof(Url) ~= "string" then
				error("invalid argument #1 to 'request' (missing Url string)")
			end
			local Method = string.upper(tostring(Payload.Method or Payload.method or "GET"))
			local Headers = Payload.Headers or Payload.headers or {}
			local BodyValue = Payload.Body
			if BodyValue == nil then
				BodyValue = Payload.body
			end
			return BuildHttpResponse(Url, Method, Headers, BodyValue)
		end,
	}

	local WebSocketLib = {
		connect = function(Url, ...)
			if typeof(Url) ~= "string" then error("invalid argument #1 to 'connect' (string expected)") end
			local OnMessageCallbacks = {}
			local OnCloseCallbacks = {}
			return {
				Send = function(self, msg)
					if typeof(msg) ~= "string" then error("invalid argument #1 to 'Send' (string expected)") end
				end,
				Close = function(self)
					for _, cb in OnCloseCallbacks do
						pcall(cb)
					end
				end,
				OnMessage = {
					Fire = function(self, ...)
						local a = table.pack(...)
						for _, cb in OnMessageCallbacks do pcall(cb, table.unpack(a, 1, a.n)) end
					end,
					Connect = function(self, Cb)
						table.insert(OnMessageCallbacks, Cb)
						return {
							Connected = true,
							Disconnect = function(s) s.Connected = false end,
						}
					end,
				},
				OnClose = {
					Fire = function(self, ...)
						local a = table.pack(...)
						for _, cb in OnCloseCallbacks do pcall(cb, table.unpack(a, 1, a.n)) end
					end,
					Connect = function(self, Cb)
						table.insert(OnCloseCallbacks, Cb)
						return {
							Connected = true,
							Disconnect = function(s) s.Connected = false end,
						}
					end,
				},
			}
		end,
	}

	local cache_invalidation = {}
	local cache_replace = {}
	local cache = {
		invalidate = function(obj)
			cache_invalidation[obj] = true
			if typeof(obj) == "table" and typeof(obj.SetParent) == "function" then
				pcall(function()
					obj:SetParent(nil)
				end)
			end
		end,
		iscached = function(obj)
			return not (cache_invalidation[obj] == true)
		end,
		replace = function(obj, new_obj)
			cache_replace[obj] = new_obj
		end,
	}

	return {
		http = HttpLib,
		WebSocket = WebSocketLib,
		cache = cache,
		request = function(Options)
			if typeof(Options) ~= "table" then error("invalid argument #1 to 'request' (table expected)") end
			local Url = Options.Url or Options.URL or Options.url
			if typeof(Url) ~= "string" then
				error("invalid argument #1 to 'request' (missing Url string)")
			end
			local Method = string.upper(tostring(Options.Method or Options.method or "GET"))
			local Headers = Options.Headers or Options.headers or {}
			local BodyValue = Options.Body
			if BodyValue == nil then
				BodyValue = Options.body
			end
			return BuildHttpResponse(Url, Method, Headers, BodyValue)
		end,
		httpget = function(Url)
			if typeof(Url) ~= "string" then error("invalid argument #1 to 'httpget' (string expected)") end
			return ""
		end,
	}
end

return HttpApi