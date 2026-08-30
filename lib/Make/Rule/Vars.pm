package Make::Rule::Vars;

use strict;
use warnings;
use Carp;
use constant DEBUG => $ENV{MAKE_DEBUG};

our $VERSION = '2.011';
my @KEYS = qw(@ * ^ ? <);
my %NEXTKEY = map +($KEYS[$_] => $_+1), 0..$#KEYS;

# Package to handle automatic variables pertaining to rules e.g. $@ $* $^ $?
# by using tie to this package 'subsvars' can work with array of
# hash references to possible sources of variable definitions.

sub TIEHASH {
  my ($class, $rule, $info, $name) = @_;
  bless [ $rule, $info, $name ], $class;
}

sub FIRSTKEY { $KEYS[0] }

sub NEXTKEY { $KEYS[ $NEXTKEY{$_[1]} ] }

sub EXISTS { exists $NEXTKEY{$_[1]} }

my %DISPATCH = (
  '@' => sub { $_[0][2] },
  '*' => sub { $_[0][2] =~ s/\.[^.]+$//r },
  '^' => sub { join ' ', @{ $_[0][0]->prereqs } },
  '?' => sub { join ' ', @{ $_[0][1]->out_of_date($_[0][2], $_[0][0]) } },
  '<' => sub { $_[0][0]->prereqs->[0] },
);
sub FETCH {
  my ($self, $v)      = @_;
  DEBUG and print STDERR "FETCH $v for $self->[2]\n";
  return unless my $sub = $DISPATCH{$v};
  $sub->($self);
}

1;
