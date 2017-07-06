--[[

    Automatically apply profiles to certain directories or files.
    
    This mpv Lua script makes it easy to automatically apply a profile to
    a given directory, or to specific files within that directory, without
    the need to enable `use-filedir-conf` and scatter *.conf* files
    everywhere.

    For a more detailed description of what this does, please refer to the
    EXAMPLE section below.

    (This script was initially written to "scratch my own itch", but I hope it
    can be useful to other people as well.  Feedback is most welcome!)


    USAGE:

    Simply drop this script (along with brace-expand.lua, ideally) in your
    scripts configuration directory (usually *~/.config/mpv/scripts/*), and
    define some profiles in your main mpv configuration file (*mpv.conf*) as
    illustrated in the EXAMPLE section below.


    REQUIREMENTS:

    - This script requires mpv version 0.21.0 or later.

    - luaposix is also required at the moment.  (Therefore this script won't
    work on Windows, at least for now.)

    - brace-expand.lua (optional, from the same repository as this script)
    will enable the use of Bash-style brace expansions.


    EXAMPLE:

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


    SUB-PATHS FEATURE:

    This script can also automatically add a `sub-paths` entry referring
    to a directory structure mirroring that of the media files.

    In other words, suppose your external subtitles are arranged thusly:

        /nas/
            subtitles/
                Fullmetal Alchemist/
                    Season 1/
                        Fullmetal Alchemist S01E01.ass
                        ...

    After setting the `sub-paths-dir` script option to `/nas/subtitles`,
    the appropriate directory will automatically be appended to the
    `sub-paths` option for every file under */media/anime*.

    You can set this option globally, by adding it to
    *~/.config/mpv/lua-settings/tree_profiles.conf*:

        sub-paths-dir=/nas/subtitles

    You can also set it on the command-line (or in regular configuration
    files) with the `script-opts` option:

        --script-opts=tree_profiles-sub-paths-dir=/nas/subtitles


    ADDITIONAL FEATURES:

    Options set in a profile applied by this script will only take effect
    on individual files, and will be restored to their previous value
    afterwards.

    This script will not apply any profiles in the presence of a
    file-specific or directory-specific configuration file.  You can
    therefore disable/override it for specific files or directories by
    creating a (possibly empty) *FILE.conf* or *DIR/mpv.conf* file.
    (This configuration file could then pull in the original profile if
    desired.)


    NOTES:

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


    AUTHOR:

    Frédéric Brière (fbriere@fbriere.net)

    Licensed under the GNU General Public License, version 2 or later.


    THANKS:

    Thanks to V. Lang (@wm4) for auto-profiles.lua, which was tremendously
    helpful as a starting point (https://github.com/wm4/mpv-scripts).

--]]


local msg = require 'mp.msg'
local utils = require 'mp.utils'
require 'mp.options'

-- The "profile-list" property was introduced in v0.21.0
do
    local prop, err = mp.get_property("profile-list")
    if not prop then
        if err == "property not found" then
            msg.error("This script requires mpv version 0.21.0 or later")
        else
            msg.error(string.format("%s command not supported: %s", "profile-list", err))
        end
        return
    end
end

-- This is currently required for fnmatch() and realpath()
-- TODO: Could this be made optional?
local posix = require 'posix'

-- Optional require(), copied from https://stackoverflow.com/a/17878208
local function prequire(m)
    local ok, err = pcall(require, m)
    if not ok then return nil, err end
    return err
end
-- Don't fail if brace-expand.lua wasn't installed alongside us
local brace_expand = prequire 'brace-expand'
if not brace_expand then
    msg.warn("brace-expand.lua not found -- brace expansion disabled")
    brace_expand = { expand = function(x) return {x} end }
end


local DIR_SEPARATOR = package.config:sub(1,1)


-- Adapted from http://lua-users.org/wiki/StringRecipes
function string:startswith(prefix)
    return self:sub(1, #prefix) == prefix
end

local function file_exists(name)
    return posix.stat(name) ~= nil
end

-- Basically equivalent to Python's os.path.relpath(), but returns nil
-- if path is not located under parent.
local function child_relpath(path, parent)
    -- FIXME: realpath() may or may not be the right solution
    path = posix.realpath(path)
    parent = posix.realpath(parent)

    if not parent or not path then
        return nil
    elseif path:startswith(parent .. DIR_SEPARATOR) then
        return path:sub(#parent + 2)
    elseif path == parent then
        return "."
    else
        return nil
    end
end

-- Apply func() to each step of a path
local function walk_path(path, func)
    local i = 0
    while true do
        i = path:find(DIR_SEPARATOR, i + 1)
        if i == nil then break end
        func(path:sub(1, i - 1))
    end
    func(path)
end

-- Find the parent profile matching a full path, and convert the child to a
-- relative path under the directory tree.  Returns (parent-name, child-path).
local function find_lineage(fullpath)
    msg.verbose("Searching for parent profile of", fullpath)
    local retval

    for _, profile in ipairs(mp.get_property_native("profile-list")) do
        local desc = profile["profile-desc"]
        if desc and desc:startswith("tree:") then
            local dir = desc:sub(6)
            -- TODO: Support paths starting with "~"
            msg.debug(string.format("Trying %s (%s)", profile.name, dir))
            local child_path = child_relpath(fullpath, dir)
            if child_path then
                msg.debug("Profile matches as a parent")
                if retval and not (#child_path < #retval.child) then
                    msg.debug("Match is not better than previous candidate")
                else
                    retval = { parent = profile, child = child_path }
                end
            end
        end
    end

    if retval then
        return retval.parent, retval.child
    else
        return
    end
end

-- Apply a profile locally to the current playing file.  Options set here
-- will be restored to their previous value on the next file.
local MAX_PROFILE_DEPTH = 20
local function apply_local_profile(profile, depth)
    local function find_profile_by_name(name)
        for _,p in ipairs(mp.get_property_native("profile-list")) do
            if p.name == name then
                return p
            end
        end
    end

    depth = depth or 0
    if depth > MAX_PROFILE_DEPTH then
        -- This is a warning in mpv, but it triggers an error later on
        msg.error("Profile inclusion too deep.")
        return
    end
    depth = depth + 1
    msg.debug(string.format("Locally applying profile %q (depth %d)", profile.name, depth))

    for _, option in ipairs(profile.options) do
        k,v = option.key, option.value
        -- TODO: Should we also handle "include"?  Others?
        if k == "profile" then
            local subprofile = find_profile_by_name(v)
            if subprofile then
                msg.debug(string.format("Locally including profile %q", v))
                apply_local_profile(subprofile, depth)
            else
                msg.error(string.format("Unknown profile %q.", v))
            end
        else
            -- FILE_LOCAL_FLAGS implies M_SETOPT_PRESERVE_CMDLINE
            if not mp.get_property_bool(string.format("option-info/%s/set-from-commandline", k)) then
                msg.debug(string.format("Locally setting %s = %q", k, v))
                mp.set_property(string.format("file-local-options/%s", k), v)
            else
                msg.verbose(string.format("Option %s was set on command-line -- leaving it as-is", k))
            end
        end
    end
end

-- Apply a parent profile and all applicable sub-profiles.
local function apply_profiles(parent_profile, child_path)
    msg.verbose("Applying profile", parent_profile.name)
    apply_local_profile(parent_profile)

    walk_path(child_path, function(step)
        msg.debug(string.format("Checking for profiles matching '%s'", step))
        for _, profile in ipairs(mp.get_property_native("profile-list")) do
            if profile.name:startswith(parent_profile.name .. "/") then
                -- TODO: Filter duplicates if braces match twice
                local desc = profile["profile-desc"]
                if desc then
                    msg.debug(string.format("Testing against %s ('%s')", profile.name, desc))
                    for _, glob in ipairs(brace_expand.expand(desc)) do
                        if posix.fnmatch(glob, step, posix.FNM_PATHNAME) then
                            msg.verbose("Applying profile", profile.name)
                            apply_local_profile(profile)
                        end
                    end
                else
                    -- FIXME: This will be output on every step
                    msg.warn("Profile", profile.name, "is lacking profile-desc -- skipping")
                end
            end
        end
    end)
end

-- Add <sub-paths-dir>/<child-path-dir> to sub-paths
local function add_sub_path(options, child_path)
    local sub_paths_dir = options["sub-paths-dir"]
    if sub_paths_dir == "" then
        msg.verbose("sub-paths-dir not set -- not adding any sub-paths")
        return
    end

    local child_path_dir, _ = utils.split_path(child_path)
    -- Cosmetic nitpicking: That trailing "/" just looks annoying to me
    child_path_dir = child_path_dir:gsub("/+$", "")
    -- Cosmetic nitpicking: Adding a "." component does nothing useful
    if child_path_dir ~= "." then
        sub_paths_dir = utils.join_path(sub_paths_dir, child_path_dir)
    end

    msg.verbose("Adding", sub_paths_dir, "to sub-paths")

    local sub_paths = mp.get_property("sub-paths")
    if sub_paths ~= "" then
        sub_paths = sub_paths .. ':' .. sub_paths_dir
    else
        sub_paths = sub_paths_dir
    end
    msg.debug("Setting sub-paths to", sub_paths)
    mp.set_property("sub-paths", sub_paths)
end

-- This probably won't be of any use to you at the moment.  :-)
local function load_chapters_file(options, child_path)
    local function find_chapters_file(dir, filename_no_ext)
        -- NOTE: I made these up  :-)
        local extensions = { "chp", "chapters" }

        for _, ext in ipairs(extensions) do
            local chapname = utils.join_path(dir, filename_no_ext .. "." .. ext)
            msg.debug("Checking for chapters file", chapname)
            if file_exists(chapname) then
                msg.debug("Chapters file found")
                return chapname
            end
        end
    end

    local chapters_file_dir = options["chapters-file-dir"]
    if chapters_file_dir == "" then
        msg.verbose("chapters-file-dir not set")
        return
    end
    chapters_file_dir = utils.join_path(chapters_file_dir, (utils.split_path(child_path)))

    local dirname, filename = utils.split_path(mp.get_property("path"))
    local chapters_file = find_chapters_file(
        utils.join_path(dirname, chapters_file_dir),
        mp.get_property("filename/no-ext"))
    if chapters_file then
        msg.verbose("Setting chapters file to", chapters_file)
        mp.set_property("chapters-file", chapters_file)
    end
end

local function on_start_file()
    local options = {
        ["sub-paths-dir"] = "",
        ["chapters-file-dir"] = "",
    }

    local fullpath = utils.join_path(mp.get_property("working-directory"), mp.get_property("path"))
    local parent_profile, child_path = find_lineage(fullpath)
    if not parent_profile then
        msg.verbose("No parent profile found -- exiting")
        return
    end

    if mp.get_property_bool("use-filedir-conf") then
        local dirname, filename = utils.split_path(mp.get_property("path"))
        if file_exists(utils.join_path(dirname, "mpv.conf")) then
            msg.verbose("directory-specific configuration file found -- quitting")
            return
        end
        local file_confname = filename .. '.conf'
        if file_exists(utils.join_path(dirname, file_confname)) then
            msg.verbose("file-specific configuration file found -- quitting")
            return
        end
        -- TODO: Also check for file_confname in config dir (~~)
    end

    apply_profiles(parent_profile, child_path)

    -- Applying profiles may have changed script-opts
    read_options(options)
    add_sub_path(options, child_path)
    load_chapters_file(options, child_path)
end
mp.register_event("start-file", on_start_file)
