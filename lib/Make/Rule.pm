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

# The key make test - is target out-of-date as far as this rule is concerned
# In scalar context - boolean value of 'do we need to apply the rule'
# In list context the things we are out-of-date with e.g. magic $? variable
sub out_of_date {
  my ($self, $name, $info) = @_;
  confess "info not given" if !defined $info;
  my @dep   = ();
  my $tdate = $info->date($name);
  my $count = 0;
  foreach my $dep ( @{ $self->prereqs } ) {
    my $date = $info->date($dep);
    $count++;
    if (!defined($date) || !defined($tdate) || $date > $tdate) {
      DEBUG and print STDERR "$name outdated by $dep\n";
      return 1 unless wantarray;
      push( @dep, $dep );
    }
  }
  return @dep if wantarray;
  # Note special case of no prerequisites means it is always out-of-date!
  !$count;
}

sub auto_vars {
  my ($self, $target, $name, $info) = @_;
  confess "info not given" if !defined $info;
  tie my %var, 'Make::Rule::Vars', $self, $info, $name, $target;
  return \%var;
}

# - May need vpath processing
sub exp_recipe {
  my ($self, $target, $name, $info) = @_;
  confess "info not given" if !defined $info;
  my @subs_args = ($info->function_packages, [ $self->auto_vars($target, $name, $info), $info->vars, \%ENV ]);
  my @cmd = map Make::subsvars( $_, @subs_args ), @{ $self->recipe };
  wantarray ? @cmd : \@cmd;
}

sub new {
  my ( $class, $kind, $prereqs, $recipe, $recipe_raw ) = @_;
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
  my ($self, $target, $name, $info) = @_;
  confess "info not given" if !defined $info;
  return if !$self->out_of_date($name, $info);
  [ $name, $self->exp_recipe($target, $name, $info) ];
}

#
# Print rule out in makefile syntax
# - currently has variables expanded as debugging aid.
# - will eventually become make -p
# - may be useful for writing makefiles from MakeMaker too...
#
sub Print {
  my ($self, $target, $name, $info) = @_;
  confess "info not given" if !defined $info;
  print "$name $self->{KIND} ";
  print " \\\n   $_" for $self->prereqs;
  print "\n";
  my @cmd = $self->exp_recipe($target, $name, $info);
  if (@cmd) {
    print "\t$_\n" for @cmd;
  } else {
    print STDERR "No recipe for $name\n" unless $self->target->phony;
  }
  print "\n";
  ();
}

=head1 NAME

Make::Rule - a rule with prerequisites and recipe

=head1 SYNOPSIS

    my $rule = Make::Rule->new( $kind, \@prereqs, \@recipe, \@recipe_raw );
    my @name_commands = $rule->Make($target);
    my @deps = @{ $rule->prereqs };
    my @cmds = @{ $rule->recipe };
    my @expanded_cmds = @{ $rule->exp_recipe($target, $name, $make) }; # vars expanded
    my @raw_cmds = @{ $rule->recipe_raw }; # with any \ still on line-ends
    my @ood = $rule->out_of_date($name, $make);
    my $vars = $rule->auto_vars($target, $name, $make); # tied hash-ref

=head1 DESCRIPTION

Represents a rule. An instance exists for each ':' or '::' rule in
the makefile. The recipe and prerequisites are kept here.

=cut

1;
