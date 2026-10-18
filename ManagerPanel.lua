local LrView = import 'LrView'
local LrPrefs = import 'LrPrefs'

local bind = LrView.bind
local prefs = LrPrefs.prefsForPlugin(nil)

local DOMAIN = 'com.adobe.LightroomClassicCC7'

local SHORTCUTS = {
    { title = 'Option+S', value = 'option_s' },
    { title = 'Command+P (replaces Print)', value = 'cmd_p' },
    { title = 'Control+Option+Command+S', value = 'coa_s' },
    { title = 'None', value = 'none' },
}

local KEY_MAP = {
    option_s = '~s',
    cmd_p = '@p',
    coa_s = '^~@s',
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

local function applyShortcut(prefValue)
    local keys = KEY_MAP[prefValue]
    local cmd
    if keys then
        cmd = 'defaults write ' .. DOMAIN .. ' NSUserKeyEquivalents -dict '
            .. shellEscape('Send to Phone') .. ' ' .. shellEscape(keys) .. ' '
            .. shellEscape('   Send to Phone') .. ' ' .. shellEscape(keys)
    else
        cmd = 'defaults delete ' .. DOMAIN .. ' NSUserKeyEquivalents'
    end
    return run(cmd)
end

return {
    sectionsForBottomOfDialog = function(f)
        local LrDialogs = import 'LrDialogs'

        if not prefs.shortcut then
            prefs.shortcut = 'option_s'
        end

        local section = {}
        section.title = 'Send to Phone Settings'

        section[#section + 1] = f:row {
            spacing = 4,
            bind_to_object = prefs,
            f:static_text { title = 'Phone number:', alignment = 'right', width = LrView.share 'label' },
            f:edit_field { value = bind 'phone_number', width_in_chars = 20, immediate = true },
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
            spacing = 4,
            bind_to_object = prefs,
            f:static_text { title = 'Keyboard shortcut:', alignment = 'right', width = LrView.share 'label' },
            f:popup { items = SHORTCUTS, value = bind 'shortcut', width_in_chars = 24 },
            f:push_button {
                title = 'Apply',
                action = function()
                    applyShortcut(prefs.shortcut)
                    LrDialogs.message('Shortcut applied. Quit and relaunch Lightroom Classic for it to take effect.')
                end,
            },
        }

        section[#section + 1] = f:row {
            f:static_text {
                title = 'Settings apply on next send. Shortcuts require relaunching Lightroom.',
            },
        }

        return { section }
    end,
}
