-- Test wildcard() (not a real test unit, just a regular script)


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


-- Tests adapted from https://github.com/davidm/lua-glob-pattern/blob/master/test.lua
tests = {
    -- text only
    { "", '^$' },
    { "abc", '^abc$' },
    -- escaping in pattern
    { "ab#/.", '^ab%#%/%.$' },
    -- escaping in glob
    { "\\\\\\ab\\c\\", '^%\\abc%\\$' },

    -- basic * and ?
    { "abc.*", '^abc%.[^/]*$' },
    { "??.txt", '^[^/][^/]%.txt$' },

    -- character sets
    -- normal
    { "a[a][b]z", '^a[a][b]z$' },
    { "a[a-f]z", '^a[a-f]z$' },
    { "a[a-f0-9]z", '^a[a-f0-9]z$' },
    { "a[!a-f]z", '^a[^a-f]z$' },
    { "a[^a-f]z", '^a[^a-f]z$' },
    { "a[\\!\\^\\-z\\]]z", '^a[%!%^%-z%]]z$' },
    { "a[\\a-\\f]z", '^a[a-f]z$' },
    { "a[?*]z", '^a[%?%*]z$' },
}


for _, test in ipairs(tests) do
    s, expected = table.unpack(test)
    got = wildcard(s)
    if got ~= expected then
        print("NOT OK:", s, wildcard(s), expected)
    end
end

