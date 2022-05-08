local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local FakeSkybox = require(script.Parent.FakeSkybox)
local SkyboxEffects = require(script.Parent.SkyboxEffects)

local SkyboxTweener = {}
SkyboxTweener.__index = SkyboxTweener

function SkyboxTweener.new(lighting)
    local skyboxEffects = SkyboxEffects.new()

    return setmetatable({
        _fakeSkybox = skyboxEffects:AddEffect(FakeSkybox.new());
        _skyboxEffects = skyboxEffects;
        _lighting = lighting;
        _promise = Promise.resolve();
    }, SkyboxTweener)
end

function SkyboxTweener:Destroy()
    self._skyboxEffects:Destroy()
end

function SkyboxTweener:TweenSkybox(skybox, tweenInfo, undoSky)
    undoSky = undoSky or function() end
    self._promise:cancel()

    local oldSkybox = self._oldSkybox
    self._oldSkybox = skybox

    self._promise = self._fakeSkybox:SetSky(oldSkybox or skybox):andThen(function()
        -- Should deparent sky before setting new skybox, or else the default sky is shown I think.
        undoSky()

        skybox.Parent = self._lighting
        local root = self._fakeSkybox:GetRoot()
        root.ImageTransparency = 0

        return Promise.new(function(resolve, _, onCancel)
            local tween = TweenService:Create(root, tweenInfo, {ImageTransparency = 1})
            tween:Play()
            tween.Completed:Connect(resolve)

            onCancel(function()
                tween:Cancel()
            end)
        end)
    end)

    return self._promise
end

function SkyboxTweener:SetSkybox(skybox)
    self._promise:cancel()
    self._fakeSkybox:GetRoot().ImageTransparency = 1
    skybox.Parent = self._lighting
end

return SkyboxTweener