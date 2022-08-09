rules = {}

local S = minetest.get_translator(minetest.get_current_modname())

local items = {
	S("By playing on this server you agree to these rules:"),
	"",
	S("1. No swearing, dating, or other inappropriate behaviour."),
	S("2. No spamming, using all-caps, or any other method of chat abuse."),
	S("3. Don't be a cheater. No hacked clients."),
	S("4. Spawnkilling is considered excessive and thus forbidden if it doesn't"),
	"        " .. S("contribute to the goal of the game in a proper way. Consequently,"),
	"        " .. S("spawnkilling can already be punished if only two kills are made,"),
	"        " .. S("depending on the situation."),
	S("5. Don't be a traitor:"),
	S("    a. Don't dig blocks in your base to make it less secure or"),
	S("       to trap team mates on purpose."),
	S("    b. Don't help the other team win."),
	S("    c. Team changing is not allowed, unless done by the game."),
	S("6. Don't leave the game whilst in a fight"),
	S("7. Don't impersonate other community members"),
	S("8. Do not share your password with ANYONE."),
	S("9. Avoid controversial topics like politics/religion"),
	S("10. Moderator decisions are final."),
	"",
	S("Failure to follow these rules may result in a kick or ban"),
	S("     (temp or permanent) depending on severity."),
	"",
	S("Created by rubenwardy. Developed by ")..S("LandarVargan and savilli."),
	S("Moderators")..": Thomas-S, IceAgeComing, Waterbug, DragonsVolcanoDance,",
	"            Shara, Calinou, Aurika, LandarVargan, Xenon, Jhalman, Kat, _Lucy",
	"",
	S("Though the server owner will not actively read private messages or disclose"),
	S("their content outside the mod team, random checks will be done to make sure"),
	S("they are not being abused and they will be reviewed if abuse or inappropriate"),
	S("behaviour is suspected."),
	"",
	S("Use /report to send a message to a moderator."),
	S("For example, /report bobgreen is destroying our base")}

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

local function need_to_accept(pname)
	return not minetest.check_player_privs(pname, { interact = true }) and
			not minetest.check_player_privs(pname, { shout = true })
end

function rules.show(player)
	local pname = player:get_player_name()
	local fs = "size[8,8.6]bgcolor[#080808BB;true]" ..
			"textlist[0.1,0.1;7.8,7.9;msg;" .. rules.txt .. ";-1;true]"

	if not need_to_accept(pname) then
		fs = fs .. "button_exit[0.5,7.6;7,2;ok;Okay]"
	else
		local yes = minetest.formspec_escape("Yes, let me play!")
		local no = minetest.formspec_escape("No, get me out of here!")

		fs = fs .. "button_exit[0.5,7.6;3.5,2;no;" .. no .. "]"
		fs = fs .. "button_exit[4,7.6;3.5,2;yes;" .. yes .. "]"
	end

	minetest.show_formspec(pname, "rules:rules", fs)
end

minetest.register_chatcommand("rules", {
	func = function(pname, param)
		if param ~= "" and
				minetest.check_player_privs(pname, { kick = true }) then
			pname = param
		end

		local player = minetest.get_player_by_name(pname)
		if player then
			rules.show(player)
			return true, "Rules shown."
		else
			return false, "Player " .. pname .. " does not exist or is not online"
		end
	end
})

minetest.register_on_newplayer(function(player)
	local pname = player:get_player_name()

	local privs = minetest.get_player_privs(pname)
	privs.shout = nil
	privs.interact = nil
	minetest.set_player_privs(pname, privs)

	rules.show(player)
end)

minetest.register_on_joinplayer(function(player)
	if need_to_accept(player:get_player_name()) then
		rules.show(player)
	end
end)

minetest.register_on_player_receive_fields(function(player, form, fields)
	if form ~= "rules:rules" then return end

	local pname = player:get_player_name()
	if not need_to_accept(pname) then
		return true
	end

	if fields.no then
		minetest.kick_player(pname,
			"You need to agree to the rules to play on this server. " ..
			"Please rejoin and confirm another time.")
		return true
	end

	if not fields.yes then
		return true
	end

	local privs = minetest.get_player_privs(pname)
	privs.shout = true
	privs.interact = true
	minetest.set_player_privs(pname, privs)

	minetest.chat_send_player(pname, "Welcome "..pname.."! You have now permission to play!")

	return true
end)
