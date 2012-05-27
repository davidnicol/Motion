
package TipJar::Motion::singleton;
=pod
this package does NOT inherit from mote.
=cut
use strict;
use TipJar::Motion::configuration;
sub import{
  my $caller = caller;
  my $pack = shift;
  my $singletonname = shift;
  $singletonname or Carp::confess "USAGE: use ".__PACKAGE__." 'singletonname';";
  @_ and die "USAGE: use ".__PACKAGE__." 'singletonname';";
               
  # try to look up the prototype in persistent storage
  # if not found, mint one

  my $singleton = OldMote(bootstrap_get("$singletonname singleton"));
  $singleton or do {
       $singleton = new_type $caller;
	   bootstrap_set("$singletonname singleton", $$singleton)
  };
  
  no strict 'refs';
  *{$caller.'::type'} = sub { $singleton };
  
}

=pod

Singleton types carry all their meaning in their implementation package,
so all calls to the type are forwarded there.

=cut

=pod

the TYPE type is only used for coercion operations (become, accept)


As an OP, the TYPE keyword becomes a type constructor type, which
consumes a lexicon to produce a new user type.

types are motes. The core types all appear in the initial lexicon as
the provided names, this placement occurs in configuration.pm

The provided name for this package is 'TYPE'; 

=head2 $caller::type
a mote representing the type, used in operand lists

=head2

To access a type's package, access the type mote's scalar value

=cut


=head1 constructor

Constructing a new type requires passing in a LEXICON mote
from which the various options will be pulled.

This is how user types, including OPs, which are expected to be singletons
are defined.

Options include

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
sub process {
    Carp::confess " TYPE used as OP";
    my ($parser,$self, $lexarg) = @_;
    my $prototype = $lexarg->lookup('PROTOTYPE') || $parser->lexicon->lookup('MOTE');
    die 'FIXME'
};
1;
