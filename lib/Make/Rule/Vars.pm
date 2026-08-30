package Make::Rule::Vars;

use strict;
use warnings;
use Carp;
use constant DEBUG => $ENV{MAKE_DEBUG};

our $VERSION = '2.011';
my @KEYS = qw( @ * ^ ? < );
my $i;
my %NEXTKEY = map +( $_ => ++$i ), @KEYS;

# Package to handle automatic variables pertaining to rules e.g. $@ $* $^ $?
# by using tie to this package 'subsvars' can work with array of
# hash references to possible sources of variable definitions.

sub TIEHASH {
  my ($class, $rule, $info, $name) = @_;
  bless [ $rule, $info, $name ], $class;
}

sub FIRSTKEY {
  $KEYS[0];
}

sub NEXTKEY {
  my ( $self, $lastkey ) = @_;
  $KEYS[ $NEXTKEY{$lastkey} ];
}

sub EXISTS {
  my ( $self, $key ) = @_;
  exists $NEXTKEY{$key};
}

sub FETCH {
  my ($self, $v)      = @_;
  my ($rule, $info, $name) = @$self;
  DEBUG and print STDERR "FETCH $v for ", $name, "\n";
  return $name if $v eq '@';
  return $name =~ s/\.[^.]+$//r if $v eq '*';
  return join ' ', @{ $rule->prereqs }         if $v eq '^';
  return join ' ', $info->out_of_date($name, $rule) if $v eq '?';
  return ( @{ $rule->prereqs } )[0] if $v eq '<';
  ();
}

1;
