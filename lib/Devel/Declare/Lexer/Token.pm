package Devel::Declare::Lexer::Token;

use v5.14.2;

sub new
{
    my ($caller, %arg) = @_;

    my $self = bless { %arg }, $caller;
    return $self;
}

sub dump
{
    my ($self) = @_;

    print $self->get;
}

sub get
{
    my ($self) = @_;

    if(defined $self->{strstype}) {
        return $self->{strstype} . $self->{value} . $self->{stretype};
    }
    return $self->{value};
}

1;
