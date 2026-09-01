package Make::Rule;

use strict;
use warnings;
use Carp qw(confess);
use Make::Rule::Vars;
use constant DEBUG => $ENV{MAKE_DEBUG};

our $VERSION = '2.011';

sub prereqs {
  Make::maybe_return($_[0], 'PREREQ');
}

sub recipe {
  Make::maybe_return($_[0], 'RECIPE');
}

sub recipe_raw {
  my @stored = @{ Make::maybe_return($_[0], 'RAW_RECIPE') };
  @stored ? \@stored : $_[0]->recipe;
}

sub auto_vars {
  my ($self, $name, $info) = @_;
  confess "info not given" if !defined $info;
  tie my %var, 'Make::Rule::Vars', $self, $info, $name;
  \%var;
}

sub exp_recipe {
  my ($self, $name, $info) = @_;
  confess "info not given" if !defined $info;
  my @cmd = map $self->expand($_, $name, $info), @{ $self->recipe };
  wantarray ? @cmd : \@cmd;
}

sub expand {
  my ($self, $text, $name, $info) = @_;
  Make::subsvars(
    $text, $info->function_packages,
    [ $self->auto_vars($name, $info), $info->vars, \%ENV ],
    $info->fsmap,
  );
}

sub new {
  my ($class, $kind, $prereqs, $recipe, $recipe_raw) = @_;
  confess "prereqs $prereqs are not an array reference"
    if 'ARRAY' ne ref $prereqs;
  confess "recipe $recipe not an array reference"
    if 'ARRAY' ne ref $recipe;
  confess "recipe_raw $recipe_raw not an array reference"
    if 'ARRAY' ne ref $recipe_raw;
  confess "recipe (@{[0+@$recipe]}) and recipe_raw (@{[0+@$recipe]}) have different number of elements"
    if @$recipe != @$recipe_raw;
  $recipe_raw = [] if !grep $recipe->[$_] ne $recipe_raw->[$_], 0..$#$recipe;
  bless {
    KIND => $kind, # : or ::
    Make::maybe_store(PREREQ => $prereqs), # right hand args
    Make::maybe_store(RECIPE => $recipe),
    Make::maybe_store(RAW_RECIPE => $recipe_raw),
  }, $class;
}

sub kind {
  $_[0]{KIND};
}

sub Make {
  my ($self, $name, $info) = @_;
  confess "info not given" if !defined $info;
  return if !$info->out_of_date($name, $self);
  [ $name, $self->exp_recipe($name, $info) ];
}

#
# Print rule out in makefile syntax
# - currently has variables expanded as debugging aid.
# - will eventually become make -p
# - may be useful for writing makefiles from MakeMaker too...
#
sub Print {
  my ($self, $name, $info) = @_;
  confess "info not given" if !defined $info;
  my @result = join(' ', $name, $self->{KIND}, @{ $self->prereqs }) . "\n";
  push @result, map "\t$_\n", @{ $self->exp_recipe($name, $info) };
  @result;
}

=head1 NAME

Make::Rule - a rule with prerequisites and recipe

=head1 SYNOPSIS

    my $rule = Make::Rule->new($kind, \@prereqs, \@recipe, \@recipe_raw);
    my @name_commands = $rule->Make($target, $make);
    my @deps = @{ $rule->prereqs };
    my @cmds = @{ $rule->recipe };
    my @expanded_cmds = $rule->exp_recipe($name, $make); # vars expanded
    my @expanded_cmds = $rule->expand($text, $name, $make); # vars expanded
    my @raw_cmds = @{ $rule->recipe_raw }; # with any \ still on line-ends
    my $vars = $rule->auto_vars($name, $make); # tied hash-ref

=head1 DESCRIPTION

Represents a rule. An instance exists for each ':' or '::' rule in
the makefile. The recipe and prerequisites are kept here.

=cut

1;
