--[[

    Perform Bash-style brace expansion on a string, returning a sequence of
    all resulting strings.  Braces can be nested, and sequence expressions are
    supported.


    USAGE:

        brace_expand = require 'brace-expand'

        s1 = brace_expand.expand("{1!,a } {-2..08..5} {z..x}")

        -- The sequence returned above is identical to this one:
        s2 = {
            "1! -2 z",   "1! -2 y",   "1! -2 x",
            "1! 03 z",   "1! 03 y",   "1! 03 x",
            "1! 08 z",   "1! 08 y",   "1! 08 x",

            "a  -2 z",   "a  -2 y",   "a  -2 x",
            "a  03 z",   "a  03 y",   "a  03 x",
            "a  08 z",   "a  08 y",   "a  08 x",
        }


    NOTES:

    Special characters (`{` `,` `.` `}`) can be quoted by preceding
    then with a backslash.  That backslash is currently left in place and
    *not* removed from the results.  (This may change in the future.)

    Only the characters listed above have any special meaning; in
    particular, spaces and quotes are treated like any other character.
    (The sequence `${` is not treated differently either.)

    Otherwise, this module tries to mimic Bash's behavior as closely as
    possible.  (If I missed something, please let me know!)


    AUTHOR:

    Frédéric Brière (fbriere@fbriere.net)

    Licensed under the GNU General Public License, version 2 or later.


    THANKS:

    Thanks to Stanis Trendelenburg for braceexpand.py, which was tremendously
    helpful as a starting point (https://github.com/trendels/braceexpand).

--]]

-- Forward declarations
local expand_contents, split

-- Perform brace expansion on a string, and return a sequence of results.
local function expand(s)
    local retvar = {}

    -- Split the string in three parts: preamble '{' expr '}' postscript

    -- First split: preamble '{' postamble
    local preamble, postamble = split(s, '{')
    if postamble == nil then
        -- No '{', so no expansion necessary; return the string as-is
        return {s}
    end

    -- Second split: expr '}' postscript
    --
    -- This part is trickier, since we must not stop on the first '}' that
    -- matches, but rather the first one encompassing a valid expression.
    -- (Example: "{1},2}" -> "1}", "2")
    --
    -- However, "{}" appears to be a special case, where parsing halts
    -- immediately.  (Example: "{}1,2}" -> "{}1,2}")  This will be treated as
    -- a special case by expand_contents().

    -- This is our starting point:
    local expr, postscript = nil, postamble
    -- Once the expr is valid, its expanded items will go there:
    local contents

    -- Let's start!
    while contents == nil do
        -- Keep looking for the closing brace.  If we already had a partial
        -- expr, we stash it away before split(), and bring it back
        -- afterwards, along with the '}' that was gobbled previously.
        local old_expr = expr
        expr, postscript = split(postscript, '}')
        if old_expr then
            expr = old_expr .. '}' .. expr
        end

        if postscript == nil then
            -- No closing brace found, so we put back the unmatched '{'
            preamble = preamble .. '{'
            -- Bring back the entire original postamble.  (expr == nil) will
            -- be treated as a special case by expand_contents(), and return
            -- a single empty string.
            expr, postscript = nil, postamble
        end

        -- Let's see if we have a valid expression!
        contents = expand_contents(expr)
    end

    for _, item in ipairs(contents) do
        for _, suffix in ipairs(expand(postscript)) do
            retvar[#retvar + 1] = table.concat({ preamble, item, suffix })
        end
    end

    return retvar
end

-- Expand the contents of a brace expression
function expand_contents(s)
    -- Special case where a '{' had no matching '}'
    if s == nil then
        return { "" }
    end
    -- Special case for '{}': Pretend it's a valid expression to halt parsing,
    -- and put back the braces ourselves.
    if s == "" then
        return { "{}" }
    end

    -- Various functions to deal with sequence expressions follow:

    -- Generate a sequence of numbers from..to..step and return the
    -- corresponding { func(i) } sequence.  from/to/step can be strings.
    local function gen_sequence(from, to, step, func)
        -- Comparison won't work correctly with strings
        from, to, step = tonumber(from), tonumber(to), tonumber(step)

        step = math.abs(step or 1)
        if to < from then
            step = -step
        end

        local items = {}
        for i = from, to, step do
            items[#items + 1] = func(i)
        end
        return items
    end

    -- Return the sequence of strings for a numeric sequence expression
    local function gen_sequence_num(from, to, step)
        local format = '%d'

        -- Pad strings in the presence of a leading zero
        local leading_zero_pattern = '^-?0%d'
        if from:match(leading_zero_pattern) or to:match(leading_zero_pattern) then
            format = '%0' .. math.max(#from, #to) .. 'd'
        end

        local func = function(i) return string.format(format, i) end
        return gen_sequence(from, to, step, func)
    end

    -- Return the sequence of strings for a character sequence expression
    local function gen_sequence_char(from, to, step)
        -- FIXME: Should not output unescaped '\'
        return gen_sequence(from:byte(), to:byte(), step, string.char)
    end

    -- Given a sequence of {func,pattern} items, for the first pattern that
    -- matches s, return func() using the capture groups as arguments.
    local function try_sequence_patterns(t)
        for _, entry in ipairs(t) do
            local func, pattern = table.unpack(entry)
            local from, to, step = s:match(pattern)
            if from then
                return func(from, to, step)
            end
        end
    end

    -- Look for any sequence expression first
    local sequence = try_sequence_patterns({
        { gen_sequence_num,  [=[^(-?%d+)%.%.(-?%d+)%.%.(-?%d+)$]=] },
        { gen_sequence_num,  [=[^(-?%d+)%.%.(-?%d+)$]=]            },
        { gen_sequence_char, [=[^(%a)%.%.(%a)%.%.(-?%d+)$]=]       },
        { gen_sequence_char, [=[^(%a)%.%.(%a)$]=]                  },
    })
    if sequence then
        return sequence
    end

    -- We have a regular brace expression, not a sequence

    -- Start by splitting on ','
    local items = {}
    while s ~= nil do
        items[#items + 1], s = split(s, ',')
    end

    -- An expression with a single item is not valid.
    if #items == 1 then
        return nil
    end

    -- Finally expand and return everything
    local expanded_items = {}
    for _, item in ipairs(items) do
        for _, expanded in ipairs(expand(item)) do
            expanded_items[#expanded_items + 1] = expanded
        end
    end

    return expanded_items
end

-- Split a string on the first occurrence of sep, taking into account
-- escape sequences and nested braces.  Returns (left, right) on a match,
-- (s, nil) otherwise.
function split(s, sep)
    local pos = 1
    local depth = 0

    while pos <= s:len() do
        local c = s:sub(pos, pos)
        if c == '\\' then
            -- NOTE: These are currently left in the result string
            pos = pos + 1
        elseif c == sep and depth == 0 then
            return s:sub(1, pos - 1), s:sub(pos + 1)
        elseif c == '{' then
            depth = depth + 1
        elseif c == '}' then
            -- Don't dive into negative depth on a leading '}'
            if depth > 0 then
                depth = depth - 1
            end
        end
        pos = pos + 1
    end

    -- No match found
    return s, nil
end


return { expand = expand }
