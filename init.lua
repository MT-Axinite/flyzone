-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

minetest.register_privilege("buildbattler", {S("Can fly for Build Battle."), give_to_singleplayer = false})

local checkinterval = 2

-- Table Save Load Functions
local function save_data()
	if flyzone.players == nil then
		return
	end

	local file = io.open(minetest.get_worldpath().."/flyzone.txt", "w")
	if file then
		file:write(minetest.serialize(flyzone.players))
		file:close()
	end
end

local function load_data()
	if flyzone.players == nil then
		local file = io.open(minetest.get_worldpath().."/flyzone.txt", "r")
		if file then
			local table = minetest.deserialize(file:read("*all"))
			if type(table) == "table" then
				flyzone.players = table
				return
			end
		end
	end
	flyzone.players = {}
end

local function distance(v, w)
	return math.sqrt(
		math.pow(v.x - w.x, 2) +
		math.pow(v.y - w.y, 2) +
		math.pow(v.z - w.z, 2)
	)
end

flyzone = {

	zone = {["x"] = 29124, ["y"] = 29026, ["z"] = 29163},
	radius = 175,

	players = nil,
	userdata = {},

	createPlayerTable = function(player)
		if not flyzone.players then
			load_data()
		end

		if not player or not player:get_player_name() then
			return;
		end

		local name = player:get_player_name()

		if (name=="") then
			return;
		end

		flyzone.players[name] = {}
		flyzone.userdata[name] = player
	end,

	calculate_current_area = function(player)
		local name = player:get_player_name()

		if (name=="") then
			return;
		end

		if (not flyzone.players[name]) then
			flyzone.createPlayerTable(player)
		end

		if distance(player:getpos(),flyzone.zone) < flyzone.radius then
			if  (not flyzone.players[name].zone or flyzone.players[name].zone==false) then
				flyzone.enter_area(player)
			end
		else
			if  (flyzone.players[name].zone==true) then
				flyzone.leave_area(player)
			end
		end
	end,

	enter_area = function(player)
		local name = player:get_player_name()
		if minetest.check_player_privs(name, {buildbattler=true}) then
			flyzone.players[name].zone=true
			-- save data
			save_data()
			-- Get privs
			local privs = minetest.get_player_privs(name)
			if not privs then
				print("[PrivilegeAreas] player does not exist error!")
			end
			-- Set fly
			privs.fly = true
			minetest.set_player_privs(name, privs)
			minetest.chat_send_player(name, S("You can fly now."))
		end
	end,

	leave_area = function(player)
		local name = player:get_player_name()
		if minetest.check_player_privs(name, {buildbattler=true}) then
			flyzone.players[name].zone=false
			-- save data
			save_data()
			-- Get privs
			local privs = minetest.get_player_privs(name)

			if not privs then
				print("[PrivilegeAreas] player does not exist error!")
			end
			-- Set fly
			privs.fly = nil
			minetest.set_player_privs(name, privs)
			minetest.chat_send_player(name, S("You can't fly anymore."))
		end
	end,
}

load_data()

minetest.register_on_shutdown(function()
	save_data()
end)

minetest.register_on_joinplayer(function(player)
	flyzone.createPlayerTable(player)
end)

minetest.register_on_leaveplayer(function(player)
	flyzone.userdata[player:get_player_name()]=nil
end)

local time = 0
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time >= checkinterval then
		time = 0
		for _, plr in pairs(flyzone.userdata) do
			flyzone.calculate_current_area(plr)
		end
	end
end)
