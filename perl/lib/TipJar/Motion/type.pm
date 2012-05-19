
package TipJar::Motion::type;
use parent TipJar::Motion::Mote;
use strict;
use TipJar::Motion::configuration;
sub import{
  my $caller = caller;
  my $pack = shift;
  my $typename = shift;
  $typename or die "import called with no argument";
  @_ and die "import called with extra arguments";

  # try to look up the prototype in persistent storage
  # if not found, mint one
  my $prototype =
        TipJar::Motion::configuration::persistent_lexicon()->{$typename.'TYPE'}
             ||= TipJar::Motion::Mote->new;

  { no strict 'refs';
  *{"$$prototype\::"} = *{"$caller\::"};
  *{$caller.'::type'} = sub { $typename };
  *{$caller.'::prototype'} = sub { $prototype };
  }
  
}
__PACKAGE__->import( 'TYPE' );

=pod
this package declares C<type> methods in callers when used 
with an argument.

types are motes. The core types all appear in the "wet" lexicon as
English words, ending in 'TYPE.' At this release the suffic "TYPE"
is hard-coded.

=cut

sub asSTRING {
   my $id = $$_[0];
   $id =~ s/[^A-Z0-9]//g;
   $id
}

=head1 constructor

Constructing a new type requires passing in a LEXICON mote
from which the various options will be pulled. Options include

=head2 PROTOTYPE

what type we singly inherit from, as in Javascript. Defaults to MOTETYPE

=head2 CONSTRUCTORARGS

a LIST of type motes, that will have 'TYPE' appended to them
before getting looked up in the current lexicon. When provided, this
is used to construct the C<wants> method.

=head2 PROCESSARGS

a LIST of type motes, that will have 'TYPE' appended to them
before getting looked up in the current lexicon. When provided, this
is used to construct the C<wants2> method.

=head2 PACKAGE

the name of a perl package representing the type, defaults to
'Motion::' concatenated with the mote identifier, which
will become an alias to the named package.

=head2 CODE
a string containing what would be an included type file except that it's getting
read in from the database instead of C<use>d

When absent, we will C<require> the PACKAGE.

=cut
sub wants { 'LEXICON' }
sub init {
    my ($self, $lexarg) = @_;
};
1;
