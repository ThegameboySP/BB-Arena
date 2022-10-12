local gameActions = {}

function gameActions.gamemodeStarted(gamemodeId)
    return {
        type = "game_gamemodeStarted";
        payload = {
            gamemodeId = gamemodeId;
        };
    }
end

function gameActions.gamemodeEnded(gamemodeId)
    return {
        type = "game_gamemodeEnded";
        payload = {
            gamemodeId = gamemodeId;
        };
    }
end

function gameActions.userDataFetched(userId, data)
    return {
        type = "game_userDataFetched";
        payload = {
            userId = userId;
            data = data;
        };
        meta = {
            interestedUserIds = {userId};
        };
    }
end

function gameActions.mapChanged(mapId)
    return {
        type = "game_mapChanged";
        payload = {
            mapId = mapId;
        };
    }
end

function gameActions.setMapInfo(mapInfo)
    return {
        type = "game_setMapInfo";
        payload = {
            mapInfo = mapInfo;
        };
    }
end

return gameActions