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
  my ($class, $name) = @_;
  # member: HAS_RECIPE: undef, boolean
  # member: RULE_TYPE: undef, :, ::
  # member: RULE | RULES
  # member: Pass, used to determine if 'done' this sweep
  bless {
    NAME => $name, # name of thing
  }, $class;
}

sub has_recipe {
  my ($self) = @_;
  return $self->{HAS_RECIPE} if defined $self->{HAS_RECIPE};
  $self->{HAS_RECIPE} = grep @{ $_->recipe }, @{ Make::maybe_return($self, 'RULE') };
}

sub rules {
  my ($self, $is_phony, $info) = @_;
  confess "is_phony not given" if !defined $is_phony;
  confess "info not given" if !defined $info;
  if ( !$is_phony && !$self->has_recipe ) {
    my $rule = $info->patrule($self->Name, $self->{RULE_TYPE} || ':');
    DEBUG and print STDERR "Implicit rule (", $self->Name, "): @{ $rule ? $rule->prereqs : ['none'] }\n";
    $self->add_rule($rule) if $rule;
  }
  Make::maybe_return($self, 'RULE');
}

sub add_rule {
  my ($self, $rule) = @_;
  my $new_kind = $rule->kind;
  my $kind     = $self->{RULE_TYPE} ||= $new_kind;
  die "Target '$self->{NAME}' had '$kind' but tried to add '$new_kind'"
    if $kind ne $new_kind;
  delete $self->{HAS_RECIPE}; # reset if was no or unknown
  Make::maybe_add($self, 'RULE', $rule);
}

sub Name {
    return shift->{NAME};
}

sub Base {
    my $name = shift->{NAME};
    $name =~ s/\.[^.]+$//;
    return $name;
}

sub done {
  my ($self, $pass) = @_;
  confess "pass not given" if !defined $pass;
  $self->{Pass} ||= 0;
  return 1 if $self->{Pass} == $pass;
  $self->{Pass} = $pass;
  return 0;
}

1;
