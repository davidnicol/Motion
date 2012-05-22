
package TipJar::Motion::type;
use parent TipJar::Motion::Mote;
use strict;
use TipJar::Motion::configuration;
sub import{
  my $caller = caller;
  my $pack = shift;
  my $typename = shift;
  $typename or die "import called with no argument";
               
  # try to look up the prototype in persistent storage
  # if not found, mint one
  my $type = __PACKAGE__->new;
  TipJar::Motion::configuration::initial_AA()->{$typename} = $caller;
  { no strict 'refs';
### no, don't do this; it uses too much perl
### but it lets us treat MOTE type names as packages,
### most convenient.
  ### *{"$typename\::"} = *{"$caller\::"};

  *{$caller.'::type'} = sub { $type };
  *{$caller.'::prototype'} = sub { $caller };
  }
  
}
__PACKAGE__->import( 'TYPE' );

=pod

the TYPE type is only used for coercion operations (become, accept)
As an OP, the TYPE keyword becomes a type constructor type, which
consumes a lexicon to produce a new type.

this package declares C<type> and C<prototype> methods in callers when used 
with an argument.

types are motes. The core types all appear in the initial lexicon as
the provided names.

The provided name for this package is 'TYPE';

=head2 $caller::type
a mote representing the type, used in operand lists

=head2 $caller::prototype
an example of the type, used in inheritance method resolution.

=cut


=head1 constructor

Constructing a new type requires passing in a LEXICON mote
from which the various options will be pulled. Options include

=head2 PROTOTYPE

what type we singly inherit from, as in Javascript. Defaults to MOTE

=head2 CONSTRUCTORARGS

a LIST of type motes, that will have 'TYPE' appended to them
before getting looked up in the current lexicon. When provided, this
is used to construct the C<wants> method by storing it in the 
C<constructor_operand_types> instance variable slot.

=head2 PROCESSARGS

a LIST of type motes, that will have 'TYPE' appended to them
before getting looked up in the current lexicon. When provided, this
is used to construct the C<wants2> method by storing it in
the C<process_operand_types> instance variable slot.

=head2 PACKAGE

the name of a perl package representing the type, defaults to
'Motion::' concatenated with the mote identifier with non-alpha checksums switched to 'U' 

=head2 CODE
a string containing what would be an included type file except that it's getting
read in from the database instead of C<use>d

When absent, we C<require> the PACKAGE.

=cut
# sub wants2 { ['LEXICON'] }   # as an OP, it takes a lexicon.
# as a constructor OP, TYPE motes store what they require here.
BEGIN { *constructor_operand_types = accessor }
INIT {__PACKAGE__->type->constructor_operand_types
or __PACKAGE__->type->constructor_operand_types([TipJar::Motion::lexicon->type] ) };
sub wants2 { shift->constructor_operand_types || [] }
BEGIN { *process_operand_types = accessor }
sub wants { shift->process_operand_types || [] }
sub process {
    Carp::confess "base TYPE used as OP";
    my ($parser,$self, $lexarg) = @_;
    my $prototype = $lexarg->lookup('PROTOTYPE') || $parser->lexicon->lookup('MOTE');
    die 'FIXME'
};
1;
