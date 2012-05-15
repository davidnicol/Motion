
package TipJar::Motion::Mote;
use strict;

=head1 virtual base class

everything, absolutely everything, in Motion
is a mote.

Motes are the fundamental instructions to
the motes virtual machine.

=cut

=head2 wants
A mote type knows
how many operands it needs, and their types. 

by default, no operands are needed.

=cut

sub wants {[]}

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

=cut

sub sponsor { die "MOTE NOT CAPABLE OF SPONSORSHIP\n" }


use TipJar::Motion::VMid;
use TipJar::Motion::persistence;
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
       TipJar::Motion::persistence::fresh_rowid(),
       $r2
    );
    foreach (@X){
         $_ = "00000" . base32_encode_with_checksum( $_  % 1048576 );
         $_ = substr($_,-5,5);
    };
    join '',@X,VMid()
}}

=head1 type
the type method reveals the Motion type, for operand validation
and parse-time coercion.

=cut
sub type { 'BASE' }

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
    my $moteid = NewMoteID();
    my $new = bless \$moteid, $pack;
    my $wants = $new->wants;
    @$wants == @_ or die "OP COUNT MISMATCH\n";
    my $argtypes = [ map { $_->type } @_ ];
    "@$wants" eq "@$argtypes" or die "OP MISMATCH\n";

    $new->init(@_);
}

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


1;
