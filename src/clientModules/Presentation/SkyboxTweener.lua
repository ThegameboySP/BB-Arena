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

function SkyboxTweener:TweenSkybox(skybox, tweenInfo)
    self._promise:cancel()

    local root = self._fakeSkybox:GetRoot()
    root.ImageTransparency = 1

    self._promise = self._fakeSkybox:SetSky(skybox):andThen(function()
        return Promise.new(function(resolve, _, onCancel)
            local tween = TweenService:Create(root, tweenInfo, {ImageTransparency = 0})
            tween:Play()
            tween.Completed:Connect(resolve)

            onCancel(function()
                tween:Cancel()
            end)
        end)
    end):finally(function()
        self:_setSkybox(skybox)
    end)

    return self._promise
end

function SkyboxTweener:_setSkybox(skybox)
    local oldSkybox = self._lighting:FindFirstChildWhichIsA("Skybox")
    if oldSkybox then
        oldSkybox.Parent = nil
    end

    self._fakeSkybox:GetRoot().ImageTransparency = 1
    skybox.Parent = self._lighting
end

function SkyboxTweener:SetSkybox(skybox)
    self._promise:cancel()
    self:_setSkybox(skybox)
end

return SkyboxTweener