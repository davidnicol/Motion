
package TipJar::Motion::lexicon;
use parent TipJar::Motion::Mote;
use strict;
=pod

A class that provides a lexicon object, supporting lookup of strings
to motes.

=head1 instance data 
=head2 lexicon
the lexicon method accesses a hash of names to coderefs which are executed
at lookup time to return values
=head2 outer
declare an inner scope by creating a new lexicon and setting its outer
member. The persistence abstraction, when allowed,
appears as the outermost scope.

=head2 AddLex(lex)
Makes all of an additional lexicon's data visible to a lexicon
by inserting it into the outer chain using this method

Later added lexicons are queried first.

Returns the invocant, allowing chaining.
=cut
sub AddLex{
   my $invocant = shift;
   my $argument = shift;
   eval { $argument->type eq 'LEXICON' } or Carp::confess("argument [$argument] is not a LEXICON mote");
   my $outer = $invocant->outer;
   my $new = TipJar::Motion::lexicon->new;
   $new->outer($outer);
   $new->lexicon($argument->lexicon);
   $invocant->outer($new);
   $invocant
}

use TipJar::Motion::type 'LEXICON' ;


{
  my %L; sub lexicon{
       my $s = shift; @_ and $L{$$s} = shift; $L{$$s}
  }
  my %P; sub outer{
       my $s = shift;
       if (defined $_[0]){
          my $newval = shift;
          !ref $newval and Carp::confess "non hash set as outer";
          $P{$$s} = $newval;
       };
       $P{$$s}
  }
}
sub perl_arrayrefname() { ref sub {} } # this is a constant, yo

=head1 AddTerms

add items to a lexicon with this. Values must be unblessed coderefs.  
Add a whole additional lexicon like so:

    $receiver_lexicon->AddTerms( %{ $sender_lexicon->lexicon } )

Returns the invocant, allowing chaining. See also L<AddLex>.
=cut

sub AddTerms{
  my $self = shift;
  while (my($k,$v) = splice @_,0,2){
     ref $v eq perl_arrayrefname or die "MISFORMATTED LEXICON VALUE";
     $self->lexicon->{"$k"} = $v
  };
  $self
};

sub explode{ %{ $_[0]->lexicon } }

sub init { $_[0]->lexicon({}); $_[0] }
sub Exists {
  my $self = shift;
  my $term = shift;
  exists $self->lexicon->{$term} and return 1;
  my $p = $self->outer;
  $p and $p->Exists($term)
}
sub lookup {
  my $self = shift;
  my $term = shift;
  my $l = $self->lexicon;
  if(exists $l->{$term}){
         return &{$l->{$term}}
  };
  my $p = $self->outer;
  $p and $p->lookup($term)
}
1;
