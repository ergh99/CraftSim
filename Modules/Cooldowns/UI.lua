---@class CraftSim
local CraftSim = select(2, ...)

---@class CraftSim.COOLDOWNS
CraftSim.COOLDOWNS = CraftSim.COOLDOWNS

---@class CraftSim.COOLDOWNS.UI
CraftSim.COOLDOWNS.UI = {}

---@class CraftSim.COOLDOWNS.FRAME : GGUI.Frame
CraftSim.COOLDOWNS.frame = nil

local GUTIL = CraftSim.GUTIL
local GGUI = CraftSim.GGUI
local L = CraftSim.UTIL:GetLocalizer()
local f = GUTIL:GetFormatter()
local LID = CraftSim.CONST.TEXT

local print = CraftSim.DEBUG:SetDebugPrint(CraftSim.CONST.DEBUG_IDS.COOLDOWNS)

function CraftSim.COOLDOWNS.UI:Init()
    local sizeX = 670
    local sizeY = 220
    local offsetX = 0
    local offsetY = 0

    ---@class CraftSim.COOLDOWNS.FRAME : GGUI.Frame
    CraftSim.COOLDOWNS.frame = GGUI.Frame({
        parent = ProfessionsFrame,
        anchorParent = ProfessionsFrame,
        anchorA = "TOPRIGHT",
        anchorB = "BOTTOMRIGHT",
        sizeX = sizeX,
        sizeY = sizeY,
        offsetY = offsetY,
        offsetX = offsetX,
        frameID = CraftSim.CONST.FRAMES.COOLDOWNS,
        title = L(CraftSim.CONST.TEXT.COOLDOWNS_TITLE),
        collapseable = true,
        closeable = true,
        moveable = true,
        backdropOptions = CraftSim.CONST.DEFAULT_BACKDROP_OPTIONS,
        onCloseCallback = CraftSim.CONTROL_PANEL:HandleModuleClose("MODULE_COOLDOWNS"),
        frameTable = CraftSim.INIT.FRAMES,
        frameConfigTable = CraftSim.DB.OPTIONS:Get("GGUI_CONFIG"),
        frameStrata = CraftSim.CONST.MODULES_FRAME_STRATA,
        raiseOnInteraction = true,
        frameLevel = CraftSim.UTIL:NextFrameLevel()
    })

    ---@class CraftSim.COOLDOWNS.FRAME.CONTENT : Frame
    CraftSim.COOLDOWNS.frame.content = CraftSim.COOLDOWNS.frame.content

    ---@class CraftSim.COOLDOWNS.FRAME.CONTENT : Frame
    local content = CraftSim.COOLDOWNS.frame.content

    content.cooldownList = GGUI.FrameList {
        parent = content, anchorParent = content, anchorA = "TOPLEFT", anchorB = "TOPLEFT", offsetY = -60, offsetX = 20,
        showBorder = true, sizeY = 147, selectionOptions = { noSelectionColor = true, hoverRGBA = CraftSim.CONST.FRAME_LIST_SELECTION_COLORS.HOVER_LIGHT_WHITE },
        columnOptions = {
            {
                label = L(LID.COOLDOWNS_CRAFTER_HEADER),
                width = 150,
            },
            {
                label = L(LID.COOLDOWNS_RECIPE_HEADER),
                width = 150,
            },
            {
                label = L(LID.COOLDOWNS_CHARGES_HEADER),
                width = 70,
                justifyOptions = { type = "H", align = "CENTER" }
            },
            {
                label = L(LID.COOLDOWNS_NEXT_HEADER),
                width = 120,
                justifyOptions = { type = "H", align = "CENTER" }
            },
            {
                label = L(LID.COOLDOWNS_ALL_HEADER),
                width = 120,
            },
        },
        rowConstructor = function(columns, row)
            ---@class CraftSim.COOLDOWNS.CooldownList.Row : GGUI.FrameList.Row
            row = row
            ---@type CraftSim.CooldownData
            row.cooldownData = nil
            row.allchargesFullTimestamp = 0
            ---@class CraftSim.COOLDOWNS.CooldownList.CrafterColumn : Frame
            local crafterColumn = columns[1]
            ---@class CraftSim.COOLDOWNS.CooldownList.RecipeColumn : Frame
            local recipeColumn = columns[2]
            ---@class CraftSim.COOLDOWNS.CooldownList.ChargesColumn : Frame
            local chargesColumn = columns[3]
            ---@class CraftSim.COOLDOWNS.CooldownList.NextColumn : Frame
            local nextColumn = columns[4]
            ---@class CraftSim.COOLDOWNS.CooldownList.AllColumn : Frame
            local allColumn = columns[5]

            crafterColumn.text = GGUI.Text {
                parent = crafterColumn, anchorParent = crafterColumn, justifyOptions = { type = "H", align = "LEFT" },
                anchorA = "LEFT", anchorB = "LEFT",
            }
            recipeColumn.text = GGUI.Text {
                parent = recipeColumn, anchorParent = recipeColumn, justifyOptions = { type = "H", align = "LEFT" },
                anchorA = "LEFT", anchorB = "LEFT", fixedWidth = 150,
            }
            chargesColumn.slash = GGUI.Text {
                parent = chargesColumn, anchorParent = chargesColumn, text = "/"
            }
            chargesColumn.current = GGUI.Text {
                parent = chargesColumn, anchorParent = chargesColumn.slash.frame, justifyOptions = { type = "H", align = "RIGHT" },
                anchorA = "RIGHT", anchorB = "LEFT",
            }
            chargesColumn.max = GGUI.Text {
                parent = chargesColumn, anchorParent = chargesColumn.slash.frame, justifyOptions = { type = "H", align = "LEFT" },
                anchorA = "LEFT", anchorB = "RIGHT",
            }
            chargesColumn.SetCharges = function(self, current, max)
                current = math.min(current, max)
                if current == max and max > 0 then
                    chargesColumn.current:SetText(f.g(current))
                    chargesColumn.max:SetText(f.g(max))
                elseif max > 0 then
                    chargesColumn.current:SetText(f.l(current))
                    chargesColumn.max:SetText(f.l(max))
                else
                    chargesColumn.current:SetText("-")
                    chargesColumn.max:SetText("-")
                end
            end
            nextColumn.text = GGUI.Text {
                parent = nextColumn, anchorParent = nextColumn, fixedWidth = 120,
            }
            allColumn.text = GGUI.Text {
                parent = allColumn, anchorParent = allColumn, justifyOptions = { type = "H", align = "LEFT" },
                anchorA = "LEFT", anchorB = "LEFT",
            }
        end

    }

    CraftSim.COOLDOWNS.frame:HookScript("OnShow", function()
        CraftSim.COOLDOWNS:StartTimerUpdate()
    end)
    CraftSim.COOLDOWNS.frame:HookScript("OnHide", function()
        CraftSim.COOLDOWNS:StopTimerUpdate()
    end)
end

function CraftSim.COOLDOWNS.UI:UpdateDisplay()
    CraftSim.COOLDOWNS.UI:UpdateList()
    CraftSim.COOLDOWNS.UI:UpdateTimers()
end

function CraftSim.COOLDOWNS.UI:UpdateList()
    local cooldownList = CraftSim.COOLDOWNS.frame.content.cooldownList

    cooldownList:Remove()

    local crafterCooldownData = CraftSim.DB.CRAFTER:GetCrafterCooldownData()

    for crafterUID, recipeCooldowns in pairs(crafterCooldownData) do
        for serializationID, cooldownDataSerialized in pairs(recipeCooldowns) do
            local cooldownData = CraftSim.CooldownData:Deserialize(cooldownDataSerialized)
            local recipeID = cooldownData.recipeID

            cooldownList:Add(
            ---@param row CraftSim.COOLDOWNS.CooldownList.Row
                function(row)
                    row.cooldownData = cooldownData
                    local columns = row.columns
                    local crafterColumn = columns[1] --[[@as CraftSim.COOLDOWNS.CooldownList.CrafterColumn]]
                    local recipeColumn = columns[2] --[[@as CraftSim.COOLDOWNS.CooldownList.RecipeColumn]]
                    local chargesColumn = columns[3] --[[@as CraftSim.COOLDOWNS.CooldownList.ChargesColumn]]
                    local nextColumn = columns[4] --[[@as CraftSim.COOLDOWNS.CooldownList.NextColumn]]
                    local allColumn = columns[5] --[[@as CraftSim.COOLDOWNS.CooldownList.AllColumn]]

                    local crafterClass = CraftSim.DB.CRAFTER:GetClass(crafterUID)
                    local crafterName = f.class(select(1, strsplit("-", crafterUID), crafterClass))
                    local tooltipText = f.class(crafterUID, crafterClass)

                    local professionInfo = CraftSim.DB.CRAFTER:GetProfessionInfoForRecipe(crafterUID, recipeID) or
                        C_TradeSkillUI.GetProfessionInfoByRecipeID(recipeID)
                    local professionIcon = ""
                    if professionInfo.profession then
                        professionIcon = CraftSim.CONST.PROFESSION_ICONS[professionInfo.profession]
                        professionIcon = GUTIL:IconToText(professionIcon, 20, 20) .. " "
                    end

                    crafterColumn.text:SetText(professionIcon .. crafterName)

                    local recipeInfo = CraftSim.DB.CRAFTER:GetRecipeInfo(crafterUID, recipeID) or
                        C_TradeSkillUI.GetRecipeInfo(recipeID)


                    if cooldownData.sharedCD then
                        recipeColumn.text:SetText(L(CraftSim.CONST.SHARED_PROFESSION_COOLDOWNS[cooldownData.sharedCD]))
                        local recipeListText = ""
                        for _, sharedRecipeID in pairs(CraftSim.CONST.SHARED_PROFESSION_COOLDOWNS_RECIPES[cooldownData.sharedCD]) do
                            local sharedRecipeIDInfo = CraftSim.DB.CRAFTER:GetRecipeInfo(crafterUID, sharedRecipeID) or
                                C_TradeSkillUI.GetRecipeInfo(sharedRecipeID)

                            if sharedRecipeIDInfo then
                                recipeListText = recipeListText .. "\n" .. sharedRecipeIDInfo.name
                            end
                        end
                        if #recipeListText > 0 then
                            tooltipText = tooltipText ..
                                f.bb("\n\nRecipes sharing this Cooldown:\n") .. f.white(recipeListText)
                        end
                    else
                        recipeColumn.text:SetText((recipeInfo and recipeInfo.name) or serializationID)
                    end

                    row.tooltipOptions = {
                        text = tooltipText,
                        owner = row.frame,
                        anchor = "ANCHOR_CURSOR",
                    }

                    row.UpdateTimers = function(self)
                        print("Updating Timers for " .. tostring(recipeInfo.name))
                        local cooldownData = self.cooldownData
                        chargesColumn:SetCharges(cooldownData:GetCurrentCharges(), cooldownData.maxCharges)
                        local allFullTS, ready = cooldownData:GetAllChargesFullTimestamp()
                        local cdReady = ready or cooldownData:GetCurrentCharges() >= cooldownData.maxCharges
                        nextColumn.text:SetText(cdReady and f.grey("-") or
                            f.bb(cooldownData:GetFormattedTimerNextCharge()))
                        row.allchargesFullTimestamp = allFullTS
                        if cdReady then
                            allColumn.text:SetText(f.g("Ready"))
                        else
                            allColumn.text:SetText(f.g(cooldownData:GetAllChargesFullDateFormatted()))
                        end
                    end

                    row:UpdateTimers()
                end)
        end
    end

    cooldownList:UpdateDisplay(
    ---@param rowA CraftSim.COOLDOWNS.CooldownList.Row
    ---@param rowB CraftSim.COOLDOWNS.CooldownList.Row
        function(rowA, rowB)
            return rowA.allchargesFullTimestamp < rowB.allchargesFullTimestamp
        end)
end

function CraftSim.COOLDOWNS.UI:UpdateTimers()
    local cooldownList = CraftSim.COOLDOWNS.frame.content.cooldownList

    for _, activeRow in pairs(cooldownList.activeRows) do
        activeRow:UpdateTimers()
    end
end
