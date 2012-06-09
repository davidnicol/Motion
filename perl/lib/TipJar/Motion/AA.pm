

package TipJar::Motion::store;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'STORE';
use TipJar::Motion::string;
use TipJar::Motion::anything;
use TipJar::Motion::null;
sub argtypelistref{ [ANYTHING, STRING, ANYTHING] };
sub process{
  my ($op, $P, $mote, $name, $val) = @_;
  TipJar::Motion::AA::STORE($mote, $name->string, $val);
  retnull
}

package TipJar::Motion::fetch;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'FETCH';
use TipJar::Motion::anything;
use TipJar::Motion::string;
sub argtypelistref{ [ANYTHING, STRING] };
sub process{
  my ($op, $P, $mote, $name) = @_;
  TipJar::Motion::AA::FETCH($mote, $name->string)
}

package TipJar::Motion::setmote;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'STORESCALAR';
use TipJar::Motion::string;
use TipJar::Motion::anything;
use TipJar::Motion::null;
sub argtypelistref{ [ANYTHING, ANYTHING] };
sub process{
  my ($op, $P, $mote, $val) = @_;
  warn "SETMOTE: storing [$val]";
  $mote->mscalar($val);
  retnull
}

package TipJar::Motion::fetchmote;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'FETCHSCALAR';
use TipJar::Motion::anything;
sub argtypelistref{ [ANYTHING] };
sub process{
  my ($op, $P,$mote) = @_;
  my $result = $mote->mscalar;
  warn "FETCHMOTE: looked up [$result]";
  $result
}


package TipJar::Motion::AA;
use strict;
sub DEBUG(){0}
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

sub explode{ %{ $_[0] } }

sub Exists {
  my $self = shift;
  my $term = shift;
  exists $self->{$term}
}

use TipJar::Motion::configuration;
sub TIEHASH{
  bless \$_[1], __PACKAGE__
}
sub FETCH{
  my ($obj, $key) = @_;
  my $X = aa_get($$obj,$key);
  OldMote($X)
}
sub EXISTS{
  my ($obj, $key) = @_;
  aa_exists($$obj,$key)
}
sub STORE{
  my ($obj, $key, $val) = @_;
  DEBUG and warn "storing $val into $$obj / $key";
  if (ref $val){
      $val = $val->moteid;
	  $obj->sponsor($val);
  };
  aa_set($$obj,$key, $val)
}
sub CLEAR{ my $obj = shift;
   aa_clear($$obj)
}
sub DELETE{ my ($obj, $key) = @_;
   my $X = aa_get($$obj,$key);
   aa_delete($$obj, $key);
   OldMote($X)
}
my %PendingKeyLists;
sub oneortwo($$){
   if (wantarray){
       ($_[1], OldMote(aa_get($_[0],$_[1])))
   }else{
       $_[1]
   }
}
sub FIRSTKEY{ my $obj = shift;
    $PendingKeyLists{$$obj} = aa_listkeys($$obj);
	@{$PendingKeyLists{$$obj}} or return ();
	oneortwo $$obj, shift @{$PendingKeyLists{$$obj}}
}
sub NEXTKEY{ my $obj = shift;
	@{$PendingKeyLists{$$obj}} or return ();
	oneortwo $$obj, shift @{$PendingKeyLists{$$obj}}
}
    
sub DESTROY{ 0 and warn "destroying ${$_[0]}"}
our $AUTOLOAD;
sub AUTOLOAD{ Carp::confess "AUTOLOAD $AUTOLOAD" }
1;



