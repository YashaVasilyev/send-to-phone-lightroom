# Send to Phone — Lightroom Classic Plugin

One-click photo transfer from Lightroom Classic to your iPhone via iMessage.

Select a photo, hit **⌥S** (or File > Plug-in Extras > Send to Phone), and the
plugin exports an Instagram-ready JPEG and texts it to your phone instantly —
ready to post. No phone-side app, no iCloud Photos sync wait.

## How it works

1. Exports the most-selected photo at 2048px, sRGB JPEG (~90% quality) — ideal
   for Instagram.
2. Sends the file via iMessage using the [`imsg`](https://imsg.sh) CLI, which
   handles the AppleScript attachment quirks of modern macOS.
3. Cleans up the temp file.

## Requirements

- Lightroom Classic (tested on 26.6.2)
- macOS with Messages signed in to the same Apple ID as your iPhone
- [imsg](https://imsg.sh) CLI: `brew install steipete/tap/imsg`
- **Full Disk Access** granted to Lightroom Classic
  (System Settings > Privacy & Security > Full Disk Access) — imsg stages
  attachments inside `~/Library/Messages`.

## Install

1. Clone or download this repo, then in Lightroom Classic:
   **File > Plug-in Manager > Add** — select `send-to-phone.lrdevplugin`.
2. Edit `PHONE_NUMBER` at the top of `SendToPhone.lua` to your own number.
3. Optional keyboard shortcut (⌥S):

   ```bash
   defaults write com.adobe.LightroomClassicCC7 NSUserKeyEquivalents -dict \
     "Send to Phone" '~s' \
     "   Send to Phone" '~s'
   ```

   Quit and relaunch Lightroom after setting it. (The indented variant matters —
   Lightroom indents Plug-in Extras menu items with three spaces and the title
   must match exactly.)

## Usage

Select a photo (Library or Develop), press **⌥S**, and the photo arrives in
Messages on your phone seconds later. Tap to save to Photos and post.

## Configuration

All settings live in `SendToPhone.lua`:

| Variable | Default | Purpose |
|---|---|---|
| `PHONE_NUMBER` | `+1857...` | Destination for the iMessage |
| `TEMP_DIR` | `/tmp/send-to-phone` | Where the JPEG is rendered |
| `LR_size_maxWidth/Height` | `2048` | Export dimensions |
| `LR_jpeg_quality` | `0.9` | JPEG quality |

## Notes

- AirDrop has no scriptable API, and push services (Pushover, ntfy) require a
  phone app — iMessage is the only fully automatic, zero-app path.
- iCloud Photos sync was the original delivery method (via an AppleScript
  import into Photos.app); it works but sync is slow. iMessage is instant.

## License

MIT
