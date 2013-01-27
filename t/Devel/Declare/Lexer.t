#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
use Devel::Declare::Lexer;

use Test::More;

my $tests = 0;
my $parsed;

lexer_test "this is a test";
++$tests && is($parsed, q|lexer_test "this is a test";|, 'Strings');

lexer_test "this", "is", "another", "test";
++$tests && is($parsed, q|lexer_test "this", "is", "another", "test";|, 'List of strings');

lexer_test { "this", "is", "a", "test" };
++$tests && is($parsed, q|lexer_test { "this", "is", "a", "test" };|, 'Hashref list of strings');

lexer_test ( "this", "is", "a", "test" );
++$tests && is($parsed, q|lexer_test ( "this", "is", "a", "test" );|, 'Array of strings');

my $a = 1;
lexer_test ( $a + $a );
++$tests && is($parsed, q|lexer_test ( $a + $a );|, 'Variables and operators');
lexer_test ( $a != $a );
++$tests && is($parsed, q|lexer_test ( $a != $a );|, 'Inequality operator');

my $longer_name = 1234;
lexer_test ( !$longer_name );
++$tests && is($parsed, q|lexer_test ( !$longer_name );|, 'Negative operator and complex variable names');
lexer_test ( \$longer_name );
++$tests && is($parsed, q|lexer_test ( \$longer_name );|, 'Referencing operator');

my $ln_ref = \$longer_name;
lexer_test ( $$ln_ref );
++$tests && is($parsed, q|lexer_test ( $$ln_ref );|, 'Dereferencing operator');

lexer_test q(this is a string);
++$tests && is($parsed, q|lexer_test q(this is a string);|, 'q quoting operator');

lexer_test q(this
is
a
multiline);
++$tests && is($parsed, q|lexer_test q(this
is
a
multiline);|, 'q quoting operator with multiline');

lexer_test ( {
    abc => 2,
    def => 4,
} );
++$tests && is($parsed, q|lexer_test ( {
    abc => 2,
    def => 4,
} );|, 'Hashref multiline');

++$tests && is(__LINE__, 63, 'Line numbering');

done_testing $tests;

#100 / 0;
