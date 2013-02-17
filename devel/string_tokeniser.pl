#!/home/cpan/perl/bin/perl

use strict;
use warnings;

package Test;
use Test::More;

use Data::Dumper;
use Devel::Declare::Lexer qw( test );
use Devel::Declare::Lexer::Tokens;

our $DEBUG = 0;

BEGIN {
    $Devel::Declare::Lexer::DEBUG = $Test::DEBUG;
    print "=" x 80, "\n";
    sub findvars
    {
        my ($l) = @_;

        my @vars = ();

        my @chars = split //, $l;

        my @procd = ();
        my $tok = '';
        my $pos = -1;
        for my $char (@chars) {
            push @procd, $char;
            $pos++;
print "Got char '$char'\n" if $DEBUG;

            if($char =~ /\s/ && $tok) {
                print "    Captured token '$tok'\n";
                push @vars, $tok;
                $tok = '';
                next;
            }
            #if($tok && ($char !~ /[\$\@\%]/ || length $tok == 1)) {
            if($tok && ($char !~ /[\$\@]/ || length $tok == 1)) {
print "Got tok '$tok' so far\n" if $DEBUG;
                my $eot = 0;
                if($char =~ /[':]/) {
                    # do some forwardlooking
                    my $c = $chars[$pos + 1];
                    #if($c && $c =~ /[\s\$\%\@]/) {
                    if($c && $c =~ /[\s\$\@]/) { # hashes are only interpolated with $name{key} syntax
                        $eot = 1;
                    }
                }
                if(!$eot) {
                    $tok .= $char;
                    next;
                }
            }
            #if($char =~ /[\$\@\%]/ || $tok) {
            if($char =~ /[\$\@]/ || $tok) {
                #if($char =~ /[\$\@\%]/ && $tok && $tok !~ /^[\$\@\%]+$/) {
                if( $tok && (($char =~ /[\$\@]/ && $tok !~ /^[\$\@]+$/))) {
                    print "    Captured token '$tok'\n";
                    push @vars, $tok;
                    $tok = '';
                }
                my $capture = 0;
print "Got tok '$tok' in varcap\n" if $DEBUG;
                if(!$tok) {
                    # do some backtracking
                    my $ec = 0;
                    for(my $i = $pos - 1; $i >= 0; $i--) {
                        my $c = $procd[$i];
                        last if $c !~ /\\/;
                        $ec++;
print "Got char '$c' at pos $i, ec $ec\n" if $DEBUG;
                    }
                    $capture = $ec % 2 == 0 ? 1 : 0;
                    #if($ec % 2 == 0) {
                    #    print "probably a token\n";
                    #} else {
                    #    print "probably not a token\n";
                    #}
                }
print "Got capture $capture\n" if $DEBUG;
                $tok = $char if $capture;
                next;
            }
        }

        return @vars;
    }

    Devel::Declare::Lexer::lexed(test => sub {
        my $stream_r = shift;

        my @stream = @$stream_r;

        my $string = $stream[4]->{value};
        print "String is '$string'\n";

        my @vars = findvars($string);
print Dumper \@vars if $DEBUG;
        if(scalar @vars) {
            push @stream, new Devel::Declare::Lexer::Token::Raw(
                value => '; @testvars = (\'' . (join '\', \'', @vars) . '\');'
            );
        } else {
            push @stream, new Devel::Declare::Lexer::Token::Raw(
                value => '; @testvars = ();'
            );
        }

        return \@stream;
    });
}

print "=" x 80, "\n";

my $a = "a";
our $shared = "shared";
my $ar = \$a;
my @b = ("b");
my %c = ("c" => "c");

my $tests = 0;
my @testvars;

test print "This is $a string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is @b string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '@b', 'Captured @b');

test print "This is $b[0] string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$b[0]', 'Captured @b[0]');

test print "This is $c{c} string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$c{c}', 'Captured $c{c}');

test print "This is \$a string\n";
++$tests && is(scalar @testvars, 0, 'Captured 0 variable');

test print "This is \\$a string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is \\\$a string\n";
++$tests && is(scalar @testvars, 0, 'Captured 0 variable');

test print "This is \\\\$a string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is \\\\$a string and a \\\\@b string\n";
++$tests && is(scalar @testvars, 2, 'Captured 2 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');
++$tests && is($testvars[1], '@b', 'Captured @b');

test print "This is \\\\$a string and a \\\@b string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is \$a string and a \\@b string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '@b', 'Captured @b');

test print "I want to interpolate '$a' but not '\@b'\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "I want to interpolate '$$ar' but not '\@b'\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$$ar', 'Captured $$ar');

test print "I want to interpolate '$$ar$a' but not '\@b'\n";
++$tests && is(scalar @testvars, 2, 'Captured 2 variable');
++$tests && is($testvars[0], '$$ar', 'Captured $$ar');
++$tests && is($testvars[1], '$a', 'Captured $a');

test print "I want to interpolate '$$ar@b' but not '\@b'\n";
++$tests && is(scalar @testvars, 2, 'Captured 2 variable');
++$tests && is($testvars[0], '$$ar', 'Captured $$ar');
++$tests && is($testvars[1], '@b', 'Captured @b');

test print "I want to interpolate '$Test::shared' but not '\@b'\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$Test::shared', 'Captured $Test::shared');

test print "I want to interpolate '$Test::shared$$ar@b' but not '\$Test::shared\$\$ar\@b'\n";
++$tests && is(scalar @testvars, 3, 'Captured 3 variable');
++$tests && is($testvars[0], '$Test::shared', 'Captured $Test::shared');
++$tests && is($testvars[1], '$$ar', 'Captured $$ar');
++$tests && is($testvars[2], '@b', 'Captured @b');

test print "This is a %s format%s", "sprintf", "\n";
++$tests && is(scalar @testvars, 0, 'Captured 0 variable');

test print "$$: Perl special variable\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$$', 'Captured $$');

done_testing($tests);

exit;
