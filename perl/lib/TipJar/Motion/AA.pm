
package TipJar::Motion::AA;
use strict;
use TipJar::Motion::type 'AA';
use parent 'TipJar::Motion::Mote';

=pod

associative array mote.  Any mote can work as an AA, but these
are specialized for the purpose, as they offer a hashref
overload.

=cut

sub RefenceToTiedHash{
    my $moteid = ${ (shift) };
	tie my %glue, __PACKAGE__, $moteid;
	\%glue
};

use overload
            '%{}' => \&RefenceToTiedHash,
            '""' => sub { $_[0]->moteid },
;

sub explode{ %{ $_[0]->lexicon } }

sub Exists {
  my $self = shift;
  my $term = shift;
  exists $self->lexicon->{$term} and return 1;
  my $p = $self->outer;
  $p and $p->Exists($term)
}

use TipJar::Motion::configuration;
sub TIEHASH{
  bless \$_[1], __PACKAGE__
}
sub FETCH{
  my ($obj, $key) = @_;
  aa_get($$obj,$key)
}
sub EXISTS{
  my ($obj, $key) = @_;
  aa_exists($$obj,$key)
}
sub STORE{
  my ($obj, $key, $val) = @_;
  aa_set($$obj,$key, $val)
}
sub DESTROY{ warn "destroying ${$_[0]}"}
our $AUTOLOAD;
sub AUTOLOAD{ Carp::confess "AUTOLOAD $AUTOLOAD" }
1;



