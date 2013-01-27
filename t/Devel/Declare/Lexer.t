#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
use Devel::Declare::Lexer qw/ :lexer_test /; # creates a lexer_test keyword and places lexed code into runtime $lexed
#use Devel::Declare::Lexer qw/ :lexer_test lexer_test2 /; # creates a lexer_test keyword and places lexed code into runtime $lexed

use Test::More;

my $tests = 0;
my $lexed;

#BEGIN {
#    Devel::Declare::Lexer::lexed(lexer_test2 => sub {
#        my $stream = shift;
#
#        my @ns = ();
#        tie @ns, "Devel::Declare::Lexer::Stream";
#
#        push @ns, new Devel::Declare::Lexer::Token( type => 'word', length => '5', value => 'print' );
#        push @ns, new Devel::Declare::Lexer::Token( type => 'whitespace', length => '1', value => ' ' );
#        push @ns, new Devel::Declare::Lexer::Token( type => 'string', length => '22', value => 'Hello pigs in blankets', strstype => "\"", stretype => "\"" );
#        push @ns, new Devel::Declare::Lexer::Token( type => 'eos', length => '1', value => ';' );
#        push @ns, new Devel::Declare::Lexer::Token( type => 'eol', length => '1', value => "\n" );
#
#        return \@ns;
#    });
#}
#
#lexer_test2 "pigs in blankets";

lexer_test "this is a test";
++$tests && is($lexed, q|lexer_test "this is a test";|, 'Strings');

lexer_test "this", "is", "another", "test";
++$tests && is($lexed, q|lexer_test "this", "is", "another", "test";|, 'List of strings');

lexer_test { "this", "is", "a", "test" };
++$tests && is($lexed, q|lexer_test { "this", "is", "a", "test" };|, 'Hashref list of strings');

lexer_test ( "this", "is", "a", "test" );
++$tests && is($lexed, q|lexer_test ( "this", "is", "a", "test" );|, 'Array of strings');

my $a = 1;
lexer_test ( $a + $a );
++$tests && is($lexed, q|lexer_test ( $a + $a );|, 'Variables and operators');
lexer_test ( $a != $a );
++$tests && is($lexed, q|lexer_test ( $a != $a );|, 'Inequality operator');

my $longer_name = 1234;
lexer_test ( !$longer_name );
++$tests && is($lexed, q|lexer_test ( !$longer_name );|, 'Negative operator and complex variable names');
lexer_test ( \$longer_name );
++$tests && is($lexed, q|lexer_test ( \$longer_name );|, 'Referencing operator');

my $ln_ref = \$longer_name;
lexer_test ( $$ln_ref );
++$tests && is($lexed, q|lexer_test ( $$ln_ref );|, 'Dereferencing operator');

lexer_test q(this is a string);
++$tests && is($lexed, q|lexer_test q(this is a string);|, 'q quoting operator');

lexer_test q(this
is
a
multiline);
++$tests && is($lexed, q|lexer_test q(this
is
a
multiline);|, 'q quoting operator with multiline');

lexer_test ( {
    abc => 2,
    def => 4,
} );
++$tests && is($lexed, q|lexer_test ( {
    abc => 2,
    def => 4,
} );|, 'Hashref multiline');

++$tests && is(__LINE__, 83, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
