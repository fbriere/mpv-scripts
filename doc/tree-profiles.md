# tree-profiles.lua

Automatically apply profiles to certain directories or files.

This mpv Lua script makes it easy to automatically apply a profile to
a given directory, or to specific files within that directory, without
the need to enable `use-filedir-conf` and scatter *.conf* files
everywhere.

For a more detailed description of what this does, please refer to the
[Example](#example) section below.

(This script was initially written to "scratch my own itch", but I hope it
can be useful to other people as well.  Feedback is most welcome!)


## USAGE

Simply drop this script (along with brace-expand.lua, ideally) in your
scripts configuration directory (usually *~/.config/mpv/scripts/*), and
define some profiles in your main mpv configuration file (*mpv.conf*) as
illustrated in the [Example](#example) section below.


## REQUIREMENTS

- This script requires mpv version 0.21.0 or later.

- luaposix is also required at the moment.  (Therefore this script won't
work on Windows, at least for now.)

- brace-expand.lua (optional, from the same repository as this script)
will enable the use of Bash-style brace expansions.


## EXAMPLE

Suppose your media files are arranged thusly:

    /media/
        anime/
            Angel Beats!/
                Angel-Beats-01.mkv
                ...
            Fullmetal Alchemist/
                Season 1/
                    Fullmetal Alchemist S01E01.mkv
                    ...
                Season 2/
                    Fullmetal Alchemist S02E01.mkv
                    ...
        documentaries/
            ...

Your *mpv.conf* could contain the following:

    #
    # Profiles with a description starting with "tree:" will be
    # automatically applied to all files under that directory tree.
    #

    [anime]
    profile-desc="tree:/media/anime"
    alang=jpn
    slang=eng

    [documentary]
    profile-desc="tree:/media/documentaries"
    no-sub

    # A more specific match will eclipse others.  For example, this
    # profile will be applied *instead* of the "anime" profile for this
    # directory.  (Hence the "profile=anime" to explicitly pull it in.)
    #
    [angel-beats]
    profile-desc="tree:/media/anime/Angel Beats!"
    profile=anime
    sid=5

    #
    # These profiles can also have sub-profiles, to be applied to specific
    # files or directories under the parent profile's directory tree.
    #
    # These sub-profiles are identified by their name, which starts with
    # "<parent-profile-name>/"; the description then specifies which
    # directories/files they should be applied to.
    #
    # Sub-profiles are applied in *addition* to their parent profile.  If
    # several sub-profiles match, they are *all* applied.  (They are
    # applied while walking down the directory tree, so generic
    # matches will typically occur before specific matches.  The order in
    # which they appear in the configuration files does not matter.)
    #
    # For example, all "anime/*" profiles below are sub-profiles of the
    # "anime" profile.
    #

    # The description can be a simple directory name (which conveniently
    # is also the series name in our example).  Here's a simpler
    # equivalent to the previous profile:
    #
    [anime/angel-beats]
    profile-desc="Angel Beats!"
    sid=5

    # The description can also be a subdirectory or a file:
    #
    [anime/fma]
    profile-desc="Fullmetal Alchemist"
    [anime/fma-s1]
    profile-desc="Fullmetal Alchemist/Season 1"
    [anime/fma-s1-ep01]
    profile-desc="Fullmetal Alchemist/Season 1/Fullmetal Alchemist S01E01.mkv"

    # Sub-profile descriptions are actually fnmatch(3) patterns, so
    # wildcards ('?', '*', '[') are supported:
    #
    [anime/fma-s1-ep02-03-04]
    profile-desc="Fullmetal Alchemist/Season ?/Full* S01E0[2-4].mkv"
    #
    # This means you will have to escape these characters if they should
    # be matched literally:
    #
    [anime/gochiusa]
    profile-desc="Gochuumon wa Usagi Desu ka\?"
    # or:
    profile-desc="Gochuumon wa Usagi Desu ka[?]"

    # Bash-style brace expansion is also supported (if brace-expand.lua
    # was installed alongside this script):
    #
    [anime/fma-s1-ep07-16]
    profile-desc="Fullmetal Alchemist/*/* S01E{07,16}.mkv"
    [anime/fma-s1-ep08-09-10-11]
    profile-desc="Fullmetal Alchemist/*/* S01E{08..11}.mkv"
    [anime/fma-s1-ep13-15-18-19-20]
    profile-desc="Fullmetal Alchemist/*/* S01E{13,15,{18..20}}.mkv"


## PSEUDO-PROPERTIES

The configuration of any profile applied by this script can make use of the
following "pseudo-properties", which will be expanded to their respective
value:

- `${tree-profiles-parent}`: Name of the parent profile matching the
currently played file.

- `${tree-profiles-path}`: Path of the currently played file, relative to
the parent profile's directory.  (Basically, `${path}` with the parent
profile's directory stripped out.)

- `${tree-profiles-directory}`: Directory of the currently played file,
relative to the parent profile's directory.  (Basically, the directory
portion of `${tree-profiles-path}`.)

(Note that these are not actual, real properties; they can only be used in
*mpv.conf*, and only in profiles applied by this script.  Furthermore,
only the plain `${NAME}` form is supported.)


## ADDITIONAL FEATURES

Options set in a profile applied by this script will only take effect
on individual files, and will be restored to their previous value
afterwards.

If `use-filedir-conf` is enabled, this script will not apply any profiles
in the presence of a file-specific or directory-specific configuration
file.  You can therefore disable/override it for specific files or
directories by creating a (possibly empty) *FILE.conf* or *DIR/mpv.conf*
file.  (This configuration file could then pull in the original profile if
desired.)


## NOTES

This script will output some additional information on higher
verbosity levels (`-v`).  To increase the verbosity for this script
only, use `--msg-level=tree_profiles=v` (or `=debug` for more output).

The aforementioned override does not take into account *.conf*
files in *~/.config/mpv/* at the moment.

The `tree:` argument should really be an absolute path (although this
is not mandated for now).  Otherwise, it will be relative to the
current directory, which could get rather confusing.

Unfortunately, `~` prefixes are currently *not* supported.  (This may
change in the future.)

Keep in mind that the `tree:` argument is a plain directory name, not
a pattern, and therefore does not support wildcards.

I have yet to determine how this script should behave in the presence
of symbolic links.  At the moment, symlinks are fully resolved before
comparing paths.  This may change in the future.

The `sub-paths-dir` feature has now been removed; it can be emulated by
adding `sub-file-paths=<sub-paths-dir>/${tree-profiles-directory}` to each
parent profile.


## AUTHOR

Frédéric Brière (fbriere@fbriere.net)

Licensed under the GNU General Public License, version 2 or later.


## THANKS

Thanks to V. Lang (@wm4) for auto-profiles.lua, which was tremendously
helpful as a starting point (https://github.com/wm4/mpv-scripts).

