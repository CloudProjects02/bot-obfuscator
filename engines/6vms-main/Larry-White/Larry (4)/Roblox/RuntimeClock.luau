local RuntimeClock = {}

local State = {
	Now = 0,
	FrameDelta = 1 / 60,
	ServerEpoch = os.time(),
	FpsCap = 0,
}

function RuntimeClock.Reset()
	State.Now = 0
	State.FrameDelta = 1 / 60
	State.ServerEpoch = os.time()
	State.FpsCap = 0
end

function RuntimeClock.SetFrameRate(Fps)
	local Numeric = tonumber(Fps) or 0
	if Numeric < 0 then
		Numeric = 0
	end

	State.FpsCap = Numeric
	if Numeric > 0 then
		State.FrameDelta = 1 / Numeric
	else
		State.FrameDelta = 1 / 240
	end
end

function RuntimeClock.GetFrameRate()
	return State.FpsCap
end

function RuntimeClock.Advance(Delta)
	local Step = tonumber(Delta)
	if Step == nil or Step <= 0 then
		Step = State.FrameDelta
	end

	State.FrameDelta = Step
	State.Now += Step
	return State.Now
end

function RuntimeClock.Touch()
	return State.Now
end

function RuntimeClock.Now()
	return State.Now
end

function RuntimeClock.GetFrameDelta()
	return State.FrameDelta
end

function RuntimeClock.GetServerNow()
	return State.ServerEpoch + State.Now
end

return RuntimeClock