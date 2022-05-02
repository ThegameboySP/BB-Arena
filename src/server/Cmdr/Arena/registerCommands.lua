local commands = {}

local function registerCommandsIn(target)
    for _, child in pairs(target:GetChildren()) do
        if child:IsA("ModuleScript") and not child.Name:find("Server$") then
            commands[child.Name] = {
                definition = child;
                server = target:FindFirstChild(child.Name .. "Server");
            }
        elseif child:IsA("Folder") then
            registerCommandsIn(child)
        end
    end
end

registerCommandsIn(script)

return function(registry, filter)
    filter = filter or function()
        return true
    end

    local processedCommands = {}

    for name, command in pairs(commands) do
        if not filter(command) then
            continue
        end

        local definition = require(command.definition)
        -- Only for commands that need access to Cmdr's registry or util.
        if type(definition) == "function" then
            definition = definition(registry.Cmdr)   
        end

        if command.server then
            definition.Run = require(command.server)
        end

        registry:RegisterCommandObject(definition)
        processedCommands[name] = command
    end

    return processedCommands
end