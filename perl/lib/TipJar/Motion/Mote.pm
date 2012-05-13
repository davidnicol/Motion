
package TipJar::Motion::mote;

=head1 virtual base class

everything, absolutely everything, in Motion
is a mote.

Motes are the fundamental instructions to
the motes virtual machine.

=cut

=head2 opcount
A mote type knows
how many operands it needs to take before
it yields a result.

by default, no operands are needed.

=cut

sub opcount {0}

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

=head1 new
C<new> is used to create a new mote of a type.
When that type takes arguments, they must be provided.
C<new> returns the result of running C<init> with the
provided operands.

=cut
use VMid;
use Encode::Base32::Crockford qw(:all);
sub NewLocalID{
    ## FIXME relate these numbers to persistence rows
    ## in the motes table
    my @X;
    @X = (1,2,3,4);
    foreach (@X){
         $_ = "00000" . base32_encode_with_checksum(
                int( rand 100000000 ) % 1048576
              );
         $_ = substr($_,-5,5);
    };
    join '',@X   
};
sub new {

    my $pack = shift;
    ref $pack and $pack = ref $pack;
    my $moteid = VMid() . NewLocalID();
    my $new = bless \$moteid, $pack;
    my $want = $new->opcount;
    my $have = @_;
    $want == $have or die "OP COUNT MISMATCH\n";
    $new->init(@_);
}

=head init
the base class init doesn't do anything, and returns
the mote identifier.
=cut
sub init { $_[0]->moteid }

=head1 moteid

motes have unique identifiers, which are hard to guess.

the C<moteid> method returns the id of a mote, or, for
secure motes, an id of a new revocable proxy mote.

The mote ID is a 25-symbol character string consisting
of five consecutive checksummed Crockford-encoded
twenty bit numbers.

The first part is the virtual machine ID,
as defined in L<TipJar::Motion::VMid>. This file should
be edited on installation. 

The other four ...

=cut

sub moteid { ${$_[0]} }

=head VMid

=head NewLocalID

=cut

1;
