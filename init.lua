local reloading = {}
local function reload(name)
	if not reloading[name] then
		reloading[name] = true
		core.after(3,function()
			reloading[name] = nil
		end)
	end
end

core.register_chatcommand("snowgun", {
  description = "Set snowflakes amount for Snowgun (default is 30)",
  params = "<number>",
  privs = {server=true},
  func = function(name, param)
	local amount = tonumber(param)
	if not amount then return false, "Invalid number" end
	local player = core.get_player_by_name(name)
	if not player then return end
	local witem = player:get_wielded_item()
	if not witem then return end
	if witem:get_name() ~= "snowgun:snowgun" then return false, "Keep Snowgun in hand!" end
	local meta = witem:get_meta()
	if meta then
		meta:set_int("amount",amount)
		meta:set_string("count_meta",param)
		meta:set_string("description","Snowgun\nUses "..amount.." default:snow")
		player:set_wielded_item(witem)
		return true, "Snowflakes amount set to "..param
	end
end})

core.register_tool("snowgun:snowgun", {
  wield_scale = {x=1,y=1,z=2},
  description = "Snowgun\nUses 30 default:snow",
  inventory_image = "snowgun.png",
  on_use = function(itemstack, player, pointed_thing)
	local name = player:get_player_name()
	local creative = core.check_player_privs(name, {creative = true})
	local inv = player:get_inventory()
	local meta = itemstack:get_meta()
	local amount = meta:get("amount") or 30
	if inv:contains_item("main", "default:snow "..amount) or creative then
		if not creative then
			if reloading[name] then
				core.chat_send_player(name, "Snowgun is reloading")
				return
			end
			reload(name)
			inv:remove_item("main", "default:snow "..amount)
			itemstack:add_wear(256)
		end
		local pos = player:get_pos()
		local dir = player:get_look_dir()
		local pitch = player:get_look_vertical()
		if pos and dir then
			pos.y = pos.y + 1.5
			for i=1, amount do
				local obj = core.add_entity(pos, "snowgun:snowflake", name)
				if obj then
					obj:set_velocity({x=dir.x * 20 + math.random(-3,3), y=dir.y * 20 + math.random(-3,3), z=dir.z * 20 + math.random(-3,3)})
					obj:set_acceleration({x=0, y=-5, z=0})
				end
			end
		end
		core.sound_play('default_snow_footstep',{to_player = name, gain = 0.5})
		return itemstack
	end
end})

local snowflake = {
	armor_groups = {immortal = true},
	physical = true,
	timer = 0,
	visual = "sprite",
	visual_size = {x=0.6, y=0.6,},
	textures = {'snowgun_snowflake.png'},
	pointable = false,
	collisionbox = {-0.25,-0.25,-0.25,0.25,0.25,0.25},
	collide_with_objects = false,
}

snowflake.on_activate = function(self, staticdata)
	self["owner"] = staticdata or ""
end

snowflake.on_step = function(self, dtime, moveresult)
	self.timer = self.timer + dtime
	local pos = self.object:get_pos()
	if self.timer >= 20 then
		self.object:remove()
	end
	if moveresult.collides then
		local node = core.get_node_or_nil(pos)
		if not core.is_protected(pos, self["owner"]) and (not node or (node and node.name == "air") or (node and core.registered_nodes[node.name] and core.registered_nodes[node.name].buildable_to)) then
			core.add_node(pos, {name="default:snow",param2=0})
			core.check_for_falling(pos)
		end
		self.object:remove()
	end
end

core.register_entity("snowgun:snowflake", snowflake)

core.register_craft({
	output = "snowgun:snowgun",
	recipe = {
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		{"default:snow","default:mese_crystal","default:steel_ingot"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"}
	}
})
