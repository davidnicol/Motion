
package TipJar::Motion::Mote;
use strict;
use Carp;
use TipJar::Motion::configuration;
*mscalar = accessor;  # data for SETMOTE and FETCHMOTE

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

=head2 argtypelistref

An operator mote type knows
how many arguments it requires, and their types. 

by default, no operands are needed.

=head2 process

Arguments: the op, or at least its package name, then
the current parser running the operation, then
arguments acceptable to the types listed in the argtypelistref.

Return: a result mote. use the null package and return C<retnull>
to not add anything to the output.

Base motes return themselves.

=head2 parser

Provide a new parser for interpreting subsequent input characters.
Takes the old parser as an argument.
Base motes return the argument.
	
=cut

sub wants {[]}
sub argtypelistref {[]}
sub process { $_[0] }
sub parser { $_[1] }
=head2 become 
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

=head1 sponsor

Motes persist as long as they are sponsored
within a motion VM. Motes that are not sponsored
are ephemeral. Only sponsored motes persist through
a GC event.

The C<sponsor> method is used by the sponsoring
mote to register sponsorship of another mote.
Default motes are not capable of sponsorship so
this method dies.

Types created by using the type package are remembered
in the bootstrap table, which serves as the roots for
marking at GC time.

Motes stored as AA data are automatically sponsored by
the container they are stored in.

Motes stored as instance data are automatically sponsored by
the mote they are associated with as well.



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
    my $new = bless TipJar::Motion::configuration::base_obj(), $pack;
	# warn "$pack type is ".$pack->type;
	TipJar::Motion::configuration::set_type($new, $pack->type);
    my $wants = $new->wants;
    @$wants == @_ or Carp::confess  <<MISMATCH;
WANT: [@$wants]
HAVE: [@_]
OP COUNT MISMATCH
MISMATCH
    my @args;
    for my $w (@$wants){
        my $arg = shift;
# 		warn "want $w, have $arg $$arg";
#       $arg = $arg	->become($w) ;
        OldMote($w)->accept($arg)
        # $arg->type eq $w
        or Carp::confess "ARG TYPE MISMATCH";
#		warn "accepted to get $arg";
        push @args, $arg;
    };

    $new->init(@args);
}

sub accept {
   Carp::confess "$_[0] IS NOT A TYPE"
};

sub become {
   my $me = shift;    # this is not a type
   my $goal = shift;  # this is a type
eval {
   $me->type eq $goal
} and return $me;
$@ and Carp::confess $@;
   $goal eq TipJar::Motion::string::type() and return $me->asSTRING;

   # maybe the goal can take me as I am
   $me
};

=head1 type
the type method reveals the name Motion type, for operand validation
and parse-time coercion. Types are moteids of motes of type TYPE, and their
names appear in the lexicon of the default parser. The
TipJar::Motion::type package exports the C<type> method 
into the current package and registers the name with the
bootstrap lexicon.
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

sub moteid { my $M = eval {${$_[0]}};
   $M and return $M;
   Carp::confess($@)

 }

=head1 yield_returnable

the yield_returnable method provides a character string
which the engine writes to its output.

Base motes yield their mote IDs.
=cut
sub yield_returnable { ${$_[0]} }

use TipJar::Motion::type 'MOTE';

sub sponsor { 
   my $self = shift;
   my $beneficiary = shift;
   RegisterSponsorship($$self =>  (ref $beneficiary ? $$beneficiary : $beneficiary));
   $beneficiary
}
sub unsponsor { 
   my $self = shift;
   my $beneficiary = shift;
     RemoveSponsorship($$self =>  (ref $beneficiary ? $$beneficiary : $beneficiary));
   $beneficiary
}
package TipJar::Motion::Mote_constructor;
use TipJar::Motion::type 'MOTECONS';
our @ISA = qw/TipJar::Motion::Mote/;
sub process { TipJar::Motion::Mote->new }

1;
