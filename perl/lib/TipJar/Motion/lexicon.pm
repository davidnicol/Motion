
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
   my $outer = $invocant->outer;
   my $new = TipJar::Motion::lexicon->new;
   $new->outer($outer);
   $new->lexicon($argument->lexicon);
   $invocant->outer($new);
   $invocant
}

sub type { 'LEXICON' };
{
  my %L; sub lexicon{ my $s = shift; @_ and $L{$$s} = shift; $L{$$s} }
  my %P; sub outer{ my $s = shift; @_ and $P{$$s} = shift; $P{$$s} }
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

sub init { $_[0]->lexicon({}); $_[0] }

sub lookup {
  my $self = shift;
  my $l = $self->lexicon;
  my $term = shift;
  exists $l->{$term} and return &{$l->{$term}};
  my $p = $self->outer;
  $p and $p->lookup($term)
}
1;
