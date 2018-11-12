-- License: WTFPL


rules = {}



local items = {
	"Welcome to Capture the Flag!",
	"",
	"By playing on this server you agree to these rules:",
	"",
	"1. No swearing, dating, or other inappriopriate behaviour...",
	"2. No spamming, using all-caps, or any other method of chat abuse.",
	"3. Don't be a cheater. No hacked clients.",
	"4. Don't excessively spawnkill. Some spawn killing to stop players chasing",
	"        the flag bearer is OK, but hogging the flag and repeatedly killing",
	"        the same players definitely isn't.",
	"5. Don't be a traitor. Don't:",
	"    a. Dig blocks in your base to make it less secure or",
	"       to trap team mates on purpose.",
	"    b. Help the other team win.",
	"    c. Change teams.",
	"6. Don't impersonate other community members",
	"7. Moderator decisions are final.",
	"",
	"Failure to follow these rules may result in a kick or ban",
	"     (temp or permanent) depending on severity.",
	"",
	"Developed and hosted by rubenwardy",
	"Moderators: Thomas-S, ANAND, IceAgeComing, Waterbug, DragonGirl,",
	"            Gael-de-Sailly, Shara, Calinou",
	"",
	"Though the server owner will not actively read private messages or disclose",
	"their content outside the mod team, random checks will be done to make sure", 
	"they are not being abused and they will be reviewed if abuse or inappropriate",
	"behaviour is suspected. ",
	"",
	"Use /report to send a message to a moderator.",
	"For example, /report bobgreen is destroying our base"}

for i = 1, #items do
	items[i] = minetest.formspec_escape(items[i])
end
rules.txt = table.concat(items, ",")

if minetest.global_exists("sfinv") then
	sfinv.register_page("rules:rules", {
		title = "Rules",
		get = function(self, player, context)
			return sfinv.make_formspec(player, context,
				"textlist[0,0;7.85,8.5;help;" .. rules.txt .. "]", false)
		end
	})
end

local function can_grant_interact(player)
	local name = player:get_player_name()
	return not minetest.check_player_privs(name, { interact = true }) and not minetest.check_player_privs(name, { fly = true })
end

function rules.show(player)
	local fs = "size[8,7]bgcolor[#080808BB;true]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			"textlist[0.1,0.1;7.8,6.3;msg;" .. rules.txt .. ";-1;true]"

	if not can_grant_interact(player) then
		fs = fs .. "button_exit[0.5,6;7,2;yes;Okay]"
	else
		local yes = minetest.formspec_escape("Yes, let me play!")
		local no = minetest.formspec_escape("No, get me out of here!")

		fs = fs .. "button_exit[0.5,6;3.5,2;no;" .. no .. "]"
		fs = fs .. "button_exit[4,6;3.5,2;yes;" .. yes .. "]"
	end

	minetest.show_formspec(player:get_player_name(), "rules:rules", fs)
end

minetest.register_chatcommand("rules", {
	func = function(name, param)
		if param ~= "" and
				minetest.check_player_privs(name, { kick = true }) then
			name = param
		end

		local player = minetest.get_player_by_name(name)
		if player then
			rules.show(player)
			return true, "Rules shown."
		else
			return false, "Player " .. name .. " does not exist or is not online"
		end
	end
})

minetest.register_on_joinplayer(function(player)
	local privs = minetest.get_player_privs(player:get_player_name())
	if privs.interact and privs.fly then
		privs.interact = false
		minetest.set_player_privs(player:get_player_name(), privs)
	end

	if can_grant_interact(player) then
		rules.show(player)
	end
end)

minetest.register_on_player_receive_fields(function(player, form, fields)
	if form ~= "rules:rules" then
		return
	end

	local name = player:get_player_name()
	if not can_grant_interact(player) then
		return true
	end

	if fields.msg then
		return true
	elseif not fields.yes or fields.no then
		minetest.kick_player(name,
			"You need to agree to the rules to play on this server. " ..
			"Please rejoin and confirm another time.")
		return true
	end

	local privs = minetest.get_player_privs(name)
	privs.shout = true
	privs.interact = true
	minetest.set_player_privs(name, privs)

	minetest.chat_send_player(name, "Welcome "..name.."! You have now permission to play!")

	return true
end)

