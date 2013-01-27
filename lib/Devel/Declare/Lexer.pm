package Devel::Declare::Lexer;

use strict;
use Devel::Declare;
use Devel::Declare::Lexer::Stream;
use Devel::Declare::Lexer::Token;

use v5.14.2;

sub new
{
    my ($caller, %arg) = @_;

    my $self = bless { %arg }, $caller;
    return $self;
}

sub import
{
    my ($class) = @_;
    my $caller = caller;

    Devel::Declare->setup_for(
        $caller,
        {
            "lexer_test" => { const => \&lexer },
        }
    );

    # Setup a sub in the callers package which returns 1
    no strict 'refs';
    *{$caller.'::lexer_test'} = sub () { 1; };
}

sub token
{
    my ($type, $length, $value, %arg) = @_;
    return new Devel::Declare::Lexer::Token(
        type => $type,
        length => $length,
        value => $value,
        %arg
    );
}

sub lexer
{
    my ($symbol, $offset) = @_;

    print "=" x 80, "\n";

    my $linestr = Devel::Declare::get_linestr;
    my $original_linestr = $linestr;
    say "Got linestr '$linestr'";
    print "            '";
    my $c = length $linestr;
    my $c1 = 0;
    while($c) { print $c1; $c1++; $c1 = 0 if $c1 > 9; $c--; }
    print "\n";

    my @tokens = ();
    tie @tokens, "Devel::Declare::Lexer::Stream";
    my ($len, $tok);
    my $eoleos = 0;
    my %lineoffsets;
    my $line = 1;

    # Skip the declarator
    $offset += Devel::Declare::toke_move_past_token($offset);
    push @tokens, token('declarator', length $symbol, $symbol);

    my $skipspace = sub {
        #my $no_eol = shift;
        $len = Devel::Declare::toke_skipspace($offset);
        if($len > 0) {
            $tok = substr($linestr, $offset, $len);
            say "Skipped whitespace '$tok', length [$len]";
            push @tokens, token('whitespace', $len, $tok);
            $offset += $len;
        } elsif ($len < 0) {
            say "Got end of line X";
            #push @tokens, token('whitespace', $len, "\n") if (defined $no_eol && !$no_eol);
            #$offset += $len;
        } elsif ($len == 0) {
            say "No whitespace";
        }
        return $len;
    };

    # get the message
    say "Length[", length $linestr, "]";
#my $abort = 0;
    while($offset < length $linestr) {
#$abort++; last if $abort > 25;
        say "Offset[$offset], Remaining[", substr($linestr, $offset), "]";

        if(substr($linestr, $offset, 1) eq ';') {
            say "Got end of statement";
            push @tokens, token('eos', 1, ';');
            $offset += 1;
            $eoleos = 1;
            next;
        }

        if(substr($linestr, $offset, 2) eq "\n") {
            say "Got end of line L (current line $line)";
            push @tokens, token('eol', 1, "\n");
            $offset += 1;

            last if $eoleos;
            $eoleos = 0;

            # we're actually consuming a new line now

            #&$skipspace;
            $len = Devel::Declare::toke_skipspace($offset);
            if($len != 0) {
                #$offset += $len - 6; #???#
                say "Got len in EOL L = $len";
            }

            Devel::Declare::clear_lex_stuff;

            $linestr = Devel::Declare::get_linestr;
            $original_linestr = $linestr;

            if($line == 1) {
                $lineoffsets{1} = (length $symbol) + 1;
            };
            $line++;
            $lineoffsets{$line} = $offset;

            say "Got linestr [$linestr]";
            next;
        }

        last if &$skipspace < 0;

        if(substr($linestr, $offset, 1) =~ /(\{|\[|\()/) {
            my $b = substr($linestr, $offset, 1);
            push @tokens, token('bracket', 1, $b);
            say "Got bracket '$b'";
            $offset += 1;
            next;
        }
        if(substr($linestr, $offset, 1) =~ /(\}|\]|\))/) {
            my $b = substr($linestr, $offset, 1);
            push @tokens, token('bracket', 1, $b);
            say "Got bracket '$b'";
            $offset += 1;
            next;
        }

        if(substr($linestr, $offset, 1) =~ /\\/) {
            $tok = substr($linestr, $offset, 1);
            say "Got reference operator '$tok'";
            push @tokens, token('operator', $len, $tok);
            $offset += 1;
            next;
        }

        if(substr($linestr, $offset, 1) =~ /(\$|\%|\@|\*)/) {
            # get the sign
            #$len = Devel::Declare::toke_scan_word($offset, 1);
            $tok = substr($linestr, $offset, 1);
            say "Got variable '$tok'";
            push @tokens, token('variable', 1, $tok);
            $offset += 1;
            next;
        }

        if(substr($linestr, $offset, 1) =~ /[!\+\-\*\/\.><=]/) {
            $tok = substr($linestr, $offset, 1);
            say "Got operator '$tok'";
            push @tokens, token('operator', $len, $tok);
            $offset += 1;
            next;
        }

        if(substr($linestr, $offset, 1) eq ',') {
            say "Got a comma";
            push @tokens, token('comma', 1, ',');
            $offset += 1;
            next;
        }

        if(substr($linestr, $offset, 1) =~ /^(q|\"|\')/) {
            # FIXME need to determine string type properly
            my $strstype = substr($linestr, $offset, 1);
            my $stretype = $strstype;
            if($strstype =~ /q/) {
                $offset += 1;
                $strstype .= substr($linestr, $offset, 1);
                $stretype = substr($strstype, 1);
                $stretype =~ tr/\(/)/;
                $len = Devel::Declare::toke_scan_str($offset);
            } else {
                $len = Devel::Declare::toke_scan_str($offset);
            }
            say "Got string type $strstype, end type $stretype";
            $tok = Devel::Declare::get_lex_stuff;
            Devel::Declare::clear_lex_stuff;
            say "Got str '$tok'";
            push @tokens, token('string', $len, $tok, strstype => $strstype, stretype => $stretype );
            # get a new linestr - we might have captured multiple lines
            $linestr = Devel::Declare::get_linestr;
            $offset += $len;

            # If we do have multiple lines, we'll fix line numbering at the end

            next;
        }

        $len = Devel::Declare::toke_scan_word($offset, 1);
        if($len) {
            $tok = substr($linestr, $offset, $len);
            say "Got token '$tok'";
            push @tokens, token('word', $len, $tok);
            $offset += $len;
            next;
        }

    }

    my $stmt = "";
    for my $token (@tokens) {
        $stmt .= $token->get;
    }

    print "=" x 80, "\n";

    $stmt =~ s/\\/\\\\/g;
    $stmt =~ s/\"/\\"/g;
    $stmt =~ s/\$/\\\$/g;
    $stmt =~ s/\n/\\n/g;
    chomp $stmt;
    $stmt = substr($stmt, 0, (length $stmt) - 2); # strip the final \\n
    say "Statement: [$stmt]";

    my @lcnt = split /\\n/, $stmt;
    my $lc = scalar @lcnt;
    my $lineadjust = $lc - $line;
    say "Linecount[$lc] lines[$line] - missing $lineadjust lines";

    # we've got a new linestr, we need to re-fix all our offsets
    say "\n\nStarted with linestr [$linestr]";
    use Data::Dumper;
    print Dumper \%lineoffsets;

    for my $l (sort keys %lineoffsets) {
        my $sol = $lineoffsets{$l};
        last if !defined $lineoffsets{$l+1}; # don't mess with the current line, yet!
        my $eol = $lineoffsets{$l + 1} - 1;
        my $diff = $eol - $sol;
        my $substr = substr($linestr, $sol, $diff);
say "\nLine $l, sol[$sol], eol[$eol], diff[$diff], linestr[$linestr], substr[$substr]";
        substr($linestr, $sol, $diff) = " " x $diff;
    }

    # now clear up the last line
    say "Still got linestr[$linestr]";
    my $sol = $line == 1 ? (length $symbol) + 1 : $lineoffsets{$line};
    my $eol = (length $linestr) - 1;
    my $diff = $eol - $sol;
    my $substr = substr($linestr, $sol, $diff);
    say "Got substr[$substr] sol[$sol] eol[$eol] diff[$diff]";

    my $newline = "\n" x $lineadjust;
    if($symbol =~ /lexer_test/) {
        #Devel::Declare::set_linestr("$symbol and \$parsed = \"$stmt\";");
        #return;
        $newline .= "and \$parsed = \"$stmt\";";
    } else {
        #Devel::Declare::set_linestr("$symbol and print \"Extracted statement [$stmt]\n\";");
        $newline .= "and print \"Extracted statement [$stmt]\n\";";
    }

    #substr($linestr, $sol, $diff) = $newline; # put the rest of the statement in
    substr($linestr, $sol) = $newline; # put the rest of the statement in

    say "Got new linestr[$linestr] from original_linestr[$original_linestr]";

    Devel::Declare::set_linestr($linestr);
}

1;
