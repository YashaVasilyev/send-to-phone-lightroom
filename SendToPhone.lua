local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrProgressScope = import 'LrProgressScope'
local LrApplication = import 'LrApplication'
local LrLogger = import 'LrLogger'
local LrFunctionContext = import 'LrFunctionContext'

local myLogger = LrLogger('SendToPhone')
myLogger:enable('print')

local SendToPhone = {}

-- Configuration priority: plugin preferences (set in Plug-in Manager)
-- > Config.lua (created by setup.sh; gitignored) > built-in defaults.
local prefsOk, prefs = pcall(function()
    return import 'LrPrefs':prefsForPlugin(_PLUGIN)
end)
if not prefsOk or type(prefs) ~= 'table' then
    prefs = {}
end

local ok, config = pcall(require, 'Config')
if not ok or type(config) ~= 'table' then
    config = {}
end

local function getSetting(key, default)
    local v = prefs[key]
    if v == nil or v == '' then
        v = config[key]
    end
    if v == nil or v == '' then
        return default
    end
    return v
end

local PHONE_NUMBER = getSetting('phone_number', nil)
local TEMP_DIR = getSetting('temp_dir', '/tmp/send-to-phone')
local MAX_SIZE = tonumber(getSetting('max_size', 2048))
local JPEG_QUALITY = tonumber(getSetting('jpeg_quality', 0.9))

local function run(cmd)
    local handle = io.popen(cmd .. ' 2>&1')
    local result = handle:read('*a')
    handle:close()
    return result
end

local function shellEscape(s)
    return "'" .. s:gsub("'", [['\'']]) .. "'"
end

local function sendViaiMessage(path)
    local cmd = '/opt/homebrew/bin/imsg send --to ' .. shellEscape(PHONE_NUMBER)
        .. ' --file ' .. shellEscape(path)
    local result = run(cmd)
    if not result or not result:find('sent') then
        myLogger:trace('imsg failed: ' .. tostring(result))
        return false, tostring(result)
    end
    return true
end

function SendToPhone.send()
    LrTasks.startAsyncTask(function()
        if not PHONE_NUMBER then
            LrDialogs.showError('No phone number configured.\n\nRun setup.sh (or copy Config.lua.example to Config.lua and set your number), then reload the plugin.')
            return
        end

        local catalog = LrApplication.activeCatalog()
        local photo = catalog:getTargetPhoto()
        if not photo then
            LrDialogs.showError('No photo selected.')
            return
        end

        local progress = LrProgressScope({ title = 'Sending to phone' })
        progress:setPortionComplete(0, 1)

        run('mkdir -p ' .. shellEscape(TEMP_DIR))

        -- Render the photo with fixed Instagram-ready settings
        local rendered

        LrFunctionContext.callWithContext('sendToPhone', function(functionContext)
            local LrExportSession = import 'LrExportSession'
            local session = LrExportSession({
                functionContext = functionContext,
                photosToExport = { photo },
                exportSettings = {
                    LR_export_bitDepth = 8,
                    LR_export_colorSpace = 'sRGB',
                    LR_export_destinationPathPrefix = TEMP_DIR,
                    LR_export_useSubfolder = false,
                    LR_renamingTokensOnByDefault = true,
                    LR_tokenString = '{{filename}}-phone',
                    LR_collisionHandling = 'rename',
                    LR_format = 'JPEG',
                    LR_jpeg_quality = JPEG_QUALITY or 0.9,
                    LR_size_doConstrain = true,
                    LR_size_maxHeight = MAX_SIZE or 2048,
                    LR_size_maxWidth = MAX_SIZE or 2048,
                    LR_minimizeEmbeddedMetadata = true,
                    LR_removeFaceRegions = true,
                    LR_embeddedMetadataOption = 'copyrightOnly',
                    LR_export_destinationType = 'specificFolder',
                },
            })

            session:doExportOnCurrentTask({
                progress = {
                    function(done, total)
                        progress:setPortionComplete(done, total)
                    end,
                },
            })
        end)

        -- Find newest JPEG in TEMP_DIR
        rendered = run('ls -t ' .. shellEscape(TEMP_DIR) .. '/*.jpg 2>/dev/null | head -1')
        rendered = rendered and rendered:gsub('%s+$', '') or nil

        if not rendered or rendered == '' then
            progress:done()
            LrDialogs.showError('Export failed: no rendered file found in ' .. TEMP_DIR)
            return
        end

        myLogger:trace('Rendered: ' .. tostring(rendered))

        local ok, err = sendViaiMessage(rendered)
        progress:done()

        if not ok then
            LrDialogs.showError('Could not send via iMessage: ' .. tostring(err)
                .. '\n\nIf this is a permissions error, enable it in System Settings > Privacy & Security > Automation (Lightroom Classic > Messages), then restart Lightroom.')
            return
        end

        -- Clean up the temp file
        run('rm -f ' .. shellEscape(rendered))

        LrDialogs.showBezel('Sent to phone')
    end, 'Send to Phone')
end

return SendToPhone
