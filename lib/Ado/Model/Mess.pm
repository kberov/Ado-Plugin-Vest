package Ado::Model::Mess;    #A table/row class
use 5.010001;
use strict;
use warnings;
use utf8;
use parent qw(Ado::Model);

sub is_base_class { return 0 }
my $TABLE_NAME = 'mess';

sub TABLE       { return $TABLE_NAME }
sub PRIMARY_KEY { return 'id' }
my $COLUMNS = ['id', 'from_uid', 'to_uid', 'subject', 'tstamp', 'message',
    'message_assets'];

sub COLUMNS { return $COLUMNS }
my $ALIASES = {};

sub ALIASES { return $ALIASES }
my $CHECKS = {
    'to_uid'   => {'allow' => qr/(?^x:^-?\d{1,}$)/},
    'from_uid' => {'allow' => qr/(?^x:^-?\d{1,}$)/},
    'tstamp'   => {
        'required' => 1,
        'defined'  => 1,
        'allow'    => qr/(?^x:^-?\d{1,}$)/
    },
    'subject'        => {'allow' => qr/(?^x:^.{1,255}$)/},
    'id'             => {'allow' => qr/(?^x:^-?\d{1,}$)/},
    'message_assets' => {
        'allow'   => qr/(?^x:^.{1,}$)/,
        'default' => 'NULL'
    },
    'message' => {'allow' => qr/(?^x:^.{1,}$)/}
};

sub CHECKS { return $CHECKS }

__PACKAGE__->QUOTE_IDENTIFIERS(0);

#__PACKAGE__->BUILD;#build accessors during load

1;

=pod

=encoding utf8

=head1 NAME

A class for TABLE mess in schema main

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COLUMNS

Each column from table C<mess> has an accessor method in this class.

=head2 id

=head2 from_uid

=head2 to_uid

=head2 subject

=head2 tstamp

=head2 message

=head2 message_assets

=head1 ALIASES

=head1 GENERATOR

L<DBIx::Simple::Class::Schema>

=head1 SEE ALSO

L<Ado::Model>, L<DBIx::Simple::Class>, L<DBIx::Simple::Class::Schema>

=cut

