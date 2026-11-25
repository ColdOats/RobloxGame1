local SoundService = game:GetService("SoundService")

local MiningAudio = {}
MiningAudio.__index = MiningAudio

local tone = "electronicpingshort.wav"
-- One row per measure, with eight subdivisions in each voice.
-- Numbers are semitones above the sample, false is a rest, and true lets the note ring.
local tracks = {
    [1] = { -- Meadow
        Step = .215, Gain = .105,
        Lead = {
            {0, 4, 7, true, 4, 7, 9, 7},
            {5, 9, 12, true, 9, 7, 5, 4},
            {9, 12, 16, 14, 12, true, 9, 12},
            {11, 7, 5, 2, 7, true, 11, false},
            {12, 7, 4, 7, 12, true, 16, 12},
            {14, 12, 9, 7, 5, true, 9, 7},
            {4, 7, 9, 12, 11, 9, 7, 5},
            {4, true, 2, 7, 0, true, false, 7},
        },
        Bass = {
            {-12, false, -5, -12, -8, false, -5, -8},
            {-7, false, 0, -7, -3, false, 0, -5},
            {-3, false, -8, -3, 0, false, -8, 0},
            {-5, false, 2, -5, -1, false, 2, -5},
            {-12, false, -5, -12, -8, false, -5, -8},
            {-7, false, 0, -7, -3, false, 0, -5},
            {-8, false, -3, false, -5, false, -1, 2},
            {-12, false, -10, -5, -12, true, false, -5},
        },
        Harmony = {
            {false, 0, 4, false, false, 4, 5, 4},
            {false, 5, 9, false, false, 4, 2, 0},
            {false, 9, 12, 11, 9, false, 4, 9},
            {false, 2, -1, false, 2, false, 7, false},
            {7, 4, 0, 4, 7, false, 12, 7},
            {9, 7, 5, 4, 2, false, 5, 4},
            {0, 4, 5, 7, 7, 5, 4, 2},
            {0, false, -1, 2, -5, true, false, 2},
        },
    },
    [0] = { -- Meadow Mine
        Step = .232, Gain = .093,
        Lead = {
            {7, false, 0, 3, 7, true, 10, 7},
            {5, false, -2, 2, 5, true, 9, 5},
            {3, 7, 10, 12, 10, 7, 5, 3},
            {2, true, 5, 7, 0, true, false, 5},
        },
        Bass = {
            {-12, false, -5, false, -12, -9, -5, false},
            {-14, false, -7, false, -14, -10, -7, false},
            {-9, false, -2, false, -7, -3, 0, false},
            {-5, false, -10, -5, -12, true, false, -5},
        },
        Harmony = {
            {false, false, -5, 0, false, false, 3, false},
            {false, false, -7, -2, false, false, 2, false},
            {false, 3, 7, 8, false, 3, 2, 0},
            {false, -2, 2, 5, 3, true, false, 2},
        },
    },
    [2] = { -- Amethyst Cavern
        Step = .244, Gain = .089,
        Lead = {
            {-3, false, 2, 5, 9, true, 5, 2},
            {12, 10, 5, false, 7, 5, 2, false},
            {1, 4, 7, 9, 13, true, 9, 7},
            {5, 2, 9, 5, 2, true, false, 5},
        },
        Bass = {
            {-10, false, -3, false, -10, false, -7, -3},
            {-14, false, -7, false, -7, false, 0, -7},
            {-15, false, -8, -3, -3, false, -8, -11},
            {-10, false, -7, -3, -10, true, false, -3},
        },
        Harmony = {
            {false, false, -3, 2, false, false, 2, false},
            {false, 5, 2, false, 0, false, -3, false},
            {false, 1, 4, false, 9, false, 4, 1},
            {2, false, 5, 2, -3, true, false, 2},
        },
    },
    [3] = { -- Frozen Peaks
        Step = .259, Gain = .081,
        Lead = {
            {9, true, 14, 16, 18, 16, 14, false},
            {11, true, 14, 18, 21, true, 18, 16},
            {14, 16, 19, 16, 14, 11, 9, 7},
            {6, 9, 11, 9, 14, true, false, 6},
        },
        Bass = {
            {-10, false, -3, false, -10, false, -6, false},
            {-13, false, -6, false, -1, false, -6, false},
            {-5, false, 2, false, -5, false, -1, false},
            {-3, false, -8, -3, -10, true, false, -3},
        },
        Harmony = {
            {false, false, 9, 11, 14, false, 9, false},
            {false, 6, 9, 11, 14, true, false, 9},
            {7, false, 14, 11, 7, false, 6, false},
            {false, 6, 7, 6, 9, true, false, 2},
        },
    },
    [4] = { -- Sunken Ruins
        Step = .235, Gain = .088,
        Lead = {
            {4, 7, 11, false, 9, 7, 4, false},
            {2, 6, 9, 12, 11, 9, 6, 2},
            {7, false, 11, 14, 16, true, 14, 11},
            {9, 6, 2, 6, 4, true, false, 11},
        },
        Bass = {
            {-8, false, -1, -8, -5, false, -1, false},
            {-10, false, -3, -10, -6, false, -3, false},
            {-5, false, 2, -5, -1, false, 2, -1},
            {-3, false, -6, -10, -8, true, false, -1},
        },
        Harmony = {
            {false, 4, 7, false, 6, 4, 0, false},
            {false, 2, 6, 9, 7, 6, 2, false},
            {4, false, 7, 11, 12, false, 11, 7},
            {6, 2, false, 2, -1, true, false, 7},
        },
    },
    [5] = { -- Ember Forge
        Step = .192, Gain = .097,
        Lead = {
            {12, 9, 4, 9, 7, 4, 7, 9},
            {5, 9, 14, 12, 9, 5, 9, 12},
            {4, 8, 11, 14, 16, 14, 11, 8},
            {12, 9, 7, 4, 9, true, false, 4},
        },
        Bass = {
            {-15, -15, -8, -15, -12, -15, -8, -12},
            {-10, -10, -3, -10, -7, -10, -3, -7},
            {-8, -8, -4, -8, -1, -8, -4, -13},
            {-15, -8, -12, -8, -15, true, false, -8},
        },
        Harmony = {
            {false, 4, 7, 4, false, 0, 4, 5},
            {false, 5, 9, 7, false, 2, 5, 9},
            {false, 4, 8, 11, 14, 11, 8, 4},
            {9, 4, 5, 0, 4, true, false, 0},
        },
    },
}
local effects = {
    hit = {"switch.wav", .26, .88, .14},
    pickRing = {tone, .09, 1.08, .155},
    ["break"] = {"switch.wav", .30, .63, .14},
    richBreak = {"switch.wav", .30, .63, .14},
    shards = {tone, .22, 1.41, .178},
    richChime = {tone, .15, 1.89, .239},
    coins = {tone, .19, 1.12},
    buy = {tone, .20, 1.35},
    accept = {"switch.wav", .22, 1.10},
    reward = {tone, .22, 1.50},
    travel = {tone, .18, .76},
    craft = {tone, .22, 1.04},
    forge = {"switch.wav", .23, .67},
    resonance1 = {tone, .24, .83},
    resonance2 = {tone, .24, 1.05},
    resonance3 = {tone, .27, 1.32},
}

local function voice(parent, name, sample)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = "rbxasset://sounds/" .. sample
    sound.Parent = parent
    return sound
end

local function note(sound, semitones, volume)
    if semitones == true then return end
    sound:Stop()
    if semitones == false then return end
    sound.PlaybackSpeed = 2 ^ (semitones / 12)
    sound.Volume = volume
    sound.TimePosition = 0
    sound:Play()
end

function MiningAudio.new(player, biomeAt)
    local self = setmetatable({
        Music = true,
        Effects = true,
        Lead = voice(SoundService, "Mine Music Lead", tone),
        Bass = voice(SoundService, "Mine Music Bass", tone),
        Harmony = voice(SoundService, "Mine Music Harmony", tone),
        Percussion = voice(SoundService, "Mine Music Percussion", "switch.wav"),
        Bank = {},
        Zone = nil,
    }, MiningAudio)
    for cue, effect in pairs(effects) do
        local sound = voice(SoundService, "Mine " .. cue, effect[1])
        sound.Volume = effect[2]
        sound.PlaybackSpeed = effect[3]
        self.Bank[cue] = sound
    end

    task.spawn(function()
        local measure, step = 1, 1
        while player.Parent do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local zone = root and biomeAt(root.Position.X)
            if zone ~= self.Zone then
                self:stopMusic()
                measure, step = 1, 1
                self.Zone = zone
            end
            local track = tracks[zone]
            if self.Music and track then
                note(self.Lead, track.Lead[measure][step], track.Gain)
                note(self.Bass, track.Bass[measure][step], track.Gain * .68)
                note(self.Harmony, track.Harmony[measure][step], track.Gain * .37)
                if step % 2 == 1 then
                    note(self.Percussion, step % 4 == 1 and -9 or 6, track.Gain * .17)
                end
                step = step % 8 + 1
                if step == 1 then measure = measure % #track.Lead + 1 end
            end
            task.wait(track and track.Step or .25)
        end
        self.Lead:Destroy()
        self.Bass:Destroy()
        self.Harmony:Destroy()
        self.Percussion:Destroy()
        for _, sound in pairs(self.Bank) do sound:Destroy() end
    end)
    return self
end

function MiningAudio:stopMusic()
    self.Lead:Stop()
    self.Bass:Stop()
    self.Harmony:Stop()
    self.Percussion:Stop()
end

function MiningAudio:setMusic(enabled)
    self.Music = enabled
    if not enabled then self:stopMusic() end
end

function MiningAudio:setEffects(enabled)
    self.Effects = enabled
    if not enabled then
        for _, sound in pairs(self.Bank) do sound:Stop() end
    end
end

local function playEffect(self, name)
    local sound = self.Bank[name]
    if not sound or not self.Effects then return end
    local function play()
        if self.Effects and sound.Parent then
            sound.TimePosition = 0
            sound:Play()
        end
    end
    local delay = effects[name][4]
    if delay then task.delay(delay, play) else play() end
end

function MiningAudio:cue(name)
    playEffect(self, name)
    if name == "hit" then
        playEffect(self, "pickRing")
    elseif name == "break" or name == "richBreak" then
        playEffect(self, "shards")
        if name == "richBreak" then playEffect(self, "richChime") end
    end
end

return MiningAudio
