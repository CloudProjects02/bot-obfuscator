return {
	Classes = {
		Motor = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {
				SetDesiredAngle = {
					{
						Arguments = "value: number",
						HasVariadicArguments = false,
						IsVoid = false,
						ModifierFlags = {},
						Name = "SetDesiredAngle",
						ParsedArguments = {
							{
								Name = "value",
								Optional = false,
								Raw = "value: number",
								Type = "number",
								Variadic = false,
							},
						},
						Raw = "Function Motor:SetDesiredAngle(value: number) -> () {🛠️Physics}",
						RequiredArgumentCount = 1,
						ReturnType = "()",
					},
				},
			},
			Functions = {
				SetDesiredAngle = {
					Arguments = "value: number",
					HasVariadicArguments = false,
					IsVoid = false,
					ModifierFlags = {},
					Name = "SetDesiredAngle",
					ParsedArguments = {
						{
							Name = "value",
							Optional = false,
							Raw = "value: number",
							Type = "number",
							Variadic = false,
						},
					},
					Raw = "Function Motor:SetDesiredAngle(value: number) -> () {🛠️Physics}",
					RequiredArgumentCount = 1,
					ReturnType = "()",
				},
			},
			ModifierFlags = {},
			Modifiers = "",
			Name = "Motor",
			Properties = {
				CurrentAngle = {
					ModifierFlags = {
						NotReplicated = true,
						["📁LoadOnly"] = true,
					},
					Name = "CurrentAngle",
					Raw = "number {🛠️Physics} [📁LoadOnly] [NotReplicated]",
					Type = "number",
				},
				DesiredAngle = {
					ModifierFlags = {},
					Name = "DesiredAngle",
					Raw = "number {🛠️Physics}",
					Type = "number",
				},
				MaxVelocity = {
					ModifierFlags = {},
					Name = "MaxVelocity",
					Raw = "number {🛠️Physics}",
					Type = "number",
				},
				ReplicateCurrentAngle = {
					ModifierFlags = {
						Hidden = true,
						NotScriptable = true,
					},
					Name = "ReplicateCurrentAngle",
					Raw = "number {🛠️Physics} {RobloxEngine} [Hidden] [NotScriptable]",
					Type = "number {🛠️Physics} {RobloxEngine}",
				},
			},
			Super = "JointInstance",
		},
		Motor6D = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {},
			Modifiers = "",
			Name = "Motor6D",
			Properties = {
				ChildName = {
					ModifierFlags = {
						NotScriptable = true,
						ReadOnly = true,
					},
					Name = "ChildName",
					Raw = "string {🛠️Physics} [ReadOnly] [NotScriptable]",
					Type = "string",
				},
				ParentName = {
					ModifierFlags = {
						NotScriptable = true,
						ReadOnly = true,
					},
					Name = "ParentName",
					Raw = "string {🛠️Physics} [ReadOnly] [NotScriptable]",
					Type = "string",
				},
				ReplicateCurrentAngle6D = {
					ModifierFlags = {
						Hidden = true,
						NotScriptable = true,
					},
					Name = "ReplicateCurrentAngle6D",
					Raw = "Vector3 {🛠️Physics} {RobloxEngine} [Hidden] [NotScriptable]",
					Type = "Vector3 {🛠️Physics} {RobloxEngine}",
				},
				ReplicateCurrentOffset6D = {
					ModifierFlags = {
						Hidden = true,
						NotScriptable = true,
					},
					Name = "ReplicateCurrentOffset6D",
					Raw = "Vector3 {🛠️Physics} {RobloxEngine} [Hidden] [NotScriptable]",
					Type = "Vector3 {🛠️Physics} {RobloxEngine}",
				},
				Transform = {
					ModifierFlags = {
						Hidden = true,
						NotReplicated = true,
					},
					Name = "Transform",
					Raw = "CFrame {🛠️Physics} [Hidden] [NotReplicated]",
					Type = "CFrame",
				},
			},
			Super = "Motor",
		},
		MotorFeature = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				Deprecated = true,
			},
			Modifiers = "[Deprecated]",
			Name = "MotorFeature",
			Properties = {},
			Super = "Feature",
		},
		Mouse = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {
				Button1Down = {
					Arguments = "",
					ModifierFlags = {},
					Name = "Button1Down",
					Raw = "Event Mouse.Button1Down() {🛠️Input}",
				},
				Button1Up = {
					Arguments = "",
					ModifierFlags = {},
					Name = "Button1Up",
					Raw = "Event Mouse.Button1Up() {🛠️Input}",
				},
				Button2Down = {
					Arguments = "",
					ModifierFlags = {},
					Name = "Button2Down",
					Raw = "Event Mouse.Button2Down() {🛠️Input}",
				},
				Button2Up = {
					Arguments = "",
					ModifierFlags = {},
					Name = "Button2Up",
					Raw = "Event Mouse.Button2Up() {🛠️Input}",
				},
				Idle = {
					Arguments = "",
					ModifierFlags = {},
					Name = "Idle",
					Raw = "Event Mouse.Idle() {🛠️Input}",
				},
				KeyDown = {
					Arguments = "key: string",
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "KeyDown",
					Raw = "Event Mouse.KeyDown(key: string) {🛠️Input} [Deprecated]",
				},
				KeyUp = {
					Arguments = "key: string",
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "KeyUp",
					Raw = "Event Mouse.KeyUp(key: string) {🛠️Input} [Deprecated]",
				},
				Move = {
					Arguments = "",
					ModifierFlags = {},
					Name = "Move",
					Raw = "Event Mouse.Move() {🛠️Input}",
				},
				WheelBackward = {
					Arguments = "",
					ModifierFlags = {},
					Name = "WheelBackward",
					Raw = "Event Mouse.WheelBackward() {🛠️Input}",
				},
				WheelForward = {
					Arguments = "",
					ModifierFlags = {},
					Name = "WheelForward",
					Raw = "Event Mouse.WheelForward() {🛠️Input}",
				},
				keyDown = {
					Arguments = "key: string",
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "keyDown",
					Raw = "Event Mouse.keyDown(key: string) {🛠️Input} [Deprecated]",
				},
			},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				NotCreatable = true,
			},
			Modifiers = "[NotCreatable]",
			Name = "Mouse",
			Properties = {
				Hit = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "Hit",
					Raw = "CFrame {🛠️Input} [ReadOnly]",
					Type = "CFrame",
				},
				Icon = {
					ModifierFlags = {},
					Name = "Icon",
					Raw = "string {🛠️Input}",
					Type = "string",
				},
				IconContent = {
					ModifierFlags = {},
					Name = "IconContent",
					Raw = "Content {🛠️Input}",
					Type = "Content",
				},
				Origin = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "Origin",
					Raw = "CFrame {🛠️Input} [ReadOnly]",
					Type = "CFrame",
				},
				Target = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "Target",
					Raw = "BasePart? {🛠️Input} [ReadOnly]",
					Type = "BasePart?",
				},
				TargetFilter = {
					ModifierFlags = {},
					Name = "TargetFilter",
					Raw = "Instance? {🛠️Input}",
					Type = "Instance?",
				},
				TargetSurface = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "TargetSurface",
					Raw = "Enum.NormalId {🛠️Input} [ReadOnly]",
					Type = "Enum.NormalId",
				},
				UnitRay = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "UnitRay",
					Raw = "Ray {🛠️Input} [ReadOnly]",
					Type = "Ray",
				},
				ViewSizeX = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "ViewSizeX",
					Raw = "number {🛠️Input} [ReadOnly]",
					Type = "number",
				},
				ViewSizeY = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "ViewSizeY",
					Raw = "number {🛠️Input} [ReadOnly]",
					Type = "number",
				},
				X = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "X",
					Raw = "number {🛠️Input} [ReadOnly]",
					Type = "number",
				},
				Y = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "Y",
					Raw = "number {🛠️Input} [ReadOnly]",
					Type = "number",
				},
				hit = {
					ModifierFlags = {
						Deprecated = true,
						Hidden = true,
						ReadOnly = true,
					},
					Name = "hit",
					Raw = "CFrame {🛠️Input} [Hidden] [ReadOnly] [Deprecated]",
					Type = "CFrame",
				},
				target = {
					ModifierFlags = {
						Deprecated = true,
						ReadOnly = true,
					},
					Name = "target",
					Raw = "BasePart? {🛠️Input} [ReadOnly] [Deprecated]",
					Type = "BasePart?",
				},
			},
			Super = "Instance",
		},
		MouseService = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {
				MouseEnterStudioViewport = {
					Arguments = "",
					ModifierFlags = {},
					Name = "MouseEnterStudioViewport",
					Raw = "Event MouseService.MouseEnterStudioViewport() {🛠️Input} {🔒RobloxScript}",
				},
				MouseLeaveStudioViewport = {
					Arguments = "",
					ModifierFlags = {},
					Name = "MouseLeaveStudioViewport",
					Raw = "Event MouseService.MouseLeaveStudioViewport() {🛠️Input} {🔒RobloxScript}",
				},
			},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				NotCreatable = true,
				NotReplicated = true,
				Service = true,
			},
			Modifiers = "[NotCreatable] [Service] [NotReplicated]",
			Name = "MouseService",
			Properties = {},
			Super = "Instance",
		},
		MultipleDocumentInterfaceInstance = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {
				DataModelSessionEnded = {
					Arguments = "dataModelSession: Instance",
					ModifierFlags = {},
					Name = "DataModelSessionEnded",
					Raw = "Event MultipleDocumentInterfaceInstance.DataModelSessionEnded(dataModelSession: Instance) {🔒RobloxScript}",
				},
				DataModelSessionStarted = {
					Arguments = "dataModelSession: Instance",
					ModifierFlags = {},
					Name = "DataModelSessionStarted",
					Raw = "Event MultipleDocumentInterfaceInstance.DataModelSessionStarted(dataModelSession: Instance) {🔒RobloxScript}",
				},
			},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				NotCreatable = true,
				NotReplicated = true,
			},
			Modifiers = "{🔒Plugin} [NotCreatable] [NotReplicated]",
			Name = "MultipleDocumentInterfaceInstance",
			Properties = {
				FocusedDataModelSession = {
					ModifierFlags = {
						Hidden = true,
						ReadOnly = true,
					},
					Name = "FocusedDataModelSession",
					Raw = "DataModelSession? {RobloxScript} [Hidden] [ReadOnly]",
					Type = "DataModelSession?",
				},
			},
			Super = "Instance",
		},
		NegateOperation = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {},
			Modifiers = "",
			Name = "NegateOperation",
			Properties = {
				PreviousOperation = {
					ModifierFlags = {
						Hidden = true,
						NotReplicated = true,
						NotScriptable = true,
					},
					Name = "PreviousOperation",
					Raw = "Enum.NegateOperationHiddenHistory {🛠️Basic | CSG} {RobloxEngine} [Hidden] [NotReplicated] [NotScriptable]",
					Type = "Enum.NegateOperationHiddenHistory {🛠️Basic | CSG} {RobloxEngine}",
				},
			},
			Super = "PartOperation",
		},
		NetworkClient = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {
				ConnectionAccepted = {
					Arguments = "peer: string, replicator: Instance",
					ModifierFlags = {},
					Name = "ConnectionAccepted",
					Raw = "Event NetworkClient.ConnectionAccepted(peer: string, replicator: Instance)",
				},
				ConnectionFailed = {
					Arguments = "peer: string, code: number",
					ModifierFlags = {},
					Name = "ConnectionFailed",
					Raw = "Event NetworkClient.ConnectionFailed(peer: string, code: number)",
				},
			},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				NotCreatable = true,
				NotReplicated = true,
				Service = true,
			},
			Modifiers = "[NotCreatable] [Service] [NotReplicated]",
			Name = "NetworkClient",
			Properties = {},
			Super = "NetworkPeer",
		},
		NetworkMarker = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {
				Received = {
					Arguments = "",
					ModifierFlags = {},
					Name = "Received",
					Raw = "Event NetworkMarker.Received()",
				},
			},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				NotBrowsable = true,
				NotCreatable = true,
			},
			Modifiers = "[NotCreatable] [NotBrowsable]",
			Name = "NetworkMarker",
			Properties = {},
			Super = "Instance",
		},
		NetworkPeer = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {
				InitializeRemoteAllowList = {
					{
						Arguments = "names: { any }",
						HasVariadicArguments = false,
						IsVoid = false,
						ModifierFlags = {},
						Name = "InitializeRemoteAllowList",
						ParsedArguments = {
							{
								Name = "names",
								Optional = false,
								Raw = "names: { any }",
								Type = "{ any }",
								Variadic = false,
							},
						},
						Raw = "Function NetworkPeer:InitializeRemoteAllowList(names: { any }) -> () {🔒RobloxScript}",
						RequiredArgumentCount = 1,
						ReturnType = "()",
					},
				},
				SetOutgoingKBPSLimit = {
					{
						Arguments = "limit: number",
						HasVariadicArguments = false,
						IsVoid = false,
						ModifierFlags = {},
						Name = "SetOutgoingKBPSLimit",
						ParsedArguments = {
							{
								Name = "limit",
								Optional = false,
								Raw = "limit: number",
								Type = "number",
								Variadic = false,
							},
						},
						Raw = "Function NetworkPeer:SetOutgoingKBPSLimit(limit: number) -> () {🔒Plugin}",
						RequiredArgumentCount = 1,
						ReturnType = "()",
					},
				},
			},
			Functions = {
				InitializeRemoteAllowList = {
					Arguments = "names: { any }",
					HasVariadicArguments = false,
					IsVoid = false,
					ModifierFlags = {},
					Name = "InitializeRemoteAllowList",
					ParsedArguments = {
						{
							Name = "names",
							Optional = false,
							Raw = "names: { any }",
							Type = "{ any }",
							Variadic = false,
						},
					},
					Raw = "Function NetworkPeer:InitializeRemoteAllowList(names: { any }) -> () {🔒RobloxScript}",
					RequiredArgumentCount = 1,
					ReturnType = "()",
				},
				SetOutgoingKBPSLimit = {
					Arguments = "limit: number",
					HasVariadicArguments = false,
					IsVoid = false,
					ModifierFlags = {},
					Name = "SetOutgoingKBPSLimit",
					ParsedArguments = {
						{
							Name = "limit",
							Optional = false,
							Raw = "limit: number",
							Type = "number",
							Variadic = false,
						},
					},
					Raw = "Function NetworkPeer:SetOutgoingKBPSLimit(limit: number) -> () {🔒Plugin}",
					RequiredArgumentCount = 1,
					ReturnType = "()",
				},
			},
			ModifierFlags = {
				NotBrowsable = true,
				NotCreatable = true,
			},
			Modifiers = "[NotCreatable] [NotBrowsable]",
			Name = "NetworkPeer",
			Properties = {},
			Super = "Instance",
		},
		NetworkReplicator = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {
				GetPlayer = {
					{
						Arguments = "",
						HasVariadicArguments = false,
						IsVoid = false,
						ModifierFlags = {},
						Name = "GetPlayer",
						ParsedArguments = {},
						Raw = "Function NetworkReplicator:GetPlayer() -> Instance? {🛠️Network | Players}",
						RequiredArgumentCount = 0,
						ReturnType = "Instance?",
					},
				},
			},
			Functions = {
				GetPlayer = {
					Arguments = "",
					HasVariadicArguments = false,
					IsVoid = false,
					ModifierFlags = {},
					Name = "GetPlayer",
					ParsedArguments = {},
					Raw = "Function NetworkReplicator:GetPlayer() -> Instance? {🛠️Network | Players}",
					RequiredArgumentCount = 0,
					ReturnType = "Instance?",
				},
			},
			ModifierFlags = {
				NotCreatable = true,
				NotReplicated = true,
			},
			Modifiers = "[NotCreatable] [NotReplicated]",
			Name = "NetworkReplicator",
			Properties = {},
			Super = "Instance",
		},
		NetworkServer = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {
				EncryptStringForPlayerId = {
					{
						Arguments = "toEncrypt: string, playerId: number",
						HasVariadicArguments = false,
						IsVoid = false,
						ModifierFlags = {},
						Name = "EncryptStringForPlayerId",
						ParsedArguments = {
							{
								Name = "toEncrypt",
								Optional = false,
								Raw = "toEncrypt: string",
								Type = "string",
								Variadic = false,
							},
							{
								Name = "playerId",
								Optional = false,
								Raw = "playerId: number",
								Type = "number",
								Variadic = false,
							},
						},
						Raw = "Function NetworkServer:EncryptStringForPlayerId(toEncrypt: string, playerId: number) -> string {🛠️Network}",
						RequiredArgumentCount = 2,
						ReturnType = "string",
					},
				},
			},
			Functions = {
				EncryptStringForPlayerId = {
					Arguments = "toEncrypt: string, playerId: number",
					HasVariadicArguments = false,
					IsVoid = false,
					ModifierFlags = {},
					Name = "EncryptStringForPlayerId",
					ParsedArguments = {
						{
							Name = "toEncrypt",
							Optional = false,
							Raw = "toEncrypt: string",
							Type = "string",
							Variadic = false,
						},
						{
							Name = "playerId",
							Optional = false,
							Raw = "playerId: number",
							Type = "number",
							Variadic = false,
						},
					},
					Raw = "Function NetworkServer:EncryptStringForPlayerId(toEncrypt: string, playerId: number) -> string {🛠️Network}",
					RequiredArgumentCount = 2,
					ReturnType = "string",
				},
			},
			ModifierFlags = {
				NotCreatable = true,
				NotReplicated = true,
				Service = true,
			},
			Modifiers = "[NotCreatable] [Service] [NotReplicated]",
			Name = "NetworkServer",
			Properties = {},
			Super = "NetworkPeer",
		},
	},
}