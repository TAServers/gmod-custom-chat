--[[
    SChat by StyledStrike
]]
resource.AddWorkshop("2799307109")

util.AddNetworkString("schat.say")
util.AddNetworkString("schat.is_typing")

util.AddNetworkString("schat.set_theme")
util.AddNetworkString("schat.set_emojis")
util.AddNetworkString("schat.set_tags")

-- handle networking of messages
local sayCooldown = {}

-- Gets a list of all players who can
-- listen to messages from a "speaker".
function SChat:GetListeners(speaker, text, channel)
	local targets = {}

	if channel == self.EVERYONE then
		targets = player.GetHumans()
	elseif channel == self.TEAM then
		targets = team.GetPlayers(speaker:Team())
	end

	local listeners = {}
	local teamOnly = channel ~= SChat.EVERYONE

	for _, ply in ipairs(targets) do
		if
			hook.Run("PlayerCanSeePlayersChat", text, teamOnly, ply, speaker)
		then
			listeners[#listeners + 1] = ply
		end
	end

	return listeners
end

net.Receive("schat.say", function(_, ply)
	local id = ply:AccountID()
	local nextSay = sayCooldown[id] or 0

	if RealTime() < nextSay then
		return
	end

	sayCooldown[id] = RealTime() + 0.5

	local channel = net.ReadUInt(4)
	local text = net.ReadString()

	if text:len() > SChat.MAX_MESSAGE_LEN then
		text = text:Left(SChat.MAX_MESSAGE_LEN)
	end

	text = SChat.CleanupString(text)

	text = hook.Run("PlayerSay", ply, text, channel ~= SChat.EVERYONE)
	if not isstring(text) or text == "" then
		return
	end

	local targets = SChat:GetListeners(ply, text, channel)
	if #targets == 0 then
		return
	end

	net.Start("schat.say", false)
	net.WriteUInt(channel, 4)
	net.WriteString(text)
	net.WriteEntity(ply)
	net.Send(targets)
end)

hook.Add("PlayerDisconnected", "schat_PlayerDisconnected", function(ply)
	sayCooldown[ply:AccountID()] = nil
end)

-- lets restore the "hands on the ear"
-- behaviour from the default chat.
local PLY = FindMetaTable("Player")

PLY.DefaultIsTyping = PLY.DefaultIsTyping or PLY.IsTyping

function PLY:IsTyping()
	return self:GetNWBool("IsTyping", false)
end

net.Receive("schat.is_typing", function(_, ply)
	ply:SetNWBool("IsTyping", net.ReadBool())
end)

-- server settings
local Settings = {
	themeFilePath = "schat_server_theme.json",
	emojiFilePath = "schat_server_emojis.json",
	tagsFilePath = "schat_server_tags.json",

	themeData = {},
	emojiData = {},
	tagsData = {},
}

function Settings:Serialize(tbl)
	return util.TableToJSON(tbl)
end

function Settings:Unserialize(str)
	if not str or str == "" then
		return {}
	end

	return util.JSONToTable(str) or {}
end

function Settings:Load()
	-- load an existing server theme
	self.themeData = self:Unserialize(file.Read(self.themeFilePath, "DATA"))

	-- load existing server emojis
	self.emojiData = self:Unserialize(file.Read(self.emojiFilePath, "DATA"))

	-- load existing server chat tags
	self.tagsData = self:Unserialize(file.Read(self.tagsFilePath, "DATA"))
end

function Settings:Save()
	file.Write(self.themeFilePath, self:Serialize(self.themeData))
	file.Write(self.emojiFilePath, self:Serialize(self.emojiData))
	file.Write(self.tagsFilePath, self:Serialize(self.tagsData))
end

function Settings:ShareTheme(ply)
	if game.SinglePlayer() then
		return
	end

	net.Start("schat.set_theme", false)

	if table.IsEmpty(self.themeData) then
		net.WriteString("")
	else
		net.WriteString(self:Serialize(self.themeData))
	end

	if IsValid(ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function Settings:ShareEmojis(ply)
	net.Start("schat.set_emojis", false)
	net.WriteString(self:Serialize(self.emojiData))

	if IsValid(ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function Settings:ShareTags(ply)
	net.Start("schat.set_tags", false)
	net.WriteString(self:Serialize(self.tagsData))

	if IsValid(ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function Settings:SetTheme(data, admin)
	SChat.PrintF(
		"%s %s the server theme.",
		admin or "Someone",
		table.IsEmpty(data) and "removed" or "changed"
	)

	self.themeData = data
	self:ShareTheme()
	self:Save()
end

function Settings:SetEmojis(data, admin)
	SChat.PrintF(
		"%s %s the server emojis.",
		admin or "Someone",
		table.IsEmpty(data) and "removed" or "changed"
	)

	self.emojiData = data
	self:ShareEmojis()
	self:Save()
end

function Settings:SetChatTags(data, admin)
	SChat.PrintF("%s changed the chat tags.", admin or "Someone")

	self.tagsData = data
	self:ShareTags()
	self:Save()
end

function Settings:GetEmojiInfo(id)
	for _, emoji in ipairs(self.emojiData) do
		if id == emoji.id then
			return emoji, true
		end
	end
end

net.Receive("schat.set_theme", function(_, ply)
	if SChat:CanSetServerTheme(ply) then
		local themeData = Settings:Unserialize(net.ReadString())
		Settings:SetTheme(themeData, ply:Nick())
	else
		ply:ChatPrint("SChat: You cannot change the server theme.")
	end
end)

net.Receive("schat.set_tags", function(_, ply)
	if SChat:CanSetChatTags(ply) then
		local tagsData = Settings:Unserialize(net.ReadString())
		Settings:SetChatTags(tagsData, ply:Nick())
	else
		ply:ChatPrint("SChat: You cannot change the chat tags.")
	end
end)

-- the sheer amount of workarounds down here...

-- since PlayerInitialSpawn is called BEFORE the player is ready
-- to receive net events, we have to use ClientSignOnStateChanged instead
hook.Add(
	"ClientSignOnStateChanged",
	"schat_ClientStateChanged",
	function(user, _, new)
		if new == SIGNONSTATE_FULL then
			-- since we can only retrieve the player entity
			-- after this hook runs, lets use a timer
			timer.Simple(0, function()
				local ply = Player(user)
				if not IsValid(ply) then
					return
				end
				if ply:IsBot() then
					return
				end

				-- send the server theme (if set)
				if not table.IsEmpty(Settings.themeData) then
					Settings:ShareTheme(ply)
				end

				-- send the server emojis (if set)
				if not table.IsEmpty(Settings.emojiData) then
					Settings:ShareEmojis(ply)
				end

				-- send chat tags (if set)
				if not table.IsEmpty(Settings.tagsData) then
					Settings:ShareTags(ply)
				end
			end)
		end
	end
)

Settings:Load()

SChat.Settings = Settings
