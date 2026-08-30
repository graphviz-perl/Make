package Make::Target;

use strict;
use warnings;
use constant DEBUG => $ENV{MAKE_DEBUG};
use Carp qw(confess);

our $VERSION = '2.011';

# Intermediate 'target' package
# There is an instance of this for each 'target' that apears on
# the left hand side of a rule i.e. for each thing that can be made.
sub new {
  my ($class) = @_;
  # member: HAS_RECIPE: undef, boolean
  # member: RULE_TYPE: undef, :, ::
  # member: RULE | RULES
  # member: Pass, used to determine if 'done' this sweep
  bless {}, $class;
}

sub rule_type { $_[0]{RULE_TYPE} || ':' }

sub has_recipe {
  my ($self) = @_;
  $self->{HAS_RECIPE} //= grep @{ $_->recipe }, @{ Make::maybe_return($self, 'RULE') };
}

sub rules {
  Make::maybe_return($_[0], 'RULE');
}

sub add_rule {
  my ($self, $rule, $name) = @_;
  my $new_kind = $rule->kind;
  my $kind     = $self->{RULE_TYPE} ||= $new_kind;
  confess "Target '$name' had '$kind' but tried to add '$new_kind'"
    if $kind ne $new_kind;
  delete $self->{HAS_RECIPE}; # reset if was no or unknown
  Make::maybe_add($self, 'RULE', $rule);
}

sub done {
  my ($self, $pass) = @_;
  confess "pass not given" if !defined $pass;
  $self->{Pass} ||= 0;
  return 1 if $self->{Pass} == $pass;
  $self->{Pass} = $pass;
  0;
}

1;
