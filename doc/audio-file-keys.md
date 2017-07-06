# audio-file-keys.lua

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

Wouldn't it be nice to be able to swap those keys only when playing audio
files?  This is what this script makes possible.


## USAGE

Simply add some key bindings to the `audio-file` input session in
*~/.config/mpv/input.conf*, such as:

    # Have Page Up/Down emulate Shift + Page Up/Down
    PGUP  {audio-file} keypress Shift+PGUP
    PGDWN {audio-file} keypress Shift+PGDWN

You can override the name of the input session used by this script by
setting it in *~/.config/mpv/lua-settings/audio_file_keys.conf*:

    section=some-other-name


## REQUIREMENTS

This script requires mpv version 0.10.0 or later.


## NOTES

Technically, the trigger for this script is not directly based on the
contents of the file being played, but rather on the presence or
absence of a window.  Therefore, an audio file with image attachments
will be considered as being a video file (unless `audio-display=no`).

This also means that this script can be forcibly disabled for all
files with `--force-window`, or forcibly enabled with `--no-video`.
(Note that setting `vo=null` will not have any effect, however.)


## AUTHOR

Frédéric Brière (fbriere@fbriere.net)

Licensed under the GNU General Public License, version 2 or later.

