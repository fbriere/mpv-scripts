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

    - brace-expand.lua (optional, from the same repository as this script)
    will enable the use of Bash-style brace expansions.

    - [luaposix](https://github.com/luaposix/luaposix) (optional) will provide
    better support for wildcards, as well as symbolic link resolution (see the
    NOTES section below).


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

        # Sub-profile descriptions are actually glob(7) patterns, so
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


    PSEUDO-PROPERTIES:

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


    ADDITIONAL FEATURES:

    Options set in a profile applied by this script will only take effect
    on individual files, and will be restored to their previous value
    afterwards.

    If `use-filedir-conf` is enabled, this script will not apply any profiles
    in the presence of a file-specific or directory-specific configuration
    file.  You can therefore disable/override it for specific files or
    directories by creating a (possibly empty) *FILE.conf* or *DIR/mpv.conf*
    file.  (This configuration file could then pull in the original profile if
    desired.)


    NOTES:

    This script will output some additional information on higher
    verbosity levels (`-v`).  To increase the verbosity for this script
    only, use `--msg-level=tree_profiles=v` (or `=debug` for more output).

    Any leading `~/` in a `tree:` argument will be expanded to the user's
    home directory.  (Other `~~` prefixes are currently not supported.)

    The `tree:` argument should really be an absolute path (although this
    is not mandated for now).  Otherwise, it will be relative to the
    current directory, which could get rather confusing.

    Keep in mind that the `tree:` argument is a plain directory name, not
    a pattern, and therefore does not support wildcards.

    The wildcard support provided by this script is somewhat simplistic, and
    does not faithfully adhere to the `glob(7)` specification (mostly regarding
    bracket expressions).  If luaposix is installed, the real
    standard-compliant `fnmatch(3)` will be used instead.

    I have yet to determine how this script should behave in the presence
    of symbolic links.  At the moment, provided that luaposix is installed,
    symlinks are fully resolved before comparing paths for sub-profiles, but
    not for the parent profile.  This may change in the future.

    The `sub-paths-dir` feature has now been removed; it can be emulated by
    adding `sub-file-paths=<sub-paths-dir>/${tree-profiles-directory}` to each
    parent profile.


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

-- Provides us with a better fnmatch(), as well as realpath() and stat()
local posix = prequire 'posix'
if not posix then
    msg.debug("luaposix not found -- falling back on alternatives")
end


local DIR_SEPARATOR = package.config:sub(1,1)


-- Adapted from http://lua-users.org/wiki/StringRecipes
function string:startswith(prefix)
    return self:sub(1, #prefix) == prefix
end

local function file_exists(name)
    if posix then
        return posix.stat(name) ~= nil
    else
        -- Copied from https://stackoverflow.com/a/4991602
        local f = io.open(name, "r")
        if f ~= nil then
            io.close(f)
            return true
        else
            return false
        end
    end
end

local function isdir(name)
    return utils.readdir(name .. "/.") ~= nil
end

local function fnmatch(glob, path)
    if posix then
        return posix.fnmatch(glob, path, posix.FNM_PATHNAME)
    else
        -- Our homebrewed version, without the corner cases.  Inspired by
        -- https://github.com/gordonbrander/lettersmith/blob/master/lettersmith/wildcards.lua

        -- Convert a whole wildcard pattern into a Lua pattern
        local function wildcard(s)
            -- Convert the contents of a single bracket expression
            local function bracket_expr(s)
                -- BUG: ']' should be allowed unescaped as first char
                -- BUG: '-' should be left as-is as first/last char
                -- BUG: '[' and '\' should stand for themselves
                -- BUG: '/' should never match even if explicitly included
                s = s
                    :gsub("^[%!%^]", "__CCLASS_COMPLEMENT__")
                    :gsub("%-",  "__CCLASS_DASH__")
                    -- '?' and '*' do not act as wildcards here
                    :gsub("%?", "__ESCAPED_" .. string.byte("?") .. "__")
                    :gsub("%*", "__ESCAPED_" .. string.byte("*") .. "__")
                return "__CCLASS_START__" .. s .. "__CCLASS_END__"
            end

            s = s
                -- Escaped characters
                -- BUG: "\" should no longer escape within brackets
                :gsub("%\\(%W)", function(s)
                        return "__ESCAPED_" .. string.byte(s) .. "__"
                    end)
                -- Alpha-numeric characters should be unescaped
                :gsub("%\\(%w)", "%1")

                -- Bracket expressions
                :gsub("%[(.-)%]", bracket_expr)

                -- The usual wildcards
                :gsub("%*",   "__ANY_STRING__")
                :gsub("%?",   "__ANY_CHAR__")

                -- Escape any non-alpha character (except "_", which we need
                -- to be left intact -- it's not magic anyway)
                :gsub("[^%w_ ]", "%%%1")

                -- Replace all tokens with their Lua counterpart
                -- BUG: Wildcards should not match any leading '.'
                :gsub("__ANY_CHAR__", "[^/]")
                :gsub("__ANY_STRING__", "[^/]*")
                :gsub("__CCLASS_START__", "[")
                :gsub("__CCLASS_COMPLEMENT__", "^")
                :gsub("__CCLASS_DASH__", "-")
                :gsub("__CCLASS_END__", "]")
                :gsub("__ESCAPED_(%d+)__", function(n)
                        return "%" .. string.char(n)
                    end)

            -- Anchor the pattern at beginning and end
            return "^" .. s .. "$"
        end

        local pattern = wildcard(glob)
        msg.debug(string.format("Converted wildcard pattern '%s' into Lua pattern '%s'", glob, pattern))
        return path:match(pattern)
    end
end


-- Create a table of pseudo-properties
local function get_pseudo_props(parent_profile, child_path)
    local pseudo_props = {
        ["parent"] = parent_profile.name,
        ["path"] = child_path,
    }

    local child_path_dir, _ = utils.split_path(child_path)
    -- Cosmetic nitpicking: That trailing "/" just looks annoying to me
    child_path_dir = child_path_dir:gsub("/+$", "")
    pseudo_props["directory"] = child_path_dir

    return pseudo_props
end

-- Expand any leading "~/" in a path
local function expand_path(path)
    if path:sub(1, 2) == "~/" then
        local home = os.getenv("HOME") or os.getenv("USERPROFILE")
        if home then
            path = home .. path:sub(2)
        else
            msg.warn("Failed to get home directory -- neither $HOME nor $USERPROFILE is set")
        end
    end

    return path
end

-- Basically equivalent to Python's os.path.relpath(), but returns nil
-- if path is not located under parent.
local function child_relpath(path, parent)
    if posix then
        -- FIXME: realpath() may or may not be the right solution
        path = posix.realpath(path)
        parent = posix.realpath(parent)
    end

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
            dir = expand_path(dir)
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
local function apply_local_profile(profile, pseudo_props, depth)
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
                apply_local_profile(subprofile, pseudo_props, depth)
            else
                msg.error(string.format("Unknown profile %q.", v))
            end
        else
            -- Convert "no-foo" to "foo=no"
            if k:startswith("no-") then
                k = k:sub(4)
                v = "no"
            end
            -- Expand pseudo-properties
            for prop_name, prop_value in pairs(pseudo_props) do
                local pattern = "${tree-profiles-" .. prop_name .. "}"
                -- Escape all non-alphanumeric characters
                pattern = pattern:gsub("([^%w])", "%%%1")
                v = v:gsub(pattern, prop_value)
            end
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
local function apply_profiles(parent_profile, child_path, pseudo_props)
    msg.verbose("Applying profile", parent_profile.name)
    apply_local_profile(parent_profile, pseudo_props)

    walk_path(child_path, function(step)
        msg.debug(string.format("Checking for profiles matching '%s'", step))
        for _, profile in ipairs(mp.get_property_native("profile-list")) do
            if profile.name:startswith(parent_profile.name .. "/") then
                -- TODO: Filter duplicates if braces match twice
                local desc = profile["profile-desc"]
                if desc then
                    msg.debug(string.format("Testing against %s ('%s')", profile.name, desc))
                    for _, glob in ipairs(brace_expand.expand(desc)) do
                        if fnmatch(glob, step) then
                            msg.verbose("Applying profile", profile.name)
                            apply_local_profile(profile, pseudo_props)
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

local function on_start_file()
    local options = {
        ["sub-paths-dir"] = "",
    }

    local fullpath = utils.join_path(mp.get_property("working-directory"), mp.get_property("path"))

    if isdir(fullpath) then
        msg.verbose("This is a directory -- skipping")
        return
    end

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
        if mp.find_config_file(file_confname) then
            msg.verbose("file-specific configuration file found -- quitting")
            return
        end
    end

    local pseudo_props = get_pseudo_props(parent_profile, child_path)
    apply_profiles(parent_profile, child_path, pseudo_props)

    -- Applying profiles may have changed script-opts
    read_options(options)
    -- Deprecation warning for sub-paths-dir
    if options["sub-paths-dir"] ~= "" then
        msg.warn("sub-paths-dir script option support has been removed")
        msg.warn("Use ${tree-profiles-directory} in the profile's configuration instead")
    end
end
mp.register_event("start-file", on_start_file)
