# [sub-fonts-dir-auto.lua](https://github.com/fbriere/mpv-scripts/blob/master/scripts/sub-fonts-dir-auto.lua)

Automatically look for a fonts directory to use with `sub-fonts-dir`.

This mpv Lua script will automatically use the `sub-fonts-dir` option (to
override the default `~~/fonts` location) if it find a `Fonts` directory
alongside the currently playing file.  (The name of the directory is
matched case-insensitively.)

**NOTE:** The `sub-fonts-dir` option has been submitted as part of [PR
#9856](https://github.com/mpv-player/mpv/pull/9856).  Until it is merged
upstream, you will have to download and compile the [mpv
source](https://github.com/mpv-player/mpv) yourself.


## USAGE

Simply drop this script in your scripts configuration directory (usually
`~/.config/mpv/scripts/`).


## REQUIREMENTS

This script requires a version of mpv that includes the `sub-fonts-dir`
option.


## NOTES

- Any `--sub-fonts-dir` option passed on the command-line will override
this script.

- When going through a playlist, `sub-fonts-dir` will be dynamically
updated for each individual file.

- This script will output some additional information on higher verbosity
levels (`-v`).  To increase the verbosity for this script only, use
`--msg-level=sub_fonts_dir_auto=v` (or `=debug` for more output).


## AUTHOR

Frédéric Brière (fbriere@fbriere.net)

Licensed under the GNU General Public License, version 2 or later.

