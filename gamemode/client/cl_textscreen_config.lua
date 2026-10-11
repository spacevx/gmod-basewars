BaseWars.TextscreenConfigLoaded = BaseWars.TextscreenConfigLoaded or false

net.Receive("textscreens_config", function()
	local length = net.ReadUInt(16)
	if length > 16000 then return end
	BaseWars.TextscreenConfig = length > 0 and net.ReadData(length) or ""
	BaseWars.TextscreenConfigLoaded = true
	if IsValid(BaseWars.TextscreenPanel) then
		BaseWars.TextscreenPanel:LoadFromConfig()
	end
end)
