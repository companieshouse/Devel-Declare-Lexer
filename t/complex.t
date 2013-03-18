#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;
#use Devel::Declare::Lexer qw/ :lexer_test /; # creates a lexer_test keyword and places lexed code into runtime $lexed
use Devel::Declare::Lexer qw/ :lexer_test lexer_test2 /; # creates a lexer_test keyword and places lexed code into runtime $lexed

use Test::More;

#BEGIN { $Devel::Declare::Lexer::DEBUG = 1; }

my $tests = 0;
my $lexed;

BEGIN {
    Devel::Declare::Lexer::lexed(lexer_test2 => sub {
        my ($stream_r) = @_;
        my @stream = @$stream_r;

        my $string = $stream[2]; # keyword [whitespace] "string"
        $string->{value} =~ tr/pi/do/;

        my @ns = ();
        tie @ns, "Devel::Declare::Lexer::Stream";

        push @ns, (
            new Devel::Declare::Lexer::Token::Declarator( value => 'lexer_test2' ),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            new Devel::Declare::Lexer::Token( value => 'my' ),
            new Devel::Declare::Lexer::Token::Variable( value => '$lexer_test2'),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            new Devel::Declare::Lexer::Token::Operator( value => '=' ),
            new Devel::Declare::Lexer::Token::Whitespace( value => ' ' ),
            $string,
            new Devel::Declare::Lexer::Token::EndOfStatement,
            new Devel::Declare::Lexer::Token::Newline,
        );

        return \@ns;
    });
}

my $eventName = 'test';
no strict 'refs';
*{'dummy_package::get_name'} = sub { return 'abc'; };
my $eh = bless {}, 'dummy_package';
lexer_test "skipping event ".$eh->get_name if $eventName ne $eh->get_name;
++$tests && is($lexed, q/lexer_test "skipping event ".$eh->get_name if $eventName ne $eh->get_name;/, 'Complex');

++$tests && is(__LINE__, 52, 'Line numbering (CHECK WHICH LINE THIS IS ON)');

done_testing $tests;

#100 / 0;
