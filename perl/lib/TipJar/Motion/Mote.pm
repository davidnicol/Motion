
package TipJar::Motion::Mote;
use strict;
use TipJar::Motion::configuration;
sub type {'BASE'}
=head1 base class

everything, absolutely everything, in Motion
is a mote.

Motes are the fundamental instructions to
the motes virtual machine, and also the data.

=cut

=head2 wants
A mote type knows
how many arguments its constructor needs, and their types. 

by default, no operands are needed.

=head2 wants2

An operator mote type knows
how many arguments it requires, and their types. 

by default, no operands are needed.

=head2 process

Accept the arguments described in the wants2 list and
return a result mote.

Base motes return themselves.

=head2 parser

Provide a new parser for interpreting subsequent input characters.
Takes the old parser as an argument.
Base motes return the argument.
	
=cut

sub wants {[]}
sub wants2 {[]}
sub process { $_[0] }
sub parser { $_[1] }
sub as {
   my $m = shift;
   my $m_type = $m->type;
   my $goal_type = shift;
   $m_type eq $goal_type and return $m;
   $goal_type or die "FALSE TYPE\n";
   my $test = eval { 
          my $coercionmethod = 'as'.$goal_type;
          $m->$coercionmethod 
   };
   $test or die "COERCION FROM $m_type TO $goal_type NOT DEFINED\n";
   $test
};
=head2 as
Coerce the invocant to the type named as the argument.

Base motes have one coercion defined, to STRING type,
and that coercion yields the moteID.
=cut
sub asSTRING {
    my $m = shift;
    my $string = TipJar::Motion::string->new;
    $string->string( $m->moteid );
    $string
}
=head2 mutable
a mote type knows if it is mutable or not.
Mutable motes may not be resolved when compiling new
motes from sequences.

By default, motes are immutable.

one time a mote is mutable is when it holds
a changing value, that is, when it provides access
to an L-value.

Another time a mote is mutable is when it represents
a process that goes through different states.

=cut

sub mutable {0}

=head1 sponsor

Motes persist as long as they are sponsored
within a motion VM. Motes that are not sponsored
are ephemeral. Only sponsored motes persist.
The C<sponsor> method is used by the sponsoring
mote to register sponsorship of another mote.
Default motes are not capable of sponsorship so
this method dies.

=head1 new
C<new> is used to create a new mote of a type.
When that type takes arguments, they must be provided.
C<new> returns the result of running C<init> with the
provided operands.
the C<new> method allocates new mote id and validates operand types
according to the list returned from the C<wants> method
=cut

sub new {

    my $pack = shift;
    ref $pack and $pack = ref $pack;
    my $mote = TipJar::Motion::configuration::base_obj(NewMoteID());
    my $new = bless $mote, $pack;
    my $wants = $new->wants;
    @$wants == @_ or die "OP COUNT MISMATCH\n";
    my $argtypes = [ map { $_->type } @_ ];
    "@$wants" eq "@$argtypes" or die "OP MISMATCH\n";

    $new->init(@_);
}


INIT{
require TipJar::Motion::VMid;
}
use Encode::Base32::Crockford qw(:all);

=head2 NewMoteID
Mote IDs are twentyfive character strings, representing
one hundred bits, formed by concatenating five
checksummed Crockford-encoded twenty-bit values.

The first is a time value that increments every 64 seconds, taking
just over two years to recycle.

The second and fourth are random.

The third is provided by the persistence layer and may be used
for optimizing database lookups.

The fifth is an organizational identifier to be used for routing
messages between Motion instances. It defaults to "TEST=".

=cut
{
my @Randoms;
sub NewMoteID{
    # this is more complex than it has to be
    # please waste as little additional time on it as possible.
    if (@Randoms < 2 + rand 10){
         srand(rand(3000000000) + time + $$);
         push @Randoms, rand(90000000) while ( rand(40) > 3);
         push @Randoms, rand(200000000);
         push @Randoms, rand(80000000) while ( rand(50) > 2);
         push @Randoms, rand(100000000);
         push @Randoms, rand(70000000) while ( rand(60) > 1);
         for my $i ( 0 .. $#Randoms){
             my $j = int rand @Randoms;
             @Randoms[$i,$j] = @Randoms[$j,$i]
         }
    };
    my ($r1,$r2) = splice @Randoms, 0, 2;
    my @X = (
       time() >> 6,
       $r1,
       TipJar::Motion::configuration::fresh_rowid(),
       $r2
    );
    foreach (@X){
         $_ = "00000" . base32_encode_with_checksum( $_  % 1048576 );
         $_ = substr($_,-5,5);
    };
    join '',@X,VMid()
}}

sub alpha_row_id { substr($$_[0], 10,4) }
sub row_id { base32_decode_with_checksum( substr($$_[0], 10,5)) }
sub VMid { substr($$_[0], -5,4) }

=head1 type
the type method reveals the name Motion type, for operand validation
and parse-time coercion. Types are motes of type called TYPE, and their
names appear in the lexicon of the default parser. The
TipJar::Motion::type package exports the C<type> method 
into the current package and registers the name with the
current parser's types lexicon.
=cut


=head init
the base class init doesn't do anything, and returns the mote itself.
=cut
sub init { $_[0] }

=head1 moteid

motes have unique identifiers, which are hard to guess.

the C<moteid> method returns the id of a mote, or, for
secure motes, an id of a new revocable proxy mote.

The mote ID is a 25-symbol character string consisting
of five consecutive checksummed Crockford-encoded
twenty bit numbers.

Base motes reveal their own moteids.
=cut

sub moteid { ${$_[0]} }

=head1 yield_returnable

the yield_returnable method provides a character string
which the engine writes to its output.

Base motes yield the results of their asSTRING functions.
=cut
sub yield_returnable { $_[0]->as('STRING')->string }

use TipJar::Motion::Sponsortable;
sub sponsor { 
   my $self = shift;
   my $beneficiary = shift;
   Sponsortable->add($self =>  $beneficiary);
}

1;
