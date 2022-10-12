local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Llama = require(ReplicatedStorage.Packages.Llama)

local e = Roact.createElement

local ThemeController = require(script.Parent.ThemeController)
local mapListWidget = require(script.mapListWidget)

local MapList = Roact.Component:extend("MapList")

function MapList:render()
    return e(ThemeController, {}, {
        MapList = e(mapListWidget, self.props);
    })
end

local function transform(value)
    if value == nil then
        return "—"
    elseif typeof(value) == "Vector3" then
        return string.format("%dx%d", value.X, value.Z)
    elseif type(value) == "boolean" then
        return value and "yes" or "no"
    else
        return value
    end
end

MapList = RoactRodux.connect(
    function(state, props)
        local mapInfo = {}

        for name, info in state.game.mapInfo do
            table.insert(mapInfo, {
                ["Map name"] = name;
                ["Teams"] = transform(info.teamSize);
                ["Size"] = transform(info.size);
                ["Neutral allowed"] = transform(info.neutralAllowed);
                ["CTF"] = transform(info.supportsCTF);
                ["Control Points"] = transform(info.supportsControlPoints);
                ["Creator"] = transform(info.creator);
            })
        end

        return Llama.Dictionary.merge(props, {
            mapInfo = mapInfo;
            activeMap = state.game.mapId;
        })
    end
)(MapList)

return MapList