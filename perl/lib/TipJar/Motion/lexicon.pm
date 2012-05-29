
package TipJar::Motion::lexicon;
use strict;
use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'LEX';
use TipJar::Motion::AA;  ### associative array mote

=pod

A class that provides a lexicon object, supporting lookup of strings
to motes.

=head1 instance data 
=head2 aa
the aa method accesses a hash of names, blessed into persistent storage

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
   $argument->type eq __PACKAGE__->type
     or Carp::confess("argument [$argument] is not a LEXICON mote");
   my $new = TipJar::Motion::lexicon->new;
   $new->outer($invocant->outer);
   $new->aa($argument->aa);
   $invocant->outer($new);
   $invocant
}

BEGIN{
  *_outer = TipJar::Motion::configuration::accessor('lexicon outer');
  *comment = TipJar::Motion::configuration::accessor('lexicon comment');
  *aa = TipJar::Motion::configuration::accessor('lexicon aa');
}

sub outer{
   my $L= shift;
   my $O = shift;
   $O or return $L->_outer;
   warn "setting ".$O->comment()." to be outer from ".$L->comment()."\n";
   # guard against loops
   my %seen;
   my $x = $L;
   while (defined $x){
      warn "outertrace: ".$x->comment()."\n";
      $seen{"$x"}++ and Carp::confess "OUTER LEXICON LOOP REJECTED";
      $x = $x->_outer
   };
   $L->_outer($O)
};


sub perl_arrayrefname() { ref sub {} } # this is a constant, yo

=head1 AddTerms

add items to a lexicon with this. Values must be unblessed coderefs.  
Add a whole additional lexicon like so:

    $receiver_lexicon->AddTerms(  $sender_lexicon->explode  )

Returns the invocant, allowing chaining. See also L<AddLex>.
=cut

sub AddTerms{
  my $self = shift;
  while (my($k,$v) = splice @_,0,2){
     ref $k and $k = $k->asSTRING->string;
     my $alreadythere = $self->aa->{"$k"};
     defined $alreadythere and warn "overwriting $k : [$alreadythere]";
     $self->aa->{$k} = $v
  };
  $self
};

sub explode{ %{ $_[0]->aa } }

my $commentcounter='a';
sub init { $_[0]->aa( TipJar::Motion::AA->new );
   $_[0]->comment("$$ ".$commentcounter++);
   Carp::cluck("created new lexicon ".$_[0]->comment);
   $_[0]
}
sub Exists {
  my $self = shift;
  my $term = shift;
  exists $self->aa->{$term} and return 1;
  my $p = $self->outer;
  $p and $p->Exists($term)
}
sub innerlookup {
  my $self = shift;
  my $term = shift;
  my $seen = shift;
  my $l = $self->aa;
  if(exists $l->{$term}){
         warn "found [$term] in ".$self->comment().'.';
         return $l->{$term}
  };
  # warn "failed to find [$term] among [@{[sort keys %$l]}]";
  my $p = $self->outer;
  $seen->{"$self"}++ and Carp::confess "LEXICON LOOP";
  $p and $p->innerlookup($term,$seen)
}
sub lookup {
  if(1){  # lookup debugging
    my $L = @_[0];
    warn "looking for [$_[1]]";
    while($L){
        my $C = $L->comment;
        my @keys = sort keys %{$L->aa};
        warn "$C: [@keys]\n";
        $L = $L->outer;
    }
  };
  innerlookup(@_,{})
}

# processing this mote yields a fresh lexicon (or lexicon-like type)
# making this a constructor mote
# design question: should we move this into a
# general purpose ::::constructormote alternate base class?
sub process{ shift->new }
1;



