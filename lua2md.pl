#!/usr/bin/perl
#
# Little script to extract and tweak the documentation from my Lua scripts

use 5.014;
use strict;
use warnings;


my ($filename) = @ARGV;
$filename =~ s!.*/!!;
say "# $filename";

while (<>) {
	chomp;

	next unless /^--\[\[/ .. /^--\]\]/;
	# Only allow one such section for now
	last if /^--\]\]/;
	# Skip the delimiters themselves
	next if /^--/;

	# Shift everything left by 4 spaces
	s/^ {4}//;

	# Headers
	if (/^([-A-Z ]+):$/) {
		# Header itself
		$_ = "## $1";
	} else {
		# Links to headers
		s/([A-Z]{4,})(?= section)/join("", "[", ucfirst(lc($1)), "](#", lc($1), ")")/ge
			unless /^ {4}/;
	}

	say;
}
