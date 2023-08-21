#!/usr/bin/env perl
use utf8;
use 5.30.0;
use strict;
use warnings;
use Encode;
# list all .md files in the `main` branch of this .git repo, with utf8
my @files = `git ls-tree -r main --name-only --full-tree | grep .md | grep '"'`;

# now, turn "\345\272\217\347\253\240" (octal) to "中文"
s/\\(\d{3})/chr(oct($1))/ge for @files;
Encode::_utf8_on($_) for @files;

# In Unicode, "三" (19977) sorts before "二" (20108), but we need "二" to be first
# So, we replace them with numbers.
s/三/3/g for @files; s/二/2/g for @files; s/一/1/g for @files;
@files = sort { $a cmp $b } @files;
# now replace them back
s/3/三/g for @files; s/2/二/g for @files; s/1/一/g for @files;
chomp @files; s/"//g for @files;
binmode STDOUT, ":utf8";

my $output;
for (@files) {
    # now, for each file, we read its content from the main branch.
    $output .= `git show "main:$_"`;
    $output .= "\n\n";
}

Encode::_utf8_on($output);
$output =~ s/^\|.*\n//mg;
$output =~ s/^(作者：|譯者：|原文：).*\n//mg;

# now, go over each footnote.
my $cnt = 0;
my @footnotes;
$output =~ s/---\n+(?=\[\^\d+\]:)//;
$output =~ s/^\[\^\d+\](:.*$(?:\n  .*)*)/do { push @footnotes, "[^" . ++$cnt . "]$1"; '' }/gme;
$cnt = 0;
$output =~ s/\[\^\d+\]/"[^" . ++$cnt . "]"/gme;
$output .= join "\n", @footnotes;
$output =~ s/\n\n\n+---//g;
$output =~ s/\n\n\n*/\n\n/g;

print "[TOC]\n\n$output\n";
