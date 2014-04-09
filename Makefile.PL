#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2013 Ian Kent                                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;
use ExtUtils::MakeMaker;

BEGIN
{
    eval { require Config_m; }; # ExtUtils::FakeConfig (+ ActivePerl)
    eval { require Config;   } # Everyone else
    if ($@);
}

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    'NAME'          => 'Devel::Declare::Lexer',
    'VERSION_FROM'  => 'lib/Devel/Declare/Lexer.pm',
    'ABSTRACT_FROM' => 'lib/Devel/Declare/Lexer.pm',
    'LICENSE'       => 'perl',
    'AUTHOR'        => 'Ian Kent <iankent@cpan.org>',
    'PREREQ_PM'     => {
                           'Devel::Declare' => 0.006011
                       },
    'dist'          => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
       ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
               ('CAPI'         => 'TRUE') : ()),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Declare-Lexer',
            repository => {
                type => 'git',
                web  => 'https://github.com/neilbowers/Devel-Declare-Lexer',
                url  => 'git://github.com/neilbowers/Devel-Declare-Lexer.git',
            },
        },
    })),

);

__END__
