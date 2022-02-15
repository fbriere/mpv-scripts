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

-- msg.trace() was added in 0.28.0 -- define it ourselves if it's missing
if msg.trace == nil then
    msg.trace = function(...) return mp.log("trace", ...) end
end

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

-- Try to load brace-expand.lua if available
local brace_expand = prequire 'brace-expand'
-- Only warn a single time if brace-expand.lua is required but missing
local brace_expand_warning_issued
if not brace_expand then
    -- mpv 0.32.0 no longer appends the "scripts" directory to the Lua path,
    -- so we have to load this module ourselves
    local brace_expand_file = mp.find_config_file("scripts/brace-expand.lua")
    if brace_expand_file then
        msg.verbose("Manually loading brace-expand.lua in scripts/ directory")
        f, err = loadfile(brace_expand_file)
        if f then
            brace_expand = f()
        end
    end
    if not brace_expand then
        -- Install a fake module that does nothing but emit a warning if it
        -- looks like brace expansion is required
        brace_expand = { expand = function(s)
            if s:find('{') and not brace_expand_warning_issued then
                msg.warn("brace-expand.lua not found -- brace expansion not supported")
                brace_expand_warning_issued = true
            end
            return {s}
        end }
    end
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
    child_path_dir = child_path_dir:gsub("(.)/+$", "%1")
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

--[[

    LIST OPTIONS COMPATIBILITY HACKS

    List options were overhauled in version 0.26.0: the related properties were
    renamed (e.g. "sub-file" => "sub-files") and action suffixes were
    introduced (e.g. "sub-files-set"), with the original option name now being
    an alias to the "append" action (e.g. "sub-file" => "sub-files-append").

    This aliasing was only meant for the CLI and config file; scripts were now
    supposed to either use action suffixes or set the new property as a whole,
    with the original (deprecated) option name being supported as a fallback
    until 0.29.0.

    Unfortunately, action suffixes (including the "append" action to which the
    old option name was aliased) did not work when using the
    "file-local-options/" prefix, requiring us to parse[*] and apply these
    actions ourselves.  And while 0.29.0 introduced a 'change-list' command
    that could take care of the second part, it too sufferred from the same
    issue until 0.31.0.

    As a result, we provide our own (inferior) version of 'change-list', and
    use it for versions affected by these bugs.

    [*] To be fair, we still need to parse these options to avoid overriding
        command-line options.

--]]

-- Whether list option names should be parsed for action suffixes
local supports_list_option_actions
-- Whether a non-buggy 'change-list' command is available for us to use
local use_native_change_list

-- Initialize the flags listed above.  Since this requires reading file-related
-- properties, it should probably be run only after a file has been loaded.
-- (The results will then be cached for future runs.)
local function list_option_compat_checks()
    -- These checks only need to be performed once
    if supports_list_option_actions ~= nil then return end

    msg.debug("Performing compatibility checks over list option actions...")

    -- Check a property that was renamed ('audio-files' was chosen at random)
    supports_list_option_actions = mp.get_property_native("audio-files") ~= nil
    if supports_list_option_actions then
        msg.debug("- List option actions are supported and will be used")
        -- 'change-list' was fixed when introducing 'shared-script-properties'
        use_native_change_list = mp.get_property_native("shared-script-properties") ~= nil
        if use_native_change_list then
            msg.debug("- 'change-list' should work correctly and will be called directly")
        else
            msg.debug("- 'change-list' may not work correctly and will be emulated instead")
        end
    else
        msg.debug("- List option actions are not supported; properties will be set directly")
    end
end

-- Our own (naive) implementation of the 'change-list' command
local function change_list(option_name, action, value)
    local local_option_name = string.format("file-local-options/%s", option_name)

    -- If 'change-list' is available and working, let it do its magic
    if use_native_change_list then
        return mp.commandv("change-list", local_option_name, action, value)
    end

    -- Otherwise, fetch the list/table which we will need to modify ourselves
    local list = mp.get_property_native(option_name)
    if type(list) ~= "table" then
        msg.error(string.format("'%s' is not a valid list option -- skipping", option_name))
        return
    end

    -- Perform the required action on our local copy of the list
    if action == "set" then
        -- This is a special case which set_property() can handle by itself
        -- correctly in any version
        mp.set_property(local_option_name, value)
        return
    elseif action == "append" then
        table.insert(list, value)
    elseif action == "add" then
        -- NOTE: we don't support >1 items
        table.insert(list, value)
    elseif action == "pre" then
        -- NOTE: we don't support >1 items
        table.insert(list, 1, value)
    elseif action == "clr" then
        list = {}
    elseif action == "remove" then
        msg.error("'remove' list action is currently not supported")
        return
    elseif action == "del" then
        table.remove(list, value + 1)
    elseif action == "toggle" then
        msg.error("'toggle' list action is currently not supported")
        return
    else
        msg.error(string.format("Unknown list option action '%s' -- skipping", action))
        return
    end

    -- Put the final value back in place
    mp.set_property_native(local_option_name, list)
end

-- Handle CLI exceptions to option handling, such as "--no-foo", "--foo-add",
-- or "--foo" being a alias for "--foos-append".  These cannot be set as mere
-- properties, so we have to deal with them ourselves.
--
-- Takes an option name as input, and returns three values: the name of the
-- actual property that should be set/modified, a boolean indicating the
-- presence of a "no" prefix, and a possible action suffix that should be
-- passed as "operation" to the "change-list" command.
--
-- Based on m_config_mogrify_cli_opt() in options/m_config_frontend.c
local function mogrify_option_name(name)
    local negate, action = false, nil

    -- Convert "--no-foo" to "--foo=no"
    if name:startswith("no-") then
        name = name:sub(4)
        negate = true
        -- No further processing is necessary/allowed
        return name, negate, action
    end

    -- List option actions were introduced in 0.26; no need to do anything
    -- else if they are not present.
    if not supports_list_option_actions then
        return name, negate, action
    end

    -- Resolve CLI aliases (such as "--foo" => "--foos-append").  If no alias
    -- exists, the intact option name is returned.
    local function resolve_option(name)
        -- List of all CLI aliases (identified by OPT_CLI_ALIAS throughout the
        -- mpv code).  This list also includes any deprecated aliases
        -- (identified by OPT_REPLACED and OPT_REPLACED_MSG) ultimately
        -- pointing to a CLI alias (indented below their target).  (Remember to
        -- fully resolve the whole chain yourself; this function will not
        -- recurse for you.)
        local aliases = {
            [ "audio-file"        ] = "audio-files-append",
            [     "audiofile"     ] = "audio-files-append",
            [ "external-file"     ] = "external-files-append",
            [ "glsl-shader"       ] = "glsl-shaders-append",
            -- 'opengl-shaders' was renamed to 'glsl-shaders' in 0.28;
            -- the next entry is retained as-is for compatibility
            [ "opengl-shader"     ] = "opengl-shaders-append",
            [ "script"            ] = "scripts-append",
            [     "lua"           ] = "scripts-append",
            [ "sub-file"          ] = "sub-files-append",
            [     "subfile"       ] = "sub-files-append",
        }
        for alias, target in pairs(aliases) do
            if name == alias then
                return target
            end
        end
        return name
    end
    name = resolve_option(name)

    -- Determine if an option suffix is a potential action
    local function is_action(s)
        -- List of all available actions
        local actions = {
            "set", "append", "add", "pre", "clr", "remove", "del", "toggle"
        }
        for _, action in ipairs(actions) do
            if s == action then
                return true
            end
        end
        return false
    end
    -- Try splitting the option name over its last "-"
    local _, _, base, suffix = name:find("^(.+)-(%w+)$")
    -- If the suffix is an actual action, we have a winner!
    if suffix ~= nil and is_action(suffix) then
        name, action = base, suffix
    end

    return name, negate, action
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
        local option_name, value = option.key, option.value
        -- TODO: Should we also handle "include"?  Others?
        if option_name == "profile" then
            local subprofile = find_profile_by_name(value)
            if subprofile then
                msg.debug(string.format("Locally including profile %q", value))
                apply_local_profile(subprofile, pseudo_props, depth)
            else
                msg.error(string.format("Unknown profile %q.", value))
            end
        else
            -- Expand pseudo-properties
            for prop_name, prop_value in pairs(pseudo_props) do
                local pattern = "${tree-profiles-" .. prop_name .. "}"
                -- Escape all non-alphanumeric characters
                pattern = pattern:gsub("([^%w])", "%%%1")
                value = value:gsub(pattern, prop_value)
            end
            -- Deal with "--no-foo", "--foo-add" or "--foo" => "--foos-append"
            local option_name, negate, action = mogrify_option_name(option_name)
            if negate then
                value = "no"
            end
            -- FILE_LOCAL_FLAGS implies M_SETOPT_PRESERVE_CMDLINE
            if not mp.get_property_bool(string.format("option-info/%s/set-from-commandline", option_name)) then
                if action then
                    msg.debug(string.format("Locally performing list action on %s: %s %q", option_name, action, value))
                    change_list(option_name, action, value)
                else
                    msg.debug(string.format("Locally setting %s = %q", option_name, value))
                    mp.set_property(string.format("file-local-options/%s", option_name), value)
                end
            else
                msg.verbose(string.format("Option %s was set on command-line -- leaving it as-is", option_name))
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

-- "on_load" hook callback for when a file is about to be loaded.
local function on_load()
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

    -- Run compatibility checks for list options
    list_option_compat_checks()

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
-- A priority value of 50 is recommended as neutral default value, while
-- player/lua/ytdl_hook.lua uses a value of 10.  We settle for 20, since we
-- want to make sure we'll kick in rather early.  (Maybe this should be a
-- configurable option?)
mp.add_hook("on_load", 20, on_load)
