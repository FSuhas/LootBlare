local weird_vibes_mode = true
local srRollMessages = {}
local msRollMessages = {}
local osRollMessages = {}
local tmogRollMessages = {}
local rollers = {}
local isRolling = false
local time_elapsed = 0
local item_query = 0.5
local times = 5
local discover = CreateFrame("GameTooltip", "CustomTooltip1", UIParent, "GameTooltipTemplate")
local masterLooter = nil

local defaults = {
    srRollCap = 100,
    msRollCap = 100,
    osRollCap = 99,
    tmogRollCap = 98,
}

-- Variables locales
local srRollCap, msRollCap, osRollCap, tmogRollCap

-- Charge les settings depuis RollCap SavedVariable
local function LoadSettings()
    RollCap = RollCap or {}

    srRollCap = RollCap.srRollCap or defaults.srRollCap
    msRollCap = RollCap.msRollCap or defaults.msRollCap
    osRollCap = RollCap.osRollCap or defaults.osRollCap
    tmogRollCap = RollCap.tmogRollCap or defaults.tmogRollCap
end

-- Sauvegarde les settings dans RollCap SavedVariable
local function SaveSettings()
    RollCap.srRollCap = srRollCap
    RollCap.msRollCap = msRollCap
    RollCap.osRollCap = osRollCap
    RollCap.tmogRollCap = tmogRollCap
end

local BUTTON_WIDTH = 32
local BUTTON_COUNT = 4
local BUTTON_PADING = 10
local FONT_NAME = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 12
local FONT_OUTLINE = "OUTLINE"

local RAID_CLASS_COLORS = {
  ["Warrior"] = "FFC79C6E",
  ["Mage"]    = "FF69CCF0",
  ["Rogue"]   = "FFFFF569",
  ["Druid"]   = "FFFF7D0A",
  ["Hunter"]  = "FFABD473",
  ["Shaman"]  = "FF0070DE",
  ["Priest"]  = "FFFFFFFF",
  ["Warlock"] = "FF9482C9",
  ["Paladin"] = "FFF58CBA",
}

local ADDON_TEXT_COLOR= "FFEDD8BB"
local DEFAULT_TEXT_COLOR = "FFFFFF00"
local SR_TEXT_COLOR = "FFFF0000"
local MS_TEXT_COLOR = "FFFFFF00"
local OS_TEXT_COLOR = "FF00FF00"
local TM_TEXT_COLOR = "FF00FFFF"

-- Prefixe et messages du plugin
local LB_PREFIX = "LootBlare"
local LB_GET_DATA = "get data"
local LB_SET_ML = "ML set to "
local LB_SET_ROLL_TIME = "Roll time set to "

-- Fonction de print simplifiée
local function lb_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|c" .. ADDON_TEXT_COLOR .. "LootBlare: " .. msg .. "|r")
end

------------------------------------------------------------------------------------
                 -- Roll Cap Configuration Frame
------------------------------------------------------------------------------------

-- Fonction pour créer une ombre simulée autour du cadre
local function CreateShadow(frame)
  -- Création de la texture d'ombre
  local shadow = frame:CreateTexture(nil, "BACKGROUND")
  shadow:SetAllPoints(frame)
  shadow:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
  shadow:SetVertexColor(0, 0, 0, 0.5) -- Couleur de l'ombre (noir, 50% opacité)
  
  -- Déplacement de l'ombre pour lui donner un effet de profondeur
  shadow:SetPoint("TOPLEFT", 5, -5)
  shadow:SetPoint("BOTTOMRIGHT", -5, 5)
end

-- Créer la frame principale
local frame = CreateFrame("Frame", "RollCapConfigFrame", UIParent)
frame:SetWidth(250)
frame:SetHeight(220)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() frame:StartMoving() end)
frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
frame:SetClampedToScreen(true)
frame:Hide()

-- Backdrop basique
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.85) -- Fond sombre et semi-transparent
  frame:SetBackdropBorderColor(0.2, 0.2, 0.2)

-- Créer l'ombre simulée
CreateShadow(frame)

-- Titre
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText("Roll Caps settings")

-- Fonction pour créer label + EditBox (version 1.12)
local function CreateLabeledInput(parent, labelText, yOffset)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 40, yOffset)
    label:SetText(labelText)

    local input = CreateFrame("EditBox", nil, parent)
    input:SetWidth(60)
    input:SetHeight(20)
    input:SetPoint("LEFT", label, "RIGHT", 10, 0)
    input:SetAutoFocus(false)
    input:SetFontObject(GameFontHighlightSmall)
    input:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
    })
    input:SetBackdropColor(0, 0, 0, 0.5)
    input:SetMaxLetters(3) -- max 3 chiffres
    input:SetTextInsets(5, 5, 3, 3)

    -- On va valider manuellement à la sauvegarde, pas ici

    return input
end

-- Inputs
local srInput = CreateLabeledInput(frame, "srRollCap :", -50)
local msInput = CreateLabeledInput(frame, "msRollCap :", -85)
local osInput = CreateLabeledInput(frame, "osRollCap :", -120)
local tmogInput = CreateLabeledInput(frame, "tmogRollCap :", -155)

-- Met à jour les inputs
local function RefreshInputs()
    srInput:SetText(tostring(srRollCap))
    msInput:SetText(tostring(msRollCap))
    osInput:SetText(tostring(osRollCap))
    tmogInput:SetText(tostring(tmogRollCap))
end

-- Bouton enregistrer
local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
saveButton:SetWidth(120)
saveButton:SetHeight(25)
saveButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
saveButton:SetText("Save")

saveButton:SetScript("OnClick", function()
    local vals = {
        sr = tonumber(srInput:GetText()),
        ms = tonumber(msInput:GetText()),
        os = tonumber(osInput:GetText()),
        tmog = tonumber(tmogInput:GetText())
    }

    -- Validation entre 1 et 200
    local capsNames = { sr = "SR", ms = "MS", os = "OS", tmog = "TMOG" }
    for k, v in pairs(vals) do
        if not v or v < 1 or v > 200 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Erreur:|r invalid value for " .. capsNames[k] .. "RollCap (from 1 to 200)")
            return
        end
    end

    srRollCap = vals.sr
    msRollCap = vals.ms
    osRollCap = vals.os
    tmogRollCap = vals.tmog


    SaveSettings()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Roll Caps updates !|r")
    frame:Hide()
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event)
      LoadSettings()
      RefreshInputs()
end)

-- Slash commande
SLASH_ROLLCAP1 = "/lbr"
SlashCmdList["ROLLCAP"] = function(msg)
    if frame:IsShown() then
        frame:Hide()
    else
        RefreshInputs()
        frame:Show()
    end
end


------------------------------------------------------------------------------------
                 -- LootBlare Main Functionality
------------------------------------------------------------------------------------

-- Fonction pour réinitialiser les messages de roll
local function resetRolls()
  srRollMessages = {}
  msRollMessages = {}
  osRollMessages = {}
  tmogRollMessages = {}
  rollers = {}
end

-- Fonction pour trier les messages de rolls
local function sortRolls()
  local function sortRollsByMessageType(rollMessages)
    table.sort(rollMessages, function(a, b)
      return a.roll > b.roll
    end)
  end

  -- Trier chaque type de message de roll
  sortRollsByMessageType(srRollMessages)
  sortRollsByMessageType(msRollMessages)
  sortRollsByMessageType(osRollMessages)
  sortRollsByMessageType(tmogRollMessages)
end

-- Fonction pour colorier les messages en fonction de la classe et de la catégorie du roll
local function colorMsg(message)
  msg = message.msg
  class = message.class
  _,_,_, message_end = string.find(msg, "(%S+)%s+(.+)")
  classColor = RAID_CLASS_COLORS[class]
  textColor = DEFAULT_TEXT_COLOR

  if string.find(msg, "-"..srRollCap) then
    textColor = SR_TEXT_COLOR
  elseif string.find(msg, "-"..msRollCap) then
    textColor = MS_TEXT_COLOR
  elseif string.find(msg, "-"..osRollCap) then
    textColor = OS_TEXT_COLOR
  elseif string.find(msg, "-"..tmogRollCap) then
    textColor = TM_TEXT_COLOR
  end

  colored_msg = "|c" .. classColor .. "" .. message.roller .. "|r |c" .. textColor .. message_end .. "|r"
  return colored_msg
end

-- Fonction pour obtenir la taille d'une table (fonction utilitaire)
local function tsize(t)
  local c = 0
  for _ in pairs(t) do
    c = c + 1
  end
  return c > 0 and c or nil
end

-- Fonction pour vérifier l'état d'un item (s'il est déjà récupéré)
local function CheckItem(link)
  -- Essayer de récupérer les informations de l'item
  discover:SetOwner(UIParent, "ANCHOR_PRESERVE")
  discover:SetHyperlink(link)

  -- Vérification si les données de l'item sont déjà récupérées
  if discoverTextLeft1 and discoverTooltipTextLeft1:IsVisible() then
    local name = discoverTooltipTextLeft1:GetText()
    discoverTooltip:Hide()

    -- Si l'item est encore en train d'être récupéré, retourner false
    if name == (RETRIEVING_ITEM_INFO or "") then
      return false
    else
      return true
    end
  end
  return false
end


-- Fonction pour créer un bouton de fermeture stylisé
local function CreateCloseButton(frame)
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetWidth(32)
  closeButton:SetHeight(32)
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)

  closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
  closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
  closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")

  closeButton:SetScript("OnClick", function()
    frame:Hide()
    resetRolls()
  end)
end

-- Créer un bouton d'action avec des effets visuels améliorés
local function CreateActionButton(frame, buttonText, tooltipText, index, onClickAction)
  local panelWidth = frame:GetWidth()
  local spacing = (panelWidth - (BUTTON_COUNT * BUTTON_WIDTH)) / (BUTTON_COUNT + 1)
  local button = CreateFrame("Button", nil, frame)

  -- Taille et positionnement du bouton
  button:SetWidth(BUTTON_WIDTH)
  button:SetHeight(BUTTON_WIDTH)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", index * spacing + (index - 1) * BUTTON_WIDTH, BUTTON_PADING)

  -- Texte du bouton
  button:SetText(buttonText)
  local font = button:GetFontString()
  font:SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  -- Fond du bouton
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(button)
  bg:SetTexture(1, 1, 1, 1)
  bg:SetVertexColor(0.2, 0.2, 0.2, 1)
  bg:SetGradient("VERTICAL", 0.3, 0.3, 0.3, 0.1, 0.1, 0.1)  -- Dégradé vertical sombre

  -- Effet de survol : Changer la couleur du fond avec une transition douce
  button:SetScript("OnEnter", function(self)
    bg:SetGradient("VERTICAL", 0.1, 0.1, 0.1, 0.3, 0.3, 0.3)  -- Changer vers un dégradé plus clair au survol
    button:SetBackdropBorderColor(0.8, 0.8, 0.8)  -- Bordure claire au survol
    
    -- Affichage de l'info-bulle
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
    GameTooltip:Show()
  end)

  -- Retour à la couleur de fond normale lorsqu'on quitte
  button:SetScript("OnLeave", function(self)
    bg:SetTexture(1, 1, 1, 1)
    bg:SetVertexColor(0.2, 0.2, 0.2, 1)
    bg:SetGradient("VERTICAL", 0.3, 0.3, 0.3, 0.1, 0.1, 0.1)
    GameTooltip:Hide()
  end)

  -- Action sur clic
  button:SetScript("OnClick", function()
    onClickAction()
  end)
end

-- Fonction pour créer le cadre principal des rolls avec ombre simulée
local function CreateItemRollFrame()
  local frame = CreateFrame("Frame", "ItemRollFrame", UIParent)
  frame:SetWidth(220)
  frame:SetHeight(250)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

  -- Ajouter un fond élégant avec des bordures douces
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.85) -- Fond sombre et semi-transparent
  frame:SetBackdropBorderColor(0.2, 0.2, 0.2)

  -- Créer l'ombre simulée
  CreateShadow(frame)

  -- Ajouter des fonctionnalités de déplacement
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() frame:StartMoving() end)
  frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

  -- Créer le bouton de fermeture
  CreateCloseButton(frame)

  -- Créer les boutons d'action pour les différents types de rolls
  CreateActionButton(frame, "SR", "Roll for Soft Reserve", 1, function() RandomRoll(1, srRollCap) end)
  CreateActionButton(frame, "MS", "Roll for Main Spec", 2, function() RandomRoll(1, msRollCap) end)
  CreateActionButton(frame, "OS", "Roll for Off Spec", 3, function() RandomRoll(1, osRollCap) end)
  CreateActionButton(frame, "TM", "Roll for Transmog", 4, function() RandomRoll(1, tmogRollCap) end)

  -- Ajouter un fondu lors de l'apparition du cadre
  frame:SetAlpha(0)
  frame:Hide()
  UIFrameFadeIn(frame, 0.5, frame:GetAlpha(), 1)

  return frame
end

local itemRollFrame = CreateItemRollFrame()

-- Fonction pour initialiser les informations de l'item
local function InitItemInfo(frame)
  local icon = frame:CreateTexture()
  icon:SetWidth(40)
  icon:SetHeight(40)
  icon:SetPoint("TOP", frame, "TOP", 0, -10)

  local iconButton = CreateFrame("Button", nil, frame)
  iconButton:SetWidth(40)
  iconButton:SetHeight(40)
  iconButton:SetPoint("TOP", frame, "TOP", 0, -10)

  local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  timerText:SetPoint("CENTER", frame, "TOPLEFT", 30, -32)
  timerText:SetFont(timerText:GetFont(), 20)

  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("TOP", icon, "BOTTOM", 0, -10)

  frame.icon = icon
  frame.iconButton = iconButton
  frame.timerText = timerText
  frame.name = name
  frame.itemLink = ""

  -- Tooltip et interaction avec animation
  local tt = CreateFrame("GameTooltip", "CustomTooltip2", UIParent, "GameTooltipTemplate")
  iconButton:SetScript("OnEnter", function()
    tt:SetOwner(iconButton, "ANCHOR_RIGHT")
    tt:SetHyperlink(frame.itemLink)
    tt:Show()
  end)
  iconButton:SetScript("OnLeave", function()
    tt:Hide()
  end)
  iconButton:SetScript("OnClick", function()
    if IsControlKeyDown() then
      DressUpItemLink(frame.itemLink)
    elseif IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
      local itemName, itemLink, itemQuality = GetItemInfo(frame.itemLink)
      ChatFrameEditBox:Insert(ITEM_QUALITY_COLORS[itemQuality].hex.."\124H"..itemLink.."\124h["..itemName.."]\124h"..FONT_COLOR_CODE_CLOSE)
    end
  end)
end

-- Fonction pour afficher un texte coloré en fonction de la qualité de l'item
local function GetColoredTextByQuality(text, qualityIndex)
  local r, g, b, hex = GetItemQualityColor(qualityIndex)
  return string.format("%s%s|r", hex, text)
end

-- Fonction pour mettre à jour les informations de l'item
local function SetItemInfo(frame, itemLinkArg)
  local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(itemLinkArg)
  if not frame.icon then InitItemInfo(frame) end

  if itemName and itemQuality < 2 then return false end
  if not itemIcon then
    frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.name:SetText("Unknown item, attempting to query...")
    return true
  end

  frame.icon:SetTexture(itemIcon)
  frame.iconButton:SetNormalTexture(itemIcon)
  frame.name:SetText(GetColoredTextByQuality(itemName, itemQuality))
  frame.itemLink = itemLink
  return true
end

-- Fonction pour afficher le cadre avec les informations de l'item et la minuterie
local function ShowFrame(frame, duration, item)
  -- Fonction pour obtenir la couleur RVB en fonction de la qualité de l'item
  local function GetBorderColorByQuality(qualityIndex)
    if qualityIndex then
      local r, g, b = GetItemQualityColor(qualityIndex)
      return r, g, b
    else
      -- Couleur par défaut (gris clair par exemple)
      return 0.5, 0.5, 0.5
    end
  end

  -- Fonction pour définir la couleur de la bordure du cadre
  local function SetShowFrameBorderColor(frame, qualityIndex)
    local r, g, b = GetBorderColorByQuality(qualityIndex)  -- Obtenons la couleur de la bordure
    frame:SetBackdropBorderColor(r, g, b)  -- Applique la couleur à la bordure du cadre
  end

  -- Obtenir l'indice de qualité de l'objet (supposons que `item` est une chaîne avec un lien d'objet)
  local function GetItemQualityIndex(itemLink)
    local _, _, qualityIndex = GetItemInfo(itemLink)  -- Récupère la qualité de l'objet
    return qualityIndex or nil
  end
  
  -- Récupérer l'indice de qualité de l'objet
  local qualityIndex = GetItemQualityIndex(item)
  
  -- Définir la couleur de la bordure en fonction de la qualité de l'objet
  SetShowFrameBorderColor(frame, qualityIndex)

  frame:SetScript("OnUpdate", function()
    time_elapsed = time_elapsed + arg1
    item_query = item_query - arg1
    if frame.timerText then
      frame.timerText:SetText(format("%.1f", duration - time_elapsed))
    end
    if time_elapsed >= duration then
      frame.timerText:SetText("0.0")
      frame:SetScript("OnUpdate", nil)
      time_elapsed = 0
      item_query = 1.5
      times = 3
      rollMessages = {}
      isRolling = false
      if FrameAutoClose and not (masterLooter == UnitName("player")) then
        frame:Hide()
      end
    end
    if times > 0 and item_query < 0 and not CheckItem(item) then
      times = times - 1
    else
      if not SetItemInfo(itemRollFrame, item) then frame:Hide() end
      times = 5
    end
  end)
  
  frame:Show()
end


-- Fonction pour créer un texte area
local function CreateTextArea(frame)
  local textArea = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textArea:SetHeight(150)
  textArea:SetPoint("TOP", frame, "TOP", 0, -80)
  textArea:SetJustifyH("LEFT")
  textArea:SetJustifyV("TOP")

  return textArea
end

local function GetClassOfRoller(rollerName)
  -- Iterate through the raid roster
  for i = 1, GetNumRaidMembers() do
      local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
      if name == rollerName then
          return class -- Return the class as a string (e.g., "Warrior", "Mage")
      end
  end
  return nil -- Return nil if the player is not found in the raid
end

local function UpdateTextArea(frame)
  if not frame.textArea then
    frame.textArea = CreateTextArea(frame)
  end

  -- frame.textArea:SetTeClear()  -- Clear the existing messages
  local text = ""
  local colored_msg = ""
  local count = 0

  sortRolls()

  for i, v in ipairs(srRollMessages) do
    if count >= 5 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(msRollMessages) do
    if count >= 6 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(osRollMessages) do
    if count >= 7 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(tmogRollMessages) do
    if count >= 8 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end

  frame.textArea:SetText(text)
end

local function ExtractItemLinksFromMessage(message)
  local itemLinks = {}
  -- This pattern matches the standard item link structure in WoW
  for link in string.gfind(message, "|c.-|H(item:.-)|h.-|h|r") do
    table.insert(itemLinks, link)
  end
  return itemLinks
end

local function IsSenderMasterLooter(sender)
  local lootMethod, masterLooterPartyID = GetLootMethod()
  if lootMethod == "master" and masterLooterPartyID then
    if masterLooterPartyID == 0 then
      return sender == UnitName("player")
    else
      local senderUID = "party" .. masterLooterPartyID
      local masterLooterName = UnitName(senderUID)
      return masterLooterName == sender
    end
  end
  return false
end

local function HandleChatMessage(event, message, sender)
  if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
    local _,_,duration = string.find(message, "Roll time set to (%d+) seconds")
    duration = tonumber(duration)
    if duration and duration ~= FrameShownDuration then
      FrameShownDuration = duration
      -- The players get the new duration from the master looter after the first rolls
      lb_print("Rolling duration set to " .. FrameShownDuration .. " seconds. (set by Master Looter)")
    end
  elseif event == "CHAT_MSG_LOOT" then
    -- Hide frame for masterlooter when loot is awarded
    if not ItemRollFrame:IsVisible() or masterLooter ~= UnitName("player") then return end

    local _,_,who = string.find(message, "^(%a+) receive.? loot:")
    local links = ExtractItemLinksFromMessage(message)

    if who and tsize(links) == 1 then
      if this.itemLink == links[1] then
        resetRolls()
        this:Hide()
      end
    end
  elseif event == "CHAT_MSG_SYSTEM" then
    local _,_, newML = string.find(message, "(%S+) is now the loot master")
    if newML then
      masterLooter = newML
      playerName = UnitName("player")
      -- if the player is the new master looter, announce the roll time
      if newML == playerName then
        SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. FrameShownDuration .. " seconds", "RAID")
      end
    elseif isRolling and string.find(message, "rolls") and string.find(message, "(%d+)") then
      local _,_,roller, roll, minRoll, maxRoll = string.find(message, "(%S+) rolls (%d+) %((%d+)%-(%d+)%)")
      if roller and roll and rollers[roller] == nil then
        roll = tonumber(roll)
        rollers[roller] = 1
        message = { roller = roller, roll = roll, msg = message, class = GetClassOfRoller(roller) }
        if maxRoll == tostring(srRollCap) then
          table.insert(srRollMessages, message)
        elseif maxRoll == tostring(msRollCap) then
          table.insert(msRollMessages, message)
        elseif maxRoll == tostring(osRollCap) then
          table.insert(osRollMessages, message)
        elseif maxRoll == tostring(tmogRollCap) then
          table.insert(tmogRollMessages, message)
        end
        UpdateTextArea(itemRollFrame)
      end
    end

  elseif event == "CHAT_MSG_RAID_WARNING" and sender == masterLooter then
    local links = ExtractItemLinksFromMessage(message)
    if tsize(links) == 1 then
      -- interaction with other looting addons
      if string.find(message, "^No one has nee") or
        -- prevents reblaring on loot award
        string.find(message,"has been sent to") or
        string.find(message, " received ") then
        return
      end
      resetRolls()
      UpdateTextArea(itemRollFrame)
      time_elapsed = 0
      isRolling = true
      ShowFrame(itemRollFrame,FrameShownDuration,links[1])
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    SendAddonMessage(LB_PREFIX, LB_GET_DATA, "RAID") -- fetch ML info
  elseif event == "ADDON_LOADED"then
    if FrameShownDuration == nil then FrameShownDuration = 15 end
    if FrameAutoClose == nil then FrameAutoClose = true end
    if IsSenderMasterLooter(UnitName("player")) then
      SendAddonMessage(LB_PREFIX, LB_SET_ML .. UnitName("player"), "RAID")
      SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. FrameShownDuration, "RAID")
      itemRollFrame:UnregisterEvent("ADDON_LOADED")
    else
      SendAddonMessage(LB_PREFIX, LB_GET_DATA, "RAID")
    end
  elseif event == "CHAT_MSG_ADDON" and arg1 == LB_PREFIX then
    local prefix, message, channel, sender = arg1, arg2, arg3, arg4

    -- Someone is asking for the master looter and his roll time
    if message == LB_GET_DATA and IsSenderMasterLooter(UnitName("player")) then
      masterLooter = UnitName("player")
      SendAddonMessage(LB_PREFIX, LB_SET_ML .. masterLooter, "RAID")
      SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. FrameShownDuration, "RAID")
    end

    -- Someone is setting the master looter
    if string.find(message, LB_SET_ML) then
      local _,_, newML = string.find(message, "ML set to (%S+)")
      masterLooter = newML
    end
    -- Someone is setting the roll time
    if string.find(message, LB_SET_ROLL_TIME) then
      local _,_,duration = string.find(message, "Roll time set to (%d+)")
      duration = tonumber(duration)
      if duration and duration ~= FrameShownDuration then
        FrameShownDuration = duration
        lb_print("Roll time set to " .. FrameShownDuration .. " seconds.")
      end
    end
  end
end

itemRollFrame:RegisterEvent("ADDON_LOADED")
itemRollFrame:RegisterEvent("CHAT_MSG_SYSTEM")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
itemRollFrame:RegisterEvent("CHAT_MSG_ADDON")
itemRollFrame:RegisterEvent("CHAT_MSG_LOOT")
itemRollFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
itemRollFrame:SetScript("OnEvent", function () HandleChatMessage(event,arg1,arg2) end)


-- local itemID = 19852  -- ID de l'item

-- ShowFrame(itemRollFrame, 30, itemID)

itemRollFrame:Hide()

-- Register the slash command
SLASH_LOOTBLARE1 = '/lootblare'
SLASH_LOOTBLARE2 = '/lb'

-- Command handler
SlashCmdList["LOOTBLARE"] = function(msg)
  msg = string.lower(msg)
  if msg == "" then
    if itemRollFrame:IsVisible() then
      itemRollFrame:Hide()
    else
      itemRollFrame:Show()
    end
  elseif msg == "help" then
    lb_print("LootBlare is a simple addon that displays and sort item rolls in a frame.")
    lb_print("Type /lb time <seconds> to set the duration the frame is shown. This value will be automatically set by the master looter after the first rolls.")
    lb_print("Type /lb autoClose on/off to enable/disable auto closing the frame after the time has elapsed.")
    lb_print("Type /lb settings to see the current settings.")
    lb_print("Type /lbr to open the Roll Cap Configuration Frame.")
  elseif msg == "settings" then
    lb_print("Frame shown duration: " .. FrameShownDuration .. " seconds.")
    lb_print("Auto closing: " .. (FrameAutoClose and "on" or "off"))
    lb_print("Master Looter: " .. (masterLooter or "unknown"))
  elseif string.find(msg, "time") then
    local _,_,newDuration = string.find(msg, "time (%d+)")
    newDuration = tonumber(newDuration)
    if newDuration and newDuration > 0 then
      FrameShownDuration = newDuration
      lb_print("Roll time set to " .. newDuration .. " seconds.")
      if IsSenderMasterLooter(UnitName("player")) then
        SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. newDuration, "RAID")
      end
    else
      lb_print("Invalid duration. Please enter a number greater than 0.")
    end
  elseif string.find(msg, "autoclose") then
    local _,_,autoClose = string.find(msg, "autoclose (%a+)")
    if autoClose == "on" or autoClose == "true" then
      lb_print("Auto closing enabled.")
      FrameAutoClose = true
    elseif autoClose == "off" or autoClose == "false" then
      lb_print("Auto closing disabled.")
      FrameAutoClose = false
    else
      lb_print("Invalid option. Please enter 'on' or 'off'.")
    end
  else
  lb_print("Invalid command. Type /lb help for a list of commands.")
  end
end