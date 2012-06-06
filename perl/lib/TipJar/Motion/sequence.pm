

=pod

this file contains constructors for macros and sequences.

Syntactically, both macros and sequences are defined between matching
tokens, as HERE strings, with the PLACEHOLDER mote
to specify the argument list they require. They are both compiled as far as
is possible without the placeholders.

Semantically, they are different:

Macros expand immediately and their bodies are prepended to the parser's mote stream.

Sequences are compound ops, which take zero or more args and give one mote, when activated
by the "PERFORM" operator. Otherwise, they evaluate to their moteids.

Macros save names to the immediate lexicon.

Sequences save to their own local scope, and remember to the scope where they were
defined.

Internally, the results of these constructors are user types, with package
names based on their moteIDs, and package code strings that are evalled
at thaw time.

=cut

my @Scopes; # strictly a compile-time construct, need not persist


package TipJar::Motion::placeholder;
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'PLACEHOLDER';

package TipJar::Motion::endmacro;
use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'ENDMACRO';


package TipJar::Motion::macro;
use parent TipJar::Motion::hereparser;
use TipJar::Motion::type 'MAC CONS';

package TipJar::Motion::sequence;
use parent TipJar::Motion::hereparser;
use TipJar::Motion::type 'SEQ CONS';


1;
