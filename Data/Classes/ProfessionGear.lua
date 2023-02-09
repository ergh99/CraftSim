_, CraftSim = ...

---@class CraftSim.ProfessionGear
---@field item ItemMixin
---@field professionStats CraftSim.ProfessionStats

CraftSim.ProfessionGear = CraftSim.Object:extend()
local print = CraftSim.UTIL:SetDebugPrint(CraftSim.CONST.DEBUG_IDS.EXPORT_V2)

function CraftSim.ProfessionGear:new()
    self.professionStats = CraftSim.ProfessionStats()
end

function CraftSim.ProfessionGear:SetItem(itemLink)

	if not itemLink then
		return
	end

    self.item = Item:CreateFromItemLink(itemLink)

    -- parse stats
    local extractedStats = GetItemStats(itemLink)

    if not extractedStats then
        print("Could not extract item stats: " .. tostring(itemLink))
        return
    end

    self.professionStats.inspiration.value = extractedStats.ITEM_MOD_INSPIRATION_SHORT or 0

    self.professionStats.multicraft.value = extractedStats.ITEM_MOD_MULTICRAFT_SHORT or 0

    self.professionStats.resourcefulness.value = extractedStats.ITEM_MOD_RESOURCEFULNESS_SHORT or 0

    self.professionStats.craftingspeed.value = extractedStats.ITEM_MOD_CRAFTING_SPEED_SHORT or 0

	local itemID = self.item:GetItemID()
	if CraftSim.CONST.SPECIAL_TOOL_STATS[itemID] then
		local stats = CraftSim.CONST.SPECIAL_TOOL_STATS[itemID]

        if stats.inspirationBonusSkillPercent then
            self.professionStats.inspiration.extraFactor = stats.inspirationBonusSkillPercent
        end
        -- TODO: check if there any other relevant special stats
	end

	local parsedSkill = 0
	local tooltipData = C_TooltipInfo.GetHyperlink(itemLink)

	local parsedEnchantingStats = {
		inspiration = 0,
		resourcefulness = 0,
		multicraft = 0,
	}
	local equipMatchString = CraftSim.LOCAL:GetText(CraftSim.CONST.TEXT.EQUIP_MATCH_STRING)
	local enchantedMatchString = CraftSim.LOCAL:GetText(CraftSim.CONST.TEXT.ENCHANTED_MATCH_STRING)
	local inspirationMatchString = CraftSim.LOCAL:GetText(CraftSim.CONST.TEXT.STAT_INSPIRATION)
	local resourcefulnessMatchString = CraftSim.LOCAL:GetText(CraftSim.CONST.TEXT.STAT_RESOURCEFULNESS)
	local multicraftMatchString = CraftSim.LOCAL:GetText(CraftSim.CONST.TEXT.STAT_MULTICRAFT)
	for _, line in pairs(tooltipData.lines) do
		for _, arg in pairs(line.args) do
			if arg.stringVal and string.find(arg.stringVal, equipMatchString) then
				-- here the stringVal looks like "Equip: +6 Blacksmithing Skill"
				parsedSkill = tonumber(string.match(arg.stringVal, "(%d+)")) or 0
			end
			if arg.stringVal and string.find(arg.stringVal, enchantedMatchString) then
				if string.find(arg.stringVal, inspirationMatchString) then
					parsedEnchantingStats.inspiration = tonumber(string.match(arg.stringVal, "%+(%d+)")) or 0
				elseif string.find(arg.stringVal, resourcefulnessMatchString) then
					parsedEnchantingStats.resourcefulness = tonumber(string.match(arg.stringVal, "%+(%d+)")) or 0
				elseif string.find(arg.stringVal, multicraftMatchString) then
					parsedEnchantingStats.multicraft = tonumber(string.match(arg.stringVal, "%+(%d+)")) or 0
				end
			end
		end
	end

    if parsedSkill > 0 then
        self.professionStats.skill.value = parsedSkill
    end

    if parsedEnchantingStats.inspiration then
        self.professionStats.inspiration.value = self.professionStats.inspiration.value + parsedEnchantingStats.inspiration
    end

    if parsedEnchantingStats.resourcefulness then
        self.professionStats.resourcefulness.value = self.professionStats.resourcefulness.value + parsedEnchantingStats.resourcefulness
    end

    if parsedEnchantingStats.multicraft then
        self.professionStats.multicraft.value = self.professionStats.multicraft.value + parsedEnchantingStats.multicraft
    end
end