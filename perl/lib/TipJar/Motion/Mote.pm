
package TipJar::Motion::Mote;
use strict;
use Carp;
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
    my $mote = TipJar::Motion::configuration::base_obj();
    my $new = bless $mote, $pack;
    my $wants = $new->wants;
    @$wants == @_ or Carp::confess "OP COUNT MISMATCH\n";
    my @args;
    for my $w (@$wants){
        my $arg = shift ->become($w) ;
        $arg = $w->accept($arg) or die "ARG TYPE MISMATCH";
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
   $me->type->moteid eq $goal->moteid
} and return $me;
$@ and Carp::confess $@;
   $goal->moteid eq STRING->moteid and return $me->asSTRING;

   # maybe the goal can take me as I am
   $me
};

=head2 freezecode
provide a block of implementation-language code that can
be evaluated (for primitives and adapters, that's string-eval;
higher-level application code will still be string-eval, but
making reference to a new engine, and a facility for turning
a heredoc into a STREAM)

Base objects don't need this. User-defined types do.
=cut
sub freezecode { '' } 


sub alpha_row_id { substr($$_[0], 10,4) }
sub row_id { base32_decode_with_checksum( substr(${$_[0]}, 10,5)) }
sub VMid { substr(${$_[0]}, -5,5) }

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

use TipJar::Motion::Sponsortable;
sub sponsor { 
   my $self = shift;
   my $beneficiary = shift;
   Sponsortable->add($self =>  $beneficiary);
}

1;
