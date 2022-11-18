local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Llama = require(ReplicatedStorage.Packages.Llama)
local Signal = require(ReplicatedStorage.Packages.Signal)
local e = Roact.createElement

local HUDApp = require(script.Parent)

return function(target)
	local tree
	local props
	props = {
		equippedItemName = "Sword";
		health = 50;
		maxHealth = 100;
		
		failedAction = Signal.new();

		items = {
			{
				name = "Sword";
				thumbnail = "rbxasset://Textures/Sword128.png";
			};
			{
				name = "Slingshot";
				thumbnail = "rbxasset://Textures/Slingshot.png";
			};
			{
				name = "Rocket";
				thumbnail = "rbxasset://Textures/Rocket.png";
			};
			{
				name = "Trowel";
				thumbnail = "rbxasset://Textures/Wall.png";
			};
			{
				name = "Bomb";
				thumbnail = "rbxasset://Textures/Bomb.png";
				charge = 0.5;
			};
			{
				name = "Superball";
				thumbnail = "rbxasset://Textures/Superball.png";
			};
			{
				name = "PaintballGun";
				thumbnail = "rbxasset://Textures/PaintballIcon.png";
			};
		};

		toolTip = "[Z] - Bomb jump (reloading)";

		onEquipped = function(itemName)
			props = Llama.Dictionary.merge(props, {
				equippedItemName = itemName or Llama.None;
			})
			Roact.update(tree, e(HUDApp, props))
		end;

		onOrderChanged = function(newOrder)
			props = Llama.Dictionary.merge(props, {
				items = newOrder;
			})
			Roact.update(tree, e(HUDApp, props))
		end;

		secondsTimer = 1;
		displayBattleInfo = true;
	}
	
	local roactTree = e(HUDApp, props)

	tree = Roact.mount(roactTree, target)

	return function()
		Roact.unmount(tree)
	end
end