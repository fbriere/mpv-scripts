# brace-expand.lua

Perform Bash-style brace expansion on a string, returning a sequence of
all resulting strings.  Braces can be nested, and sequence expressions are
supported.


## USAGE

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


## NOTES

Special characters (`{` `,` `.` `}`) can be quoted by preceding
then with a backslash.  That backslash is currently left in place and
*not* removed from the results.  (This may change in the future.)

Only the characters listed above have any special meaning; in
particular, spaces and quotes are treated like any other character.
(The sequence `${` is not treated differently either.)

Otherwise, this module tries to mimic Bash's behavior as closely as
possible.  (If I missed something, please let me know!)


## AUTHOR

Frédéric Brière (fbriere@fbriere.net)

Licensed under the GNU General Public License, version 2 or later.


## THANKS

Thanks to Stanis Trendelenburg for braceexpand.py, which was tremendously
helpful as a starting point (https://github.com/trendels/braceexpand).

