local Logger = require("../Utils/Logger")

local View = {}

local LuneNet = nil
local LuneTask = nil

pcall(function()
	LuneNet = require("@lune/net")
end)

pcall(function()
	LuneTask = require("@lune/task")
end)

local PORT = 9371
local SESSION_TTL = 40
local MAX_RENDER_ITEMS = 96
local WAITING = "waiting"
local SUBMITTING = "submitting"
local SUBMITTED = "submitted"

local Server = nil
local ServerStarted = false
local ServerFailed = false
local ServerError = nil
local SessionsById = {}
local SessionByRoot = setmetatable({}, { __mode = "k" })
local ROOTLESS_ATTACH_WINDOW = 2
local MAX_WAIT_SECONDS = 40
local Runtime = {
	State = nil,
	Emitter = nil,
	Beautifier = nil,
}

local HINT_NEEDLES = {
	"enter key",
	"enter your key",
	"enter your key here",
	"key system",
}

local SUBMIT_NEEDLES = {
	"submit",
	"verify",
	"unlock",
	"continue",
	"check",
}

local function EscapeHtml(Text)
	local Str = tostring(Text or "")
	Str = string.gsub(Str, "&", "&amp;")
	Str = string.gsub(Str, "<", "&lt;")
	Str = string.gsub(Str, ">", "&gt;")
	Str = string.gsub(Str, "\"", "&quot;")
	Str = string.gsub(Str, "'", "&#39;")
	return Str
end

local function EscapeJson(Text)
	local Str = tostring(Text or "")
	Str = string.gsub(Str, "\\", "\\\\")
	Str = string.gsub(Str, "\"", "\\\"")
	Str = string.gsub(Str, "\n", "\\n")
	Str = string.gsub(Str, "\r", "\\r")
	Str = string.gsub(Str, "\t", "\\t")
	return Str
end

local function UrlDecode(Value)
	if typeof(Value) ~= "string" then
		return ""
	end

	if LuneNet and typeof(LuneNet.urlDecode) == "function" then
		local Ok, Decoded = pcall(LuneNet.urlDecode, Value)
		if Ok and typeof(Decoded) == "string" then
			return Decoded
		end
	end

	local Out = string.gsub(Value, "+", " ")
	Out = string.gsub(Out, "%%(%x%x)", function(Hex)
		local Num = tonumber(Hex, 16)
		if Num == nil then
			return ""
		end
		return string.char(Num)
	end)
	return Out
end

local function ParseFormBody(Body)
	local Out = {}
	if typeof(Body) ~= "string" then
		return Out
	end

	for Part in string.gmatch(Body, "([^&]+)") do
		local Key, Value = string.match(Part, "^([^=]+)=?(.*)$")
		if Key ~= nil then
			Out[UrlDecode(Key)] = UrlDecode(Value or "")
		end
	end

	return Out
end

local function UnwrapString(Value)
	if typeof(Value) == "string" then
		return Value
	end
	if typeof(Value) == "table" then
		local Raw = rawget(Value, "V")
		if typeof(Raw) == "string" then
			return Raw
		end
	end
	return nil
end

local function GetClassName(Inst)
	if typeof(Inst) ~= "table" then
		return nil
	end

	if typeof(Inst.GetClassName) ~= "function" then
		return nil
	end

	local Ok, ClassName = pcall(Inst.GetClassName, Inst)
	if Ok and typeof(ClassName) == "string" then
		return ClassName
	end

	return nil
end

local function GetParent(Inst)
	if typeof(Inst) ~= "table" or typeof(Inst.GetParent) ~= "function" then
		return nil
	end

	local Ok, Parent = pcall(Inst.GetParent, Inst)
	if Ok then
		return Parent
	end

	return nil
end

local function GetName(Inst)
	if typeof(Inst) ~= "table" or typeof(Inst.GetName) ~= "function" then
		return nil
	end

	local Ok, Name = pcall(Inst.GetName, Inst)
	if Ok and typeof(Name) == "string" then
		return Name
	end

	return nil
end

local function ReadProperty(Inst, PropName)
	if typeof(Inst) ~= "table" then
		return nil
	end

	if typeof(Inst.GetProperty) == "function" then
		local Ok, Value = pcall(Inst.GetProperty, Inst, PropName)
		if Ok then
			return Value
		end
	end

	local Ok, Value = pcall(function()
		return Inst[PropName]
	end)
	if Ok then
		return Value
	end

	return nil
end

local function IsKeyHint(Text)
	if typeof(Text) ~= "string" or Text == "" then
		return false
	end

	local Lower = string.lower(Text)
	for _, Needle in ipairs(HINT_NEEDLES) do
		if string.find(Lower, Needle, 1, true) then
			return true
		end
	end

	return false
end

local function IsLikelySubmit(Text)
	if typeof(Text) ~= "string" or Text == "" then
		return false
	end

	local Lower = string.lower(Text)
	for _, Needle in ipairs(SUBMIT_NEEDLES) do
		if string.find(Lower, Needle, 1, true) then
			return true
		end
	end

	return false
end

local function FindScreenGui(Inst)
	local Current = Inst

	for _ = 1, 40 do
		if typeof(Current) ~= "table" then
			return nil
		end

		local ClassName = GetClassName(Current)
		if ClassName == "ScreenGui" then
			return Current
		end

		local Parent = GetParent(Current)
		if Parent == nil then
			break
		end
		Current = Parent
	end

	return nil
end

local function GenerateSessionId()
	for _ = 1, 256 do
		local Id = string.format("%08d", math.random(0, 99999999))
		if SessionsById[Id] == nil then
			return Id
		end
	end

	local Fallback = tostring(math.floor((os.clock() * 1000) % 100000000))
	while #Fallback < 8 do
		Fallback = "0" .. Fallback
	end
	return Fallback
end

local function SessionSecondsLeft(Session)
	local Left = math.ceil(Session.ExpiresAt - os.clock())
	return math.max(Left, 0)
end

local function SessionCount()
	local Count = 0
	for _ in next, SessionsById do
		Count += 1
	end
	return Count
end

local function StopServer()
	if not ServerStarted or typeof(Server) ~= "table" then
		Server = nil
		ServerStarted = false
		return
	end

	local Stop = Server.stop or Server.Stop or Server.close or Server.Close
	if typeof(Stop) == "function" then
		local Ok, Err = pcall(Stop, Server)
		if not Ok then
			Logger.Print("View server stop failed:", tostring(Err))
		end
	end

	Server = nil
	ServerStarted = false
end

local function MaybeStopServer()
	if SessionCount() > 0 then
		return
	end

	StopServer()
end

local function GetRuntimePath(Value)
	if Runtime.State and typeof(Runtime.State.IsInternal) == "function" then
		local Path = Runtime.State:IsInternal(Value)
		if typeof(Path) == "string" and Path ~= "" then
			return Path
		end
	end

	if Runtime.Beautifier and typeof(Runtime.Beautifier.Beautify) == "function" then
		local Ok, Path = pcall(Runtime.Beautifier.Beautify, Runtime.Beautifier, Value, 1)
		if Ok and typeof(Path) == "string" and Path ~= "" then
			return Path
		end
	end

	return nil
end

local function EmitSubmitMarkerBegin(Button, TextBox, KeyText)
	if Runtime.Emitter == nil or typeof(Runtime.Emitter.AppendRaw) ~= "function" then
		return
	end

	local ButtonPath = GetRuntimePath(Button)
	local TextBoxPath = GetRuntimePath(TextBox)
	if typeof(ButtonPath) ~= "string" or typeof(TextBoxPath) ~= "string" then
		return
	end

	local KeyLiteral = typeof(KeyText) == "string" and string.format("%q", KeyText) or nil
	if KeyLiteral == nil then
		return
	end

	Runtime.Emitter:AppendRaw(
		``
	)
end

local function EmitSubmitMarkerEnd()
	if Runtime.Emitter == nil or typeof(Runtime.Emitter.AppendRaw) ~= "function" then
		return
	end

	Runtime.Emitter:AppendRaw("")
end

local function DropSession(Session)
	if typeof(Session) ~= "table" then
		return
	end

	SessionsById[Session.Id] = nil
	if Session.Root ~= nil then
		SessionByRoot[Session.Root] = nil
	end
end

local function DropAllSessions()
	local ToDrop = {}
	for _, Session in next, SessionsById do
		ToDrop[#ToDrop + 1] = Session
	end
	for _, Session in ipairs(ToDrop) do
		DropSession(Session)
	end
end

local function FindRecentSession()
	local Best = nil

	for _, Session in next, SessionsById do
		if Session.ExpiresAt > os.clock() and (Best == nil or Session.CreatedAt > Best.CreatedAt) then
			Best = Session
		end
	end

	if Best == nil then
		return nil
	end

	if os.clock() - Best.CreatedAt > ROOTLESS_ATTACH_WINDOW then
		return nil
	end

	return Best
end

local function CleanupExpiredSessions()
	local Now = os.clock()
	local ToDrop = {}

	for Id, Session in next, SessionsById do
		if Session.ExpiresAt <= Now then
			ToDrop[#ToDrop + 1] = Id
		end
	end

	for _, Id in ipairs(ToDrop) do
		DropSession(SessionsById[Id])
	end
end

local function PendingSessionCount()
	local Count = 0

	for _, Session in next, SessionsById do
		if (Session.State == WAITING or Session.State == SUBMITTING) and Session.ExpiresAt > os.clock() then
			Count += 1
		end
	end

	return Count
end

local function FireSignal(Target, SignalName, ...)
	local OkSignal, Signal = pcall(function()
		return Target[SignalName]
	end)
	if not OkSignal or typeof(Signal) ~= "table" or typeof(Signal.Fire) ~= "function" then
		return false
	end

	pcall(Signal.Fire, Signal, ...)
	return true
end

local function CollectControls(Session)
	local TextBoxes = {}
	local Buttons = {}
	local BoxSeen = {}
	local ButtonSeen = {}

	local function AddBox(Inst)
		if Inst and not BoxSeen[Inst] then
			BoxSeen[Inst] = true
			TextBoxes[#TextBoxes + 1] = Inst
		end
	end

	local function AddButton(Inst)
		if Inst and not ButtonSeen[Inst] then
			ButtonSeen[Inst] = true
			Buttons[#Buttons + 1] = Inst
		end
	end

	for Inst in next, Session.TextBoxes do
		AddBox(Inst)
	end

	for Inst in next, Session.Buttons do
		AddButton(Inst)
	end

	for Inst in next, Session.Elements do
		local ClassName = GetClassName(Inst)
		if ClassName == "TextBox" then
			AddBox(Inst)
		elseif ClassName == "TextButton" then
			local Text = UnwrapString(ReadProperty(Inst, "Text"))
			if IsLikelySubmit(Text or "") then
				AddButton(Inst)
			end
		end
	end

	local Root = Session.Root
	if typeof(Root) == "table" and typeof(Root.GetDescendants) == "function" then
		local Ok, Descendants = pcall(Root.GetDescendants, Root)
		if Ok and typeof(Descendants) == "table" then
			for _, Inst in ipairs(Descendants) do
				local ClassName = GetClassName(Inst)
				if ClassName == "TextBox" then
					AddBox(Inst)
				elseif ClassName == "TextButton" then
					local Text = UnwrapString(ReadProperty(Inst, "Text"))
					if IsLikelySubmit(Text or "") then
						AddButton(Inst)
					end
				end
			end
		end
	end

	return TextBoxes, Buttons
end

local function ApplySubmittedKey(Session, KeyText)
	local TextBoxes, Buttons = CollectControls(Session)
	local MarkerButton = #Buttons == 1 and Buttons[1] or nil
	local MarkerTextBox = #TextBoxes == 1 and TextBoxes[1] or nil

	EmitSubmitMarkerBegin(MarkerButton, MarkerTextBox, KeyText)

	for _, Box in ipairs(TextBoxes) do
		pcall(function()
			Box.Text = KeyText
		end)
		FireSignal(Box, "Changed", "Text")
		FireSignal(Box, "FocusLost", true, nil)
	end

	for _, Button in ipairs(Buttons) do
		FireSignal(Button, "MouseButton1Down")
		FireSignal(Button, "MouseButton1Click")
		FireSignal(Button, "Activated")
		FireSignal(Button, "MouseButton1Up")
	end

	EmitSubmitMarkerEnd()
end

local function CollectRenderItems(Session)
	local Items = {}
	local Seen = {}

	local function PushItem(Inst)
		if Inst == nil or Seen[Inst] then
			return
		end
		Seen[Inst] = true

		local ClassName = GetClassName(Inst)
		if ClassName == nil then
			return
		end

		if ClassName ~= "Frame"
			and ClassName ~= "TextLabel"
			and ClassName ~= "TextButton"
			and ClassName ~= "TextBox"
		then
			return
		end

		local Item = {
			ClassName = ClassName,
			Name = GetName(Inst) or "",
			Text = UnwrapString(ReadProperty(Inst, "Text")) or "",
			PlaceholderText = UnwrapString(ReadProperty(Inst, "PlaceholderText")) or "",
		}

		Items[#Items + 1] = Item
	end

	local Root = Session.Root
	if typeof(Root) == "table" then
		PushItem(Root)

		if typeof(Root.GetDescendants) == "function" then
			local Ok, Descendants = pcall(Root.GetDescendants, Root)
			if Ok and typeof(Descendants) == "table" then
				for _, Inst in ipairs(Descendants) do
					PushItem(Inst)
					if #Items >= MAX_RENDER_ITEMS then
						break
					end
				end
			end
		end
	end

	for Inst in next, Session.Elements do
		PushItem(Inst)
		if #Items >= MAX_RENDER_ITEMS then
			break
		end
	end

	return Items
end

local function BuildRenderHtml(Session)
	local Items = CollectRenderItems(Session)
	local Parts = {}

	for _, Item in ipairs(Items) do
		if Item.ClassName == "TextLabel" then
			Parts[#Parts + 1] = `<div class="view-label">{EscapeHtml(Item.Text ~= "" and Item.Text or Item.Name)}</div>`
		elseif Item.ClassName == "TextBox" then
			local Placeholder = Item.PlaceholderText ~= "" and Item.PlaceholderText or Item.Text
			Parts[#Parts + 1] = `<input class="view-input" disabled placeholder="{EscapeHtml(Placeholder)}" value="{EscapeHtml(Item.Text)}" />`
		elseif Item.ClassName == "TextButton" then
			local Label = Item.Text ~= "" and Item.Text or Item.Name
			Parts[#Parts + 1] = `<button class="view-button" disabled>{EscapeHtml(Label)}</button>`
		elseif Item.ClassName == "Frame" then
			Parts[#Parts + 1] = `<div class="view-frame"></div>`
		end
	end

	if #Parts == 0 then
		return `<div class="view-label">No renderable GUI objects captured yet.</div>`
	end

	return table.concat(Parts, "\n")
end

local function HtmlResponse(Body, StatusCode)
	return {
		status = StatusCode or 200,
		headers = {
			["content-type"] = "text/html; charset=utf-8",
			["cache-control"] = "no-store",
		},
		body = Body or "",
	}
end

local function JsonResponse(Payload, StatusCode)
	return {
		status = StatusCode or 200,
		headers = {
			["content-type"] = "application/json; charset=utf-8",
			["cache-control"] = "no-store",
		},
		body = Payload,
	}
end

local function BuildSessionPage(Session)
	local SecondsLeft = SessionSecondsLeft(Session)
	local SafeId = EscapeHtml(Session.Id)
	local TriggerText = EscapeHtml(Session.TriggerText ~= "" and Session.TriggerText or "Key prompt detected")
	return [[<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>Larry Key Input</title>
<style>
body {
	margin: 0;
	min-height: 100vh;
	display: grid;
	place-items: center;
	background: #0f1722;
	color: #e8f0ff;
	font-family: "Bahnschrift", "Trebuchet MS", "Verdana", sans-serif;
}
.card {
	width: min(92vw, 460px);
	padding: 20px;
	border-radius: 16px;
	border: 1px solid #2d3d53;
	background: #141f2e;
}
h1 {
	margin: 0 0 10px;
	font-size: 22px;
}
p {
	margin: 0 0 12px;
	color: #a8b7ca;
	line-height: 1.4;
}
input {
	width: 100%;
	padding: 12px;
	border-radius: 10px;
	border: 1px solid #3c516e;
	background: #0e1722;
	color: #e8f0ff;
	margin: 8px 0 10px;
}
button {
	width: 100%;
	padding: 12px;
	border-radius: 10px;
	border: 0;
	background: #1f8fff;
	color: #ffffff;
	font-weight: 700;
	cursor: pointer;
}
button:disabled {
	opacity: 0.65;
	cursor: default;
}
#status {
	margin-top: 10px;
	min-height: 18px;
	color: #c7d7eb;
}
.meta {
	font-size: 12px;
	color: #8fa3bb;
}
code { font-family: "Consolas", "Courier New", monospace; }
</style>
</head>
<body>
<div class="card">
	<h1>Enter Key</h1>
	<p>Session: <code>]] .. SafeId .. [[</code></p>
	<p class="meta">Hint: ]] .. TriggerText .. [[</p>
	<p class="meta" id="ttl">Expires in ]] .. tostring(SecondsLeft) .. [[s</p>
	<form id="keyForm">
		<input id="keyInput" autocomplete="off" autofocus placeholder="Type key here" />
		<button id="submitButton" type="submit">Submit key</button>
	</form>
	<div id="status"></div>
</div>
<script>
const sessionId = "]] .. SafeId .. [[";
const statusEl = document.getElementById("status");
const ttlEl = document.getElementById("ttl");
const keyInput = document.getElementById("keyInput");
const submitButton = document.getElementById("submitButton");

document.getElementById("keyForm").addEventListener("submit", async (ev) => {
	ev.preventDefault();
	const value = keyInput.value || "";
	if (!value.trim()) {
		statusEl.textContent = "Enter a key before resuming the trace.";
		return;
	}
	const payload = new URLSearchParams();
	payload.set("key", value);
	submitButton.disabled = true;
	statusEl.textContent = "Submitting key to Larry...";
	const resp = await fetch(`/view/${sessionId}/submit`, {
		method: "POST",
		headers: { "content-type": "application/x-www-form-urlencoded" },
		body: payload.toString(),
	});
	if (resp.ok) {
		statusEl.textContent = "Key submitted. Larry resumed execution.";
		keyInput.disabled = true;
		submitButton.textContent = "Submitted";
	} else {
		statusEl.textContent = "Failed to submit key.";
		submitButton.disabled = false;
	}
});

let ttl = ]] .. tostring(SecondsLeft) .. [[;
setInterval(() => {
	ttl = Math.max(ttl - 1, 0);
	ttlEl.textContent = `Expires in ${ttl}s`;
	if (ttl <= 0) {
		statusEl.textContent = "Session expired.";
		keyInput.disabled = true;
		submitButton.disabled = true;
	}
}, 1000);
</script>
</body>
</html>]]
end

local function BuildIndexPage()
	local Rows = {}
	local Sessions = {}

	for _, Session in next, SessionsById do
		Sessions[#Sessions + 1] = Session
	end

	table.sort(Sessions, function(A, B)
		return A.CreatedAt > B.CreatedAt
	end)

	for _, Session in ipairs(Sessions) do
		local Id = EscapeHtml(Session.Id)
		local Left = SessionSecondsLeft(Session)
		local TriggerText = EscapeHtml(Session.TriggerText ~= "" and Session.TriggerText or "Key prompt detected")
		Rows[#Rows + 1] = [[
<a class="session-card" href="/view/]] .. Id .. [[">
	<div class="session-top">
		<div>
			<span class="meta-label">Session</span>
			<strong><code>]] .. Id .. [[</code></strong>
		</div>
		<div class="timer">]] .. tostring(Left) .. [[s</div>
	</div>
	<div class="session-body">]] .. TriggerText .. [[</div>
</a>]]
	end

	local ListHtml = #Rows > 0 and table.concat(Rows, "\n") or "<div>No active sessions.</div>"

	return [[<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>Larry Sessions</title>
<style>
body {
	margin: 0;
	padding: 20px;
	background: #0f1722;
	color: #e8f0ff;
	font-family: "Bahnschrift", "Trebuchet MS", "Verdana", sans-serif;
}
a { color: #9ad0ff; text-decoration: none; }
a:hover { text-decoration: underline; }
.session-card {
	display: block;
	padding: 12px;
	margin: 8px 0;
	border: 1px solid #2d3d53;
	border-radius: 10px;
	background: #141f2e;
}
</style>
</head>
<body>
	<h1>Active key sessions</h1>
]] .. ListHtml .. [[
</body>
</html>]]
end

local function HandleRequest(Request)
	CleanupExpiredSessions()

	local Path = tostring(Request.path or "/")
	local Method = string.upper(tostring(Request.method or "GET"))

	if Path == "/" and Method == "GET" then
		return HtmlResponse(BuildIndexPage(), 200)
	end

	local SessionId = string.match(Path, "^/view/(%d%d%d%d%d%d%d%d)$")
	if SessionId and Method == "GET" then
		local Session = SessionsById[SessionId]
		if Session == nil then
			return HtmlResponse("<h3>Session not found or expired.</h3>", 404)
		end

		return HtmlResponse(BuildSessionPage(Session), 200)
	end

	local SubmitId = string.match(Path, "^/view/(%d%d%d%d%d%d%d%d)/submit$")
	if SubmitId and Method == "POST" then
		local Session = SessionsById[SubmitId]
		if Session == nil then
			return JsonResponse('{"ok":false,"error":"session_not_found"}', 404)
		end

		local Form = ParseFormBody(Request.body)
		local KeyValue = Form.key or Form.Key or ""
		KeyValue = tostring(KeyValue)
		if KeyValue == "" then
			return JsonResponse('{"ok":false,"error":"empty_key"}', 400)
		end

		Session.State = SUBMITTING
		Session.SubmittedAt = os.clock()
		Session.LastKey = KeyValue
		ApplySubmittedKey(Session, KeyValue)
		Session.State = SUBMITTED

		local Left = SessionSecondsLeft(Session)
		local Payload = string.format(
			'{"ok":true,"submitted":true,"secondsLeft":%d,"state":"%s"}',
			Left,
			EscapeJson(Session.State)
		)
		DropSession(Session)
		DropAllSessions()
		MaybeStopServer()

		return JsonResponse(Payload, 200)
	end

	return HtmlResponse("<h3>Not found.</h3>", 404)
end

local function EnsureServer()
	if ServerStarted or ServerFailed then
		return
	end

	if not (LuneNet and LuneNet.http and typeof(LuneNet.http.serve) == "function") then
		ServerFailed = true
		return
	end

	local Ok, Result = pcall(function()
		return LuneNet.http.serve(PORT, {
			handleRequest = HandleRequest,
		})
	end)

	if not Ok or typeof(Result) ~= "table" then
		ServerFailed = true
		ServerError = tostring(Result)
		local Summary = string.match(ServerError, "^[^\r\n]+") or ServerError
		Logger.Print("View server failed:", Summary)
		return
	end

	Server = Result
	ServerStarted = true
end

local function EnsureSession(Root, TriggerText)
	local ExistingId = SessionByRoot[Root]
	if ExistingId then
		local Existing = SessionsById[ExistingId]
		if Existing then
			Existing.ExpiresAt = os.clock() + SESSION_TTL
			return Existing, false
		end
	end

	local Id = GenerateSessionId()
	local Session = {
		Id = Id,
		Root = Root,
		CreatedAt = os.clock(),
		ExpiresAt = os.clock() + SESSION_TTL,
		State = WAITING,
		TriggerText = TriggerText or "",
		Elements = setmetatable({}, { __mode = "k" }),
		TextBoxes = setmetatable({}, { __mode = "k" }),
		Buttons = setmetatable({}, { __mode = "k" }),
	}

	SessionsById[Id] = Session
	SessionByRoot[Root] = Id

	return Session, true
end

function View.ObserveProperty(Inst, PropName, Value)
	if typeof(Inst) ~= "table" or typeof(PropName) ~= "string" then
		return
	end

	local ClassName = GetClassName(Inst)
	if ClassName == nil then
		return
	end

	if string.find(ClassName, "Gui", 1, true) == nil
		and ClassName ~= "Frame"
		and ClassName ~= "TextLabel"
		and ClassName ~= "TextBox"
		and ClassName ~= "TextButton"
	then
		return
	end

	CleanupExpiredSessions()

	local Root = FindScreenGui(Inst)

	local TextValue = UnwrapString(Value)
	local IsHintProperty = PropName == "Text" or PropName == "PlaceholderText" or PropName == "Name"
	local IsHint = IsHintProperty and IsKeyHint(TextValue or "")
	local Session = nil
	local Created = false

	if IsHint then
		EnsureServer()
		if Root == nil then
			local Existing = FindRecentSession()
			if Existing ~= nil then
				Session = Existing
				Session.ExpiresAt = os.clock() + SESSION_TTL
				if Session.TriggerText == "" then
					Session.TriggerText = TextValue or ""
				end
			else
				Root = Inst
			end
		end

		if Session == nil then
			if Root == nil then
				Root = Inst
			end
			Session, Created = EnsureSession(Root, TextValue)
		end
		if Created then
			if ServerStarted then
				local Url = `http://localhost:{PORT}/view/{Session.Id}`
				Logger.Print("Key UI detected. Submit key at:", Url, `(expires in {SESSION_TTL}s)`)
			else
				Logger.Print("Key UI detected, but view server is unavailable on port", PORT)
			end
		end
	else
		if Root ~= nil then
			local ExistingId = SessionByRoot[Root]
			if ExistingId then
				Session = SessionsById[ExistingId]
			end
		end

		if Session == nil then
			Session = FindRecentSession()
		end
	end

	if Session == nil then
		return
	end

	Session.Elements[Inst] = true

	if ClassName == "TextBox" then
		Session.TextBoxes[Inst] = true
	end

	if ClassName == "TextButton" then
		local DisplayText = TextValue
		if DisplayText == nil then
			DisplayText = UnwrapString(ReadProperty(Inst, "Text"))
		end

		if IsLikelySubmit(DisplayText or "") then
			Session.Buttons[Inst] = true
		end
	end

	if Session.State == SUBMITTED and Session.LastKey ~= nil and ClassName == "TextBox" and PropName == "Text" then
		local CurrentText = UnwrapString(Value)
		if CurrentText ~= Session.LastKey then
			pcall(function()
				Inst.Text = Session.LastKey
			end)
		end
	end
end

function View.GetActiveSessions()
	local Out = {}
	for Id, Session in next, SessionsById do
		Out[Id] = {
			state = Session.State,
			secondsLeft = SessionSecondsLeft(Session),
		}
	end
	return Out
end

function View.Configure(State, Emitter, Beautifier)
	Runtime.State = State
	Runtime.Emitter = Emitter
	Runtime.Beautifier = Beautifier
end

function View.ResetRuntime()
	Runtime.State = nil
	Runtime.Emitter = nil
	Runtime.Beautifier = nil
end

function View.WaitForPendingSessions()
	CleanupExpiredSessions()
	MaybeStopServer()

	if not ServerStarted then
		return {
			waited = false,
			pending = PendingSessionCount(),
			serverStarted = false,
			serverError = ServerError,
		}
	end

	local Pending = PendingSessionCount()
	if Pending <= 0 then
		return {
			waited = false,
			pending = 0,
			serverStarted = true,
		}
	end

	local Start = os.clock()
	local LastPending = Pending

	Logger.Print("Waiting for key-system input...", Pending, "session(s)")

	while true do
		CleanupExpiredSessions()
		Pending = PendingSessionCount()
		if Pending <= 0 then
			break
		end

		if os.clock() - Start >= MAX_WAIT_SECONDS then
			Logger.Print("Key wait timed out; continuing trace without submitted key.")
			break
		end

		if Pending ~= LastPending then
			LastPending = Pending
			Logger.Print("Key-system sessions remaining:", Pending)
		end

		if LuneTask and typeof(LuneTask.wait) == "function" then
			pcall(LuneTask.wait, 0.1)
		else
			local Target = os.clock() + 0.1
			while os.clock() < Target do end
		end
	end

	MaybeStopServer()

	return {
		waited = true,
		pending = 0,
		serverStarted = true,
		elapsed = os.clock() - Start,
	}
end

return View