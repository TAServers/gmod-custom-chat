local Settings = {
	filePath = "schat.json",

	width = 550,
	height = 260,
	offset_left = -1,
	offset_bottom = -1,

	font_size = 18,
	allow_any_url = false,
	timestamps = false,
}

function Settings:ValidateInteger(n, min, max)
	return math.Round(math.Clamp(tonumber(n), min, max))
end

function Settings:ValidateColor(clr)
	return Color(
		self:ValidateInteger(clr.r or 255, 0, 255),
		self:ValidateInteger(clr.g or 255, 0, 255),
		self:ValidateInteger(clr.b or 255, 0, 255),
		self:ValidateInteger(clr.a or 255, 0, 255)
	)
end

function Settings:Save()
	file.Write(
		self.filePath,
		util.TableToJSON({
			width = self.width,
			height = self.height,
			font_size = self.font_size,
			allow_any_url = self.allow_any_url,
			timestamps = self.timestamps,
			offset_left = self.offset_left,
			offset_bottom = self.offset_bottom,
		}, true)
	)
end

function Settings:Load()
	-- try to load settings
	local rawData = file.Read(self.filePath, "DATA")
	if rawData == nil then
		return
	end

	local data = util.JSONToTable(rawData) or {}

	if data.width then
		self.width = self:ValidateInteger(data.width, 250, 1000)
	end

	if data.height then
		self.height = self:ValidateInteger(data.height, 150, 1000)
	end

	if data.font_size then
		self.font_size = self:ValidateInteger(data.font_size, 10, 64)
	end

	if data.offset_left then
		self.offset_left = self:ValidateInteger(data.offset_left, -1, 1000)
	end

	if data.offset_bottom then
		self.offset_bottom = self:ValidateInteger(data.offset_bottom, -1, 1000)
	end

	self.timestamps = tobool(data.timestamps)
	self.allow_any_url = tobool(data.allow_any_url)
end

function Settings:ResetDefaultPosition()
	self.offset_left = -1
	self.offset_bottom = -1
end

function Settings:GetDefaultPosition()
	local bottomY = (ScrH() - self.height)
	return Either(self.offset_left > 0, self.offset_left, ScrW() * 0.032),
		Either(
			self.offset_bottom > 0,
			bottomY - self.offset_bottom,
			bottomY - ScrH() * 0.2
		)
end

function Settings:GetDefaultSize()
	return 550, 260
end

function Settings:SetWhitelistEnabled(enabled)
	self.allow_any_url = not enabled

	if enabled then
		SChat.InternalMessage(
			"Whitelist",
			"Only load images from trusted websites."
		)
	else
		SChat.InternalMessage("Whitelist", "Load images from any website.")
	end
end

-- Returns the properties of a emoji.
-- path|emoji, isOnline = Settings:GetEmojiInfo(id)
function Settings:GetEmojiInfo(id)
	for _, cat in ipairs(self.emojiCategories) do
		for _, emoji in ipairs(cat.emojis) do
			if type(emoji) == "string" then
				if id == emoji then
					return "materials/icon72/" .. id .. ".png"
				end
			else
				if id == emoji.id then
					return emoji, true
				end
			end
		end
	end
end

-- Add a image from the web as a emoji.
function Settings:AddOnlineEmoji(emoji)
	local emojis = self.emojiCategories[1].emojis

	table.insert(emojis, {
		id = emoji.id,
		uri = emoji.uri,
		numericId = emoji.numericId,
		isAnimated = emoji.isAnimated,
	})
end

function Settings:ClearCustomEmojis()
	self.emojiCategories[1].emojis = {}
end

Settings.emojiCategories = {
	{
		category = "Custom",
		emojis = {},
	},
	{
		category = "People",
		emojis = {
			"angel",
			"anger",
			"angry",
			"anguished",
			"astonished",
			"baby",
			"blue_heart",
			"blush",
			"boom",
			"broken_heart",
			"bust_in_silhouette",
			"clap",
			"cold_sweat",
			"cold_face",
			"confounded",
			"confused",
			"cry",
			"cupid",
			"disappointed",
			"dizzy",
			"dizzy_face",
			"droplet",
			"ear",
			"exclamation",
			"expressionless",
			"eyes",
			"fearful",
			"feet",
			"fire",
			"fist",
			"flushed",
			"frowning",
			"grey_exclamation",
			"grey_question",
			"grimacing",
			"grin",
			"grinning",
			"hand",
			"hankey",
			"hear_no_evil",
			"heart",
			"heart_eyes",
			"heartpulse",
			"hot_face",
			"hushed",
			"imp",
			"innocent",
			"joy",
			"kiss",
			"kissing",
			"kissing_heart",
			"kissing_smiling_eyes",
			"laughing",
			"lips",
			"mask",
			"muscle",
			"musical_note",
			"neutral_face",
			"no_good",
			"no_mouth",
			"nose",
			"notes",
			"ok_hand",
			"open_hands",
			"open_mouth",
			"pensive",
			"persevere",
			"point_down",
			"point_left",
			"point_right",
			"point_up",
			"pray",
			"pregnant_man",
			"pregnant_woman",
			"punch",
			"question",
			"rage",
			"raised_hands",
			"relaxed",
			"relieved",
			"revolving_hearts",
			"satisfied",
			"scream",
			"see_no_evil",
			"sick",
			"skull",
			"skull_crossbones",
			"sleeping",
			"sleepy",
			"smile",
			"smiley",
			"smirk",
			"sob",
			"sparkles",
			"speak_no_evil",
			"speaking_head",
			"star",
			"star2",
			"stuck_out_tongue",
			"stuck_out_tongue_closed_eyes",
			"stuck_out_tongue_winking_eye",
			"sunglasses",
			"sweat",
			"sweat_drops",
			"sweat_smile",
			"thought_balloon",
			"tired_face",
			"triumph",
			"unamused",
			"wave",
			"weary",
			"wink",
			"worried",
			"yum",
			"zzz",
			"alien",
		},
	},
	{
		category = "Objects",
		emojis = {
			"8ball",
			"alarm_clock",
			"apple",
			"art",
			"baby_bottle",
			"bar_chart",
			"basketball",
			"bathtub",
			"battery",
			"beer",
			"bell",
			"birthday",
			"bomb",
			"book",
			"bookmark",
			"books",
			"bread",
			"briefcase",
			"bricks",
			"bulb",
			"camera",
			"candy",
			"cd",
			"christmas_tree",
			"clapper",
			"clipboard",
			"computer",
			"corn",
			"credit_card",
			"date",
			"doughnut",
			"dvd",
			"eggplant",
			"electric_plug",
			"email",
			"eyeglasses",
			"file_folder",
			"flashlight",
			"floppy_disk",
			"game_die",
			"gem",
			"gift",
			"grapes",
			"guitar",
			"gun",
			"hamburger",
			"hammer",
			"high_brightness",
			"high_heel",
			"hourglass",
			"icecream",
			"key",
			"lock",
			"low_battery",
			"magnet",
			"mans_shoe",
			"musical_keyboard",
			"mute",
			"paperclip",
			"pencil2",
			"pill",
			"pushpin",
			"satellite",
			"soccer",
			"sound",
			"toilet",
			"tv",
			"video_game",
			"wine_glass",
			"wrench",
		},
	},
	{
		category = "Symbols",
		emojis = {
			"+1",
			"-1",
			"100",
			"1234",
			"abc",
			"zero",
			"one",
			"two",
			"three",
			"four",
			"five",
			"six",
			"seven",
			"eight",
			"nine",
			"arrow_backward",
			"arrow_double_down",
			"arrow_double_up",
			"arrow_down",
			"arrow_down_small",
			"arrow_forward",
			"arrow_heading_down",
			"arrow_heading_up",
			"arrow_left",
			"arrow_lower_left",
			"arrow_lower_right",
			"arrow_right",
			"arrow_right_hook",
			"arrow_up",
			"arrow_up_down",
			"arrow_up_small",
			"arrow_upper_left",
			"arrow_upper_right",
			"arrows_clockwise",
			"arrows_counterclockwise",
			"bangbang",
			"black_large_square",
			"black_medium_small_square",
			"black_square_button",
			"cancer",
			"cinema",
			"clock1",
			"cool",
			"copyright",
			"fast_forward",
			"free",
			"hash",
			"heavy_check_mark",
			"heavy_division_sign",
			"heavy_dollar_sign",
			"heavy_minus_sign",
			"heavy_multiplication_x",
			"heavy_plus_sign",
			"id",
			"information_source",
			"interrobang",
			"keycap_ten",
			"koko",
			"new",
			"ng",
			"no_entry",
			"no_entry_sign",
			"ok",
			"parking",
			"radio_button",
			"recycle",
			"black_circle",
			"white_circle",
			"red_circle",
			"green_circle",
			"blue_circle",
			"yellow_circle",
			"purple_circle",
			"registered",
			"signal_strength",
			"small_blue_diamond",
			"small_orange_diamond",
			"small_red_triangle",
			"small_red_triangle_down",
			"sos",
			"tm",
			"underage",
			"up",
			"white_check_mark",
		},
	},
	{
		category = "Nature",
		emojis = {
			"bear",
			"bird",
			"blossom",
			"cat",
			"cat2",
			"cherry_blossom",
			"chicken",
			"cow2",
			"cyclone",
			"dog",
			"dog2",
			"dolphin",
			"earth_americas",
			"elephant",
			"evergreen_tree",
			"fish",
			"four_leaf_clover",
			"globe_with_meridians",
			"maple_leaf",
			"monkey_face",
			"mouse",
			"mouse2",
			"ocean",
			"rat",
			"raccoon",
			"rooster",
			"rose",
			"snowflake",
			"wolf",
			"zap",
		},
	},
	{
		category = "Places",
		emojis = {
			"airplane",
			"ambulance",
			"barber",
			"beginner",
			"bike",
			"blue_car",
			"boat",
			"bullettrain_front",
			"bus",
			"car",
			"checkered_flag",
			"helicopter",
			"moyai",
			"rainbow",
			"rocket",
			"stars",
			"traffic_light",
			"vertical_traffic_light",
			"warning",
		},
	},
	{
		category = "Regional",
		emojis = {
			"regional_indicator_a",
			"regional_indicator_b",
			"regional_indicator_c",
			"regional_indicator_d",
			"regional_indicator_e",
			"regional_indicator_f",
			"regional_indicator_g",
			"regional_indicator_h",
			"regional_indicator_i",
			"regional_indicator_j",
			"regional_indicator_k",
			"regional_indicator_l",
			"regional_indicator_m",
			"regional_indicator_n",
			"regional_indicator_o",
			"regional_indicator_p",
			"regional_indicator_q",
			"regional_indicator_r",
			"regional_indicator_s",
			"regional_indicator_t",
			"regional_indicator_u",
			"regional_indicator_v",
			"regional_indicator_w",
			"regional_indicator_x",
			"regional_indicator_y",
			"regional_indicator_z",
		},
	},
}

SChat.Settings = Settings
