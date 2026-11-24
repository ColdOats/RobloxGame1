local SessionStore = {}
SessionStore.__index = SessionStore

local LEASE_SECONDS = 180
local SCHEMA = 1

function SessionStore.new(dataStore)
    return setmetatable({ dataStore = dataStore }, SessionStore)
end

local function unpackRecord(value)
    if value == nil then return {}, nil, true end
    if type(value) ~= "table" then return nil, nil, false end
    if value.Schema == nil and value.Profile == nil and value.Session == nil then
        return value, nil, true
    end
    if value.Schema ~= SCHEMA or type(value.Profile) ~= "table" then return nil, nil, false end
    local session = value.Session
    if session ~= nil and (type(session) ~= "table" or type(session.Owner) ~= "string"
        or type(session.ExpiresAt) ~= "number") then
        return nil, nil, false
    end
    return value.Profile, session, true
end

function SessionStore:_update(userId, transform)
    local reason
    local ok, result = pcall(function()
        return self.dataStore:UpdateAsync(tostring(userId), function(value)
            local profile, session, valid = unpackRecord(value)
            if not valid then
                reason = "invalid"
                return nil
            end
            local replacement
            replacement, reason = transform(profile, session, os.time())
            return replacement
        end)
    end)
    if not ok then
        warn("Profile DataStore update failed:", result)
        return nil, "unavailable"
    end
    return result, reason
end

function SessionStore:acquire(userId, owner)
    return self:_update(userId, function(profile, session, now)
        if session and session.Owner ~= owner and session.ExpiresAt > now then
            return nil, "locked"
        end
        return {
            Schema = SCHEMA,
            Profile = profile,
            Session = { Owner = owner, ExpiresAt = now + LEASE_SECONDS },
        }
    end)
end

function SessionStore:save(userId, owner, profile, release)
    return self:_update(userId, function(stored, session, now)
        if not session or session.Owner ~= owner or session.ExpiresAt <= now then
            return nil, "lost"
        end
        local record = { Schema = SCHEMA, Profile = profile or stored }
        if not release then
            record.Session = { Owner = owner, ExpiresAt = now + LEASE_SECONDS }
        end
        return record
    end)
end

return SessionStore
