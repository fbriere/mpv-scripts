--[[

    Automatically apply key bindings when playing audio files.

    When playing audio files in a terminal, some key combinations may be
    intercepted by the terminal and therefore made unavailable to mpv.  For
    example, `Shift` + `Page Up/Down` (seek forward/backward 10 min by default)
    usually activates scrollback in most terminals.

    A simple solution to this issue involves swapping those keys with others
    (usually `Page Up/Down`, since audio files seldom include chapters).
    Unfortunately, since key bindings are applied globally, this also affects
    the playing of video files, where those other keys may be used more
    frequently, making their remapping somewhat undesirable.

    Wouldn't it be nice to be able to define a different set of key bindings
    for audio files?  This is the purpose of this script.


    USAGE:

    Simply drop this script in your scripts configuration directory (usually
    *~/.config/mpv/scripts/*), and add some key bindings to the `audio-file`
    input section in *~/.config/mpv/input.conf*, such as:

        # Have Page Up/Down emulate Shift + Page Up/Down for audio files
        PGUP  {audio-file} keypress Shift+PGUP
        PGDWN {audio-file} keypress Shift+PGDWN


    REQUIREMENTS:

    This script requires mpv version 0.10.0 or later.


    NOTES:

    Technically, the trigger for this script is not directly based on the
    contents of the file being played, but rather on the presence or
    absence of a window.  Therefore, an audio file with image attachments
    will be considered as being a video file (unless `audio-display=no`).

    This also means that this script can be forcibly disabled for all
    files with `--force-window`, or forcibly enabled with `--no-video`.
    (Note that setting `vo=null` will not have any effect, however.)


    AUTHOR:

    Frédéric Brière (fbriere@fbriere.net)

    Licensed under the GNU General Public License, version 2 or later.

--]]

local msg = require 'mp.msg'
local utils = require 'mp.utils'
require 'mp.options'

if not mp.input_enable_section then
    msg.error("This script requires mpv version 0.10.0 or later")
    return
end


local options = {
    ["section"] = "audio-file",
}
read_options(options)
local section = options["section"]


local seen = false
local function on_property_change(name, value)
    if value then
        msg.verbose("Video window present -- disabling input section", section)
        mp.input_disable_section(section)
    else
        msg.verbose("No video window -- enabling input section", section)
        if not seen then
            -- I haven't found a way to reliably skip those
            msg.verbose("(This is normal, even for video files, when mpv is starting up.)")
        end
        mp.input_enable_section(section)
    end
    seen = true
end
mp.observe_property("vo-configured", "bool", on_property_change)

