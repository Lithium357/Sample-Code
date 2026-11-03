-- Lua 5.4 specifically: lua5.4 closing_iterator.lua
-- The fourth generic-for value owns cleanup, including early break and errors.
-- This is not Lua 5.1/LuaJIT syntax. No coroutine, file or external service is
-- required: an injected indexed source models acquisition/read/release events.
-- Use records ONLY as a generic-for expression. Manually unpacking its results
-- transfers responsibility for closing the fourth result to the caller.
assert(_VERSION == "Lua 5.4", "Lua 5.4 required")

local function records(count, read, trace, options)
    assert(math.type(count) == "integer" and count >= 0 and count <= 65535,
           "count must be a bounded nonnegative integer")
    assert(type(read) == "function", "read callback required")
    assert(type(trace) == "table" and getmetatable(trace) == nil, "plain trace table required")
    if options == nil then options = {} end
    assert(type(options) == "table", "options table required")
    local close_error = options.close_error -- capture before acquisition
    -- trace must be a dense array. Callbacks must not yield or mutate trace.
    -- Nil/false
    -- payloads are allowed: the positive index, not the payload, controls EOF.
    local state = { closed = false }
    trace[#trace + 1] = { event = "open" }
    local owner = setmetatable({}, {
        __close = function(_, cause)
            if state.closed then return end
            state.closed = true -- invalidate before reporting a close failure
            trace[#trace + 1] = { event = "close", cause = cause }
            if close_error ~= nil then
                error({ kind = "close", cause = cause, detail = close_error }, 0)
            end
        end,
        __metatable = "private iterator owner"
    })
    local function next_record(_, previous)
        assert(not state.closed, "read after close")
        local index = previous + 1
        if index > count then return nil end
        trace[#trace + 1] = { event = "read", index = index }
        return index, read(index)
    end
    return next_record, nil, 0, owner
end

local function events(trace)
    local result = {}
    for _, item in ipairs(trace) do
        result[#result + 1] = item.event .. (item.index and tostring(item.index) or "")
    end
    return table.concat(result, ",")
end

local trace = {}
local payload = table.pack("alpha", nil, false, "\0\255")
local seen = {}
for index, value in records(payload.n, function(i) return payload[i] end, trace) do
    seen[index] = table.pack(value)
end
assert(events(trace) == "open,read1,read2,read3,read4,close")
assert(#seen == 4 and seen[1][1] == "alpha")
assert(seen[2].n == 1 and seen[2][1] == nil)
assert(seen[3][1] == false and seen[4][1] == "\0\255")
assert(trace[#trace].cause == nil)

trace = {}
for _ in records(0, function() error("empty reader called") end, trace) do
    error("empty body called")
end
assert(events(trace) == "open,close")

trace = {}
local calls = 0
for index in records(10, function(i) calls = calls + 1; return i end, trace) do
    assert(index == 1)
    break
end
assert(calls == 1 and events(trace) == "open,read1,close")

trace = {}
local function take_one()
    for _, value in records(2, function(i) return i * 7 end, trace) do
        return value, nil, false
    end
end
local result = table.pack(take_one())
assert(result.n == 3 and result[1] == 7 and result[2] == nil and result[3] == false)
assert(events(trace) == "open,read1,close")

local body_error = { kind = "fixture-read" }
trace = {}
local ok, err = pcall(function()
    for _ in records(3, function(i)
        if i == 2 then error(body_error, 0) end
        return i
    end, trace) do end
end)
assert(not ok and err == body_error)
assert(events(trace) == "open,read1,read2,close")
assert(trace[#trace].cause == body_error)

-- false is a valid Lua error object, not an indication of successful exit.
trace = {}
ok, err = pcall(function()
    for _ in records(1, function() error(false, 0) end, trace) do end
end)
assert(not ok and err == false)
assert(events(trace) == "open,read1,close" and trace[#trace].cause == false)

local close_error = { kind = "fixture-close" }
for _, fail_read in ipairs({false, true}) do
    trace = {}
    ok, err = pcall(function()
        for _ in records(1, function()
            if fail_read then error(body_error, 0) end
            return "value"
        end, trace, {close_error = close_error}) do end
    end)
    assert(not ok and err.kind == "close" and err.detail == close_error)
    assert(err.cause == (fail_read and body_error or nil))
    assert(events(trace) == "open,read1,close")
    assert(trace[#trace].cause == (fail_read and body_error or nil))
end

trace = {}
ok, err = pcall(function()
    for _ in records(0, function() error("no read expected") end, trace,
                     {close_error = false}) do end
end)
assert(not ok and err.kind == "close" and err.detail == false and err.cause == nil)
assert(events(trace) == "open,close")

trace = {}
local captured = {close_error = close_error}
ok, err = pcall(function()
    for _ in records(1, function()
        captured.close_error = nil -- configuration was captured at acquisition
        return "value"
    end, trace, captured) do end
end)
assert(not ok and err.kind == "close" and err.detail == close_error)

-- An inner close error still closes the outer owner, receiving that structured
-- error as its cause. Resource order is observed independently from the API.
local outer, inner = {}, {}
ok, err = pcall(function()
    for _ in records(1, function() return "outer" end, outer) do
        for _ in records(1, function() return "inner" end, inner,
                         {close_error = close_error}) do break end
    end
end)
assert(not ok and err.kind == "close" and err.detail == close_error)
assert(events(inner) == "open,read1,close" and events(outer) == "open,read1,close")
assert(outer[#outer].cause == err)

-- Explicit ownership when unpacking, including sticky invalidation after a
-- failed close. Subsequent closes do not report or attempt release again.
trace = {}
local next_record, state, initial, owner = records(1, function() return "x" end,
                                                trace, {close_error = close_error})
ok, err = pcall(function()
    local adopted <close> = owner
    assert(next_record(state, initial) == 1)
end)
assert(not ok and err.detail == close_error)
do local already_closed <close> = owner end
assert(events(trace) == "open,read1,close")
ok, err = pcall(next_record, state, initial)
assert(not ok and tostring(err):find("read after close", 1, true))

-- Reject malformed count/callback before acquisition. Floating-point 1.0 is
-- intentionally outside this API's integer-subtype contract.
for _, bad in ipairs({-1, 1.0, 0/0, math.huge, 65536, "1", false}) do
    trace = {}
    ok, err = pcall(records, bad, function() end, trace)
    assert(not ok and events(trace) == "")
end
trace = {}
ok, err = pcall(records, 1, "not a function", trace)
assert(not ok and events(trace) == "")
trace = {}
ok, err = pcall(records, 1, function() end, trace, false)
assert(not ok and events(trace) == "")
local metatrace = setmetatable({}, {})
ok, err = pcall(records, 0, function() end, metatrace)
assert(not ok and next(metatrace) == nil)
print("closing iterator: normal, empty, break, return, read/close errors passed")
