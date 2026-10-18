local LrView = import 'LrView'
local LrPrefs = import 'LrPrefs'

local bind = LrView.bind
local prefs = LrPrefs.prefsForPlugin(nil)

local DOMAIN = 'com.adobe.LightroomClassicCC7'

-- Slot 1 binds to the legacy menu title "Send to Phone"; slots 2 and 3 to the
-- numbered menu items.
local TITLES = { 'Send to Phone', 'Send to Phone 2', 'Send to Phone 3' }
local PHONE_KEYS = { 'phone_number', 'phone_number_2', 'phone_number_3' }
local SHORTCUT_KEYS = { 'shortcut', 'shortcut_2', 'shortcut_3' }

local SHORTCUTS = {
    { title = 'None', value = 'none' },
    { title = 'Option+S', value = 'option_s' },
    { title = 'Command+Shift+S', value = 'css_s' },
    { title = 'Command+P (replaces Print)', value = 'cmd_p' },
    { title = 'Control+Option+Command+S', value = 'coa_s' },
    { title = 'Option+2', value = 'option_2' },
    { title = 'Option+3', value = 'option_3' },
}

local KEY_MAP = {
    option_s = '~s',
    css_s = '@$s',
    cmd_p = '@p',
    coa_s = '^~@s',
    option_2 = '~2',
    option_3 = '~3',
}

local function shellEscape(s)
    return "'" .. s:gsub("'", [['\'']]) .. "'"
end

local function run(cmd)
    local handle = io.popen(cmd .. ' 2>&1')
    local result = handle:read('*a')
    handle:close()
    return result
end

local function applyShortcuts()
    -- Write all three title bindings in one dict so none are lost.
    local cmd = 'defaults write ' .. DOMAIN .. ' NSUserKeyEquivalents -dict'
    for i = 1, 3 do
        local value = prefs[SHORTCUT_KEYS[i]]
        if value and value ~= 'none' and KEY_MAP[value] then
            local title = TITLES[i]
            cmd = cmd .. ' ' .. shellEscape(title) .. ' ' .. shellEscape(KEY_MAP[value])
                .. ' ' .. shellEscape('   ' .. title) .. ' ' .. shellEscape(KEY_MAP[value])
        end
    end
    return run(cmd)
end

return {
    sectionsForBottomOfDialog = function(f)
        local LrDialogs = import 'LrDialogs'

        local section = {}
        section.title = 'Send to Phone Settings'

        -- Destinations: phone number + shortcut per slot
        for i = 1, 3 do
            if not prefs[SHORTCUT_KEYS[i]] then
                prefs[SHORTCUT_KEYS[i]] = 'none'
            end
            if i == 1 and prefs[SHORTCUT_KEYS[1]] == 'none' then
                prefs[SHORTCUT_KEYS[1]] = 'option_s'
            end
            section[#section + 1] = f:row {
                spacing = 4,
                bind_to_object = prefs,
                f:static_text {
                    title = 'Destination ' .. i .. ':',
                    alignment = 'right',
                    width = LrView.share 'label',
                },
                f:edit_field { value = bind(PHONE_KEYS[i]), width_in_chars = 20, immediate = true },
                f:popup { items = SHORTCUTS, value = bind(SHORTCUT_KEYS[i]), width_in_chars = 24 },
            }
        end

        section[#section + 1] = f:row {
            f:push_button {
                title = 'Apply shortcuts',
                action = function()
                    applyShortcuts()
                    LrDialogs.message('Shortcuts applied. Quit and relaunch Lightroom Classic for them to take effect.')
                end,
            },
            f:static_text { title = '(each destination can have its own shortcut)' },
        }

        section[#section + 1] = f:row {
            spacing = 4,
            bind_to_object = prefs,
            f:static_text { title = 'Export folder:', alignment = 'right', width = LrView.share 'label' },
            f:edit_field { value = bind 'temp_dir', width_in_chars = 40, immediate = true },
        }

        section[#section + 1] = f:row {
            spacing = 4,
            bind_to_object = prefs,
            f:static_text { title = 'Max edge (px):', alignment = 'right', width = LrView.share 'label' },
            f:edit_field { value = bind 'max_size', width_in_chars = 6, immediate = true },
            f:static_text { title = 'JPEG quality (0-1):', alignment = 'right', width = LrView.share 'label' },
            f:edit_field { value = bind 'jpeg_quality', width_in_chars = 5, immediate = true },
        }

        section[#section + 1] = f:row {
            f:static_text {
                title = 'Phone settings apply on next send. Shortcuts require relaunching Lightroom.',
            },
        }

        return { section }
    end,
}
