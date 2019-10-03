-- License: WTFPL


rules = {}


-- Kpenguin, Thomas-S, Dragonop, stormchaser3000, Calinou, sparky/ircSparky.

local items = {
	"By playing on this server you agree to these rules:",
	"",
	"1. No swearing, dating, or other inappriopriate behaviour..",
	"2. Don't be a cheater. No hacked clients.",
	"3. Don't excessively spawnkill. Some spawn killing to stop players chasing",
	"        the flag bearer is OK, but hogging the flag and repeatedly killing",
	"        the same players definitely isn't.",
	"4. Don't be a traitor. Don't:",
	"    a. Dig blocks in your base to make it less secure or",
	"       to trap team mates on purpose.",
	"    b. Help the other team win.",
	"    c. Change teams.",
	"5. Don't combat-log, that is, leaving the game whilst in a fight",
	"6. Don't impersonate other community members.",
	"7. Don't share your password with anyone.",
	"8. Moderator decisions are final.",
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
	local pname = player:get_player_name()
	return not minetest.check_player_privs(pname, { interact = true }) and
			not minetest.check_player_privs(pname, { fly = true })
end

local function has_password(pname)
	local handler = minetest.get_auth_handler()
	local auth = handler.get_auth(pname)
	return auth and not minetest.check_password_entry(pname, auth.password, "")
end

function rules.show(player)
	local pname = player:get_player_name()
	local fs = "size[8,8.6]bgcolor[#080808BB;true]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			"textlist[0.1,0.1;7.8,7.9;msg;" .. rules.txt .. ";-1;true]"

	if not has_password(pname) then
		fs = fs .. "box[4,8.1;3.1,0.7;#900]"
		fs = fs .. "label[4.2,8.2;Please set a password]"
		fs = fs .. "button_exit[0.5,7.6;3.5,2;ok;Okay]"
	elseif not can_grant_interact(player) then
		fs = fs .. "button_exit[0.5,7.6;7,2;ok;Okay]"
	else
		local yes = minetest.formspec_escape("Yes, let me play!")
		local no = minetest.formspec_escape("No, get me out of here!")

		fs = fs .. "button_exit[0.5,7.6;3.5,2;no;" .. no .. "]"
		fs = fs .. "button_exit[4,7.6;3.5,2;yes;" .. yes .. "]"
	end

	minetest.show_formspec(pname, "rules:rules", fs)
end

function rules.show_pwd(pname, msg)
	msg = msg or "You must set a password to be able to play"

	minetest.show_formspec(pname, "rules:pwd",  [[
			size[8,3]
			no_prepends[]
			bgcolor[#600]
			pwdfield[0.8,1.5;7,1;pwd;Password;]
			button[0.5,2;7,2;setpwd;Set]
			label[0.2,0.2;]] .. minetest.formspec_escape(msg) .. "]")
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

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()

	local privs = minetest.get_player_privs(pname)
	if privs.interact and privs.fly then
		privs.interact = false
		minetest.set_player_privs(pname, privs)
	end

	if not has_password(pname) then
		privs.shout = false
		privs.interact = false
		privs.kick = false
		privs.ban = false
		minetest.set_player_privs(pname, privs)
		rules.show_pwd(pname)
	elseif can_grant_interact(player) then
		rules.show(player)
	end
end)

minetest.register_on_player_receive_fields(function(player, form, fields)
	if form == "rules:pwd" then
		local pname = player:get_player_name()
		if fields.setpwd then
			local handler = minetest.get_auth_handler()
			if not fields.pwd or fields.pwd:trim() == "" then
				rules.show_pwd(pname)
			elseif #fields.pwd < 5 then
				rules.show_pwd(pname, "Needs at least 5 characters")
			else
				handler.set_password(pname,
						minetest.get_password_hash(pname, fields.pwd))
				rules.show(player)
			end
		else
			minetest.kick_player(pname,
				"You need to set a password to play on this server.")
		end

		return true
	end

	if form ~= "rules:rules" then
		return
	end

	local pname = player:get_player_name()
	if not can_grant_interact(player) or not has_password(pname) then
		return true
	end

	if fields.msg then
		return true
	elseif not fields.yes or fields.no then
		minetest.kick_player(pname,
			"You need to agree to the rules to play on this server. " ..
			"Please rejoin and confirm another time.")
		return true
	end

	local privs = minetest.get_player_privs(pname)
	privs.shout = true
	privs.interact = true
	minetest.set_player_privs(pname, privs)

	minetest.chat_send_player(pname, "Welcome "..pname.."! You have now permission to play!")

	return true
end)
