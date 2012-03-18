package Csistck::Test::NOOP;

use 5.010;
use strict;
use warnings;

use base 'Csistck::Test';
use Csistck::Oper;
our @EXPORT_OK = qw/noop/;

sub noop { Csistck::Test::NOOP->new($_); };

sub new {
    my ($class, $args) = @_;
    my $self = $class->SUPER::new();
    my $result = undef;

    # Set result
    if (ref $args eq "HASH") {
        if (defined $args->{result}) {
            $result = $args->{result};
        }
    } 
    else {
        $result = $args;
    }

    $self->{CHECK} = sub { noop_check($result); };
    $self->{REPAIR} = sub { noop_check($result); };
    $self->{DESC} = "NOOP test";

    bless($self, $class);
    return $self;
}

sub noop_check {
    my $result = shift;

    die("Set to failure") unless ($result);
}

1;
__END__

=head1 NAME

Csistck::Test::NOOP - Csistck no operation check

=head1 DESCRIPTION

=head1 METHODS

=head2 noop($boolean)

No operation, or placeholder test. Arguments passed in are returned as a 
boolean result.

=head1 AUTHOR

Anthony Johnson, E<lt>anthony@ohess.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Anthony Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,

