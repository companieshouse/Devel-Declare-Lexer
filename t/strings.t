#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ test /;

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;

BEGIN {
    Devel::Declare::Lexer::lexed(test => sub {
        my ($stream_r) = @_;
        return $stream_r;
    });
}

my $s;

test $s = 'Single quoted string';
++$tests && is($s, 'Single quoted string', 'Single quotes');

test $s = "Double quoted string";
++$tests && is($s, 'Double quoted string', 'Double quotes');

test $s = "Some string interpolation using '$s'";
++$tests && is($s, "Some string interpolation using 'Double quoted string'", 'String interpolation');

test $s = q(the q operator);
++$tests && is($s, 'the q operator', 'q operator');

test $s = qq(the qq operator);
++$tests && is($s, 'the qq operator', 'qq operator');

test $s = qq(Some string interpolation with '$s');
++$tests && is($s, "Some string interpolation with 'the qq operator'", 'String interpolation with qq operator');

test $s = <<EOF
This is a heredoc
EOF
;
++$tests && is($s, 'This is a heredoc', 'Heredocs');

++$tests && is(__LINE__, 48, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
