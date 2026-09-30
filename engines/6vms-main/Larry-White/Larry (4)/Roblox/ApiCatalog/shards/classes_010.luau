return {
	Classes = {
		BillboardGui = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {
				GetScreenSpaceBounds = {
					{
						Arguments = "",
						HasVariadicArguments = false,
						IsVoid = false,
						ModifierFlags = {},
						Name = "GetScreenSpaceBounds",
						ParsedArguments = {},
						Raw = "Function BillboardGui:GetScreenSpaceBounds() -> any {🛠️UI} {🔒RobloxScript}",
						RequiredArgumentCount = 0,
						ReturnType = "any",
					},
				},
			},
			Functions = {
				GetScreenSpaceBounds = {
					Arguments = "",
					HasVariadicArguments = false,
					IsVoid = false,
					ModifierFlags = {},
					Name = "GetScreenSpaceBounds",
					ParsedArguments = {},
					Raw = "Function BillboardGui:GetScreenSpaceBounds() -> any {🛠️UI} {🔒RobloxScript}",
					RequiredArgumentCount = 0,
					ReturnType = "any",
				},
			},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BillboardGui",
			Properties = {
				Active = {
					ModifierFlags = {},
					Name = "Active",
					Raw = "boolean {🛠️UI}",
					Type = "boolean",
				},
				Adornee = {
					ModifierFlags = {},
					Name = "Adornee",
					Raw = "Instance? {🛠️UI}",
					Type = "Instance?",
				},
				AlwaysOnTop = {
					ModifierFlags = {},
					Name = "AlwaysOnTop",
					Raw = "boolean {🛠️UI}",
					Type = "boolean",
				},
				Brightness = {
					ModifierFlags = {},
					Name = "Brightness",
					Raw = "number {🛠️UI}",
					Type = "number",
				},
				ClipsDescendants = {
					ModifierFlags = {},
					Name = "ClipsDescendants",
					Raw = "boolean {🛠️UI}",
					Type = "boolean",
				},
				CurrentDistance = {
					ModifierFlags = {
						ReadOnly = true,
					},
					Name = "CurrentDistance",
					Raw = "number {🛠️UI} [ReadOnly]",
					Type = "number",
				},
				DistanceLowerLimit = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "DistanceLowerLimit",
					Raw = "number {🛠️UI} [Deprecated]",
					Type = "number",
				},
				DistanceStep = {
					ModifierFlags = {
						NotReplicated = true,
						["📁LoadOnly"] = true,
					},
					Name = "DistanceStep",
					Raw = "number {🛠️UI} [📁LoadOnly] [NotReplicated]",
					Type = "number",
				},
				DistanceUpperLimit = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "DistanceUpperLimit",
					Raw = "number {🛠️UI} [Deprecated]",
					Type = "number",
				},
				ExtentsOffset = {
					ModifierFlags = {},
					Name = "ExtentsOffset",
					Raw = "Vector3 {🛠️UI}",
					Type = "Vector3",
				},
				ExtentsOffsetWorldSpace = {
					ModifierFlags = {},
					Name = "ExtentsOffsetWorldSpace",
					Raw = "Vector3 {🛠️UI}",
					Type = "Vector3",
				},
				LightInfluence = {
					ModifierFlags = {},
					Name = "LightInfluence",
					Raw = "number {🛠️UI}",
					Type = "number",
				},
				MaxDistance = {
					ModifierFlags = {},
					Name = "MaxDistance",
					Raw = "number {🛠️UI}",
					Type = "number",
				},
				PlayerToHideFrom = {
					ModifierFlags = {},
					Name = "PlayerToHideFrom",
					Raw = "Instance? {🛠️UI}",
					Type = "Instance?",
				},
				Size = {
					ModifierFlags = {},
					Name = "Size",
					Raw = "UDim2 {🛠️UI}",
					Type = "UDim2",
				},
				SizeOffset = {
					ModifierFlags = {},
					Name = "SizeOffset",
					Raw = "Vector2 {🛠️UI}",
					Type = "Vector2",
				},
				StudsOffset = {
					ModifierFlags = {},
					Name = "StudsOffset",
					Raw = "Vector3 {🛠️UI}",
					Type = "Vector3",
				},
				StudsOffsetWorldSpace = {
					ModifierFlags = {},
					Name = "StudsOffsetWorldSpace",
					Raw = "Vector3 {🛠️UI}",
					Type = "Vector3",
				},
			},
			Super = "LayerCollector",
		},
		BinaryStringValue = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {
				Changed = {
					Arguments = "value: BinaryString",
					ModifierFlags = {},
					Name = "Changed",
					Raw = "Event BinaryStringValue.Changed(value: BinaryString)",
				},
			},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BinaryStringValue",
			Properties = {
				Value = {
					ModifierFlags = {
						Hidden = true,
						NotScriptable = true,
					},
					Name = "Value",
					Raw = "BinaryString [Hidden] [NotScriptable]",
					Type = "BinaryString",
				},
			},
			Super = "ValueBase",
		},
		BindableEvent = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {
				Event = {
					Arguments = "arguments: ...any",
					ModifierFlags = {},
					Name = "Event",
					Raw = "Event BindableEvent.Event(arguments: ...any)",
				},
			},
			FunctionOverloads = {
				Fire = {
					{
						Arguments = "arguments: ...any",
						HasVariadicArguments = true,
						IsVoid = false,
						ModifierFlags = {},
						Name = "Fire",
						ParsedArguments = {
							{
								Name = "arguments",
								Optional = true,
								Raw = "arguments: ...any",
								Type = "any",
								Variadic = true,
							},
						},
						Raw = "Function BindableEvent:Fire(arguments: ...any) -> () {🧬Safe}",
						RequiredArgumentCount = 0,
						ReturnType = "()",
					},
				},
			},
			Functions = {
				Fire = {
					Arguments = "arguments: ...any",
					HasVariadicArguments = true,
					IsVoid = false,
					ModifierFlags = {},
					Name = "Fire",
					ParsedArguments = {
						{
							Name = "arguments",
							Optional = true,
							Raw = "arguments: ...any",
							Type = "any",
							Variadic = true,
						},
					},
					Raw = "Function BindableEvent:Fire(arguments: ...any) -> () {🧬Safe}",
					RequiredArgumentCount = 0,
					ReturnType = "()",
				},
			},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BindableEvent",
			Properties = {},
			Super = "Instance",
		},
		BindableFunction = {
			CallbackOverloads = {
				OnInvoke = {
					{
						Arguments = "arguments: ...any",
						HasVariadicArguments = true,
						ModifierFlags = {},
						Name = "OnInvoke",
						ParsedArguments = {
							{
								Name = "arguments",
								Optional = true,
								Raw = "arguments: ...any",
								Type = "any",
								Variadic = true,
							},
						},
						Raw = "Callback BindableFunction.OnInvoke(arguments: ...any) -> ...any",
						RequiredArgumentCount = 0,
						ReturnType = "...any",
					},
				},
			},
			Callbacks = {
				OnInvoke = {
					Arguments = "arguments: ...any",
					HasVariadicArguments = true,
					ModifierFlags = {},
					Name = "OnInvoke",
					ParsedArguments = {
						{
							Name = "arguments",
							Optional = true,
							Raw = "arguments: ...any",
							Type = "any",
							Variadic = true,
						},
					},
					Raw = "Callback BindableFunction.OnInvoke(arguments: ...any) -> ...any",
					RequiredArgumentCount = 0,
					ReturnType = "...any",
				},
			},
			Events = {},
			FunctionOverloads = {
				Invoke = {
					{
						Arguments = "arguments: ...any",
						HasVariadicArguments = true,
						IsVoid = false,
						ModifierFlags = {
							Yields = true,
						},
						Name = "Invoke",
						ParsedArguments = {
							{
								Name = "arguments",
								Optional = true,
								Raw = "arguments: ...any",
								Type = "any",
								Variadic = true,
							},
						},
						Raw = "Function BindableFunction:Invoke(arguments: ...any) -> ...any [Yields]",
						RequiredArgumentCount = 0,
						ReturnType = "...any",
					},
				},
			},
			Functions = {
				Invoke = {
					Arguments = "arguments: ...any",
					HasVariadicArguments = true,
					IsVoid = false,
					ModifierFlags = {
						Yields = true,
					},
					Name = "Invoke",
					ParsedArguments = {
						{
							Name = "arguments",
							Optional = true,
							Raw = "arguments: ...any",
							Type = "any",
							Variadic = true,
						},
					},
					Raw = "Function BindableFunction:Invoke(arguments: ...any) -> ...any [Yields]",
					RequiredArgumentCount = 0,
					ReturnType = "...any",
				},
			},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BindableFunction",
			Properties = {},
			Super = "Instance",
		},
		BlockMesh = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BlockMesh",
			Properties = {},
			Super = "BevelMesh",
		},
		BloomEffect = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BloomEffect",
			Properties = {
				Intensity = {
					ModifierFlags = {},
					Name = "Intensity",
					Raw = "number {🛠️Environment}",
					Type = "number",
				},
				Size = {
					ModifierFlags = {},
					Name = "Size",
					Raw = "number {🛠️Environment}",
					Type = "number",
				},
				Threshold = {
					ModifierFlags = {},
					Name = "Threshold",
					Raw = "number {🛠️Environment}",
					Type = "number",
				},
			},
			Super = "PostEffect",
		},
		BlurEffect = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BlurEffect",
			Properties = {
				Size = {
					ModifierFlags = {},
					Name = "Size",
					Raw = "number {🛠️Environment}",
					Type = "number",
				},
			},
			Super = "PostEffect",
		},
		BodyAngularVelocity = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				Deprecated = true,
			},
			Modifiers = "[Deprecated]",
			Name = "BodyAngularVelocity",
			Properties = {
				AngularVelocity = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "AngularVelocity",
					Raw = "Vector3 {🛠️Physics} [Deprecated]",
					Type = "Vector3",
				},
				MaxTorque = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "MaxTorque",
					Raw = "Vector3 {🛠️Physics} [Deprecated]",
					Type = "Vector3",
				},
				P = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "P",
					Raw = "number {🛠️Physics} [Deprecated]",
					Type = "number",
				},
				angularvelocity = {
					ModifierFlags = {
						Deprecated = true,
						NotReplicated = true,
						["📁LoadOnly"] = true,
					},
					Name = "angularvelocity",
					Raw = "Vector3 {🛠️Physics} [📁LoadOnly] [NotReplicated] [Deprecated] [Deprecated]",
					Type = "Vector3",
				},
				maxTorque = {
					ModifierFlags = {
						Deprecated = true,
						NotReplicated = true,
						["📁LoadOnly"] = true,
					},
					Name = "maxTorque",
					Raw = "Vector3 {🛠️Physics} [📁LoadOnly] [NotReplicated] [Deprecated] [Deprecated]",
					Type = "Vector3",
				},
			},
			Super = "BodyMover",
		},
		BodyColors = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {},
			Modifiers = "",
			Name = "BodyColors",
			Properties = {
				HeadColor = {
					ModifierFlags = {
						["📁LoadOnly"] = true,
					},
					Name = "HeadColor",
					Raw = "BrickColor {🛠️AvatarAppearance} [📁LoadOnly]",
					Type = "BrickColor",
				},
				HeadColor3 = {
					ModifierFlags = {},
					Name = "HeadColor3",
					Raw = "Color3 {🛠️AvatarAppearance}",
					Type = "Color3",
				},
				LeftArmColor = {
					ModifierFlags = {
						["📁LoadOnly"] = true,
					},
					Name = "LeftArmColor",
					Raw = "BrickColor {🛠️AvatarAppearance} [📁LoadOnly]",
					Type = "BrickColor",
				},
				LeftArmColor3 = {
					ModifierFlags = {},
					Name = "LeftArmColor3",
					Raw = "Color3 {🛠️AvatarAppearance}",
					Type = "Color3",
				},
				LeftLegColor = {
					ModifierFlags = {
						["📁LoadOnly"] = true,
					},
					Name = "LeftLegColor",
					Raw = "BrickColor {🛠️AvatarAppearance} [📁LoadOnly]",
					Type = "BrickColor",
				},
				LeftLegColor3 = {
					ModifierFlags = {},
					Name = "LeftLegColor3",
					Raw = "Color3 {🛠️AvatarAppearance}",
					Type = "Color3",
				},
				RightArmColor = {
					ModifierFlags = {
						["📁LoadOnly"] = true,
					},
					Name = "RightArmColor",
					Raw = "BrickColor {🛠️AvatarAppearance} [📁LoadOnly]",
					Type = "BrickColor",
				},
				RightArmColor3 = {
					ModifierFlags = {},
					Name = "RightArmColor3",
					Raw = "Color3 {🛠️AvatarAppearance}",
					Type = "Color3",
				},
				RightLegColor = {
					ModifierFlags = {
						["📁LoadOnly"] = true,
					},
					Name = "RightLegColor",
					Raw = "BrickColor {🛠️AvatarAppearance} [📁LoadOnly]",
					Type = "BrickColor",
				},
				RightLegColor3 = {
					ModifierFlags = {},
					Name = "RightLegColor3",
					Raw = "Color3 {🛠️AvatarAppearance}",
					Type = "Color3",
				},
				TorsoColor = {
					ModifierFlags = {
						["📁LoadOnly"] = true,
					},
					Name = "TorsoColor",
					Raw = "BrickColor {🛠️AvatarAppearance} [📁LoadOnly]",
					Type = "BrickColor",
				},
				TorsoColor3 = {
					ModifierFlags = {},
					Name = "TorsoColor3",
					Raw = "Color3 {🛠️AvatarAppearance}",
					Type = "Color3",
				},
			},
			Super = "CharacterAppearance",
		},
		BodyForce = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				Deprecated = true,
			},
			Modifiers = "[Deprecated]",
			Name = "BodyForce",
			Properties = {
				Force = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "Force",
					Raw = "Vector3 {🛠️Physics} [Deprecated]",
					Type = "Vector3",
				},
				force = {
					ModifierFlags = {
						Deprecated = true,
						NotReplicated = true,
						["📁LoadOnly"] = true,
					},
					Name = "force",
					Raw = "Vector3 {🛠️Physics} [📁LoadOnly] [NotReplicated] [Deprecated] [Deprecated]",
					Type = "Vector3",
				},
			},
			Super = "BodyMover",
		},
		BodyGyro = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				Deprecated = true,
			},
			Modifiers = "[Deprecated]",
			Name = "BodyGyro",
			Properties = {
				CFrame = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "CFrame",
					Raw = "CFrame {🛠️Physics} [Deprecated]",
					Type = "CFrame",
				},
				D = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "D",
					Raw = "number {🛠️Physics} [Deprecated]",
					Type = "number",
				},
				MaxTorque = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "MaxTorque",
					Raw = "Vector3 {🛠️Physics} [Deprecated]",
					Type = "Vector3",
				},
				P = {
					ModifierFlags = {
						Deprecated = true,
					},
					Name = "P",
					Raw = "number {🛠️Physics} [Deprecated]",
					Type = "number",
				},
				cframe = {
					ModifierFlags = {
						Deprecated = true,
						NotReplicated = true,
						["📁LoadOnly"] = true,
					},
					Name = "cframe",
					Raw = "CFrame {🛠️Physics} [📁LoadOnly] [NotReplicated] [Deprecated] [Deprecated]",
					Type = "CFrame",
				},
				maxTorque = {
					ModifierFlags = {
						Deprecated = true,
						NotReplicated = true,
						["📁LoadOnly"] = true,
					},
					Name = "maxTorque",
					Raw = "Vector3 {🛠️Physics} [📁LoadOnly] [NotReplicated] [Deprecated] [Deprecated]",
					Type = "Vector3",
				},
			},
			Super = "BodyMover",
		},
		BodyMover = {
			CallbackOverloads = {},
			Callbacks = {},
			Events = {},
			FunctionOverloads = {},
			Functions = {},
			ModifierFlags = {
				Deprecated = true,
				NotCreatable = true,
			},
			Modifiers = "[NotCreatable] [Deprecated]",
			Name = "BodyMover",
			Properties = {},
			Super = "Instance",
		},
	},
}