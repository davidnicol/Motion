
package TipJar::Motion::singleton;
use parent TipJar::Motion::Mote;
sub become { $_[0] }
sub process {$_[0]}

package TipJar::Motion::null;
use strict;
use vars qw/$AUTOLOAD @ISA/;
@ISA = qw/TipJar::Motion::singleton/;
use TipJar::Motion::type 'NOTHING';
sub yield_returnable { () }
sub DESTROY{}
sub AUTOLOAD { Carp::confess "autoload: $AUTOLOAD" }

package TipJar::Motion::true;
our @ISA = qw/TipJar::Motion::singleton/;
use strict;
use TipJar::Motion::type 'TRUE';
sub yield_returnable { "TRUE" }

package TipJar::Motion::false;
our @ISA = qw/TipJar::Motion::singleton/;
use strict;
use TipJar::Motion::type 'FALSE';
sub yield_returnable { "FALSE" }

package TipJar::Motion::boolean;
our @ISA = qw/TipJar::Motion::singleton/;
use strict;
use TipJar::Motion::type 'BOOLEAN';
sub yield_returnable { () }
sub become  {die "NOT A VALID RESULT"}
### type() returns a moteId string
our $T = TipJar::Motion::true::type();
our $F = TipJar::Motion::false::type();
sub accept  {  # declare a BOOLEAN argument to require either a TRUE or a FALSE
    my ($self, $other) = @_;
    $$other eq $T or $$other eq $F
}
# use BOOLEAN as an op to coerce the following mote into TRUE or FALSE
use TipJar::Motion::anything;
sub argtypelistref { [ANYTHING] }
sub process {
    my ($self, $parser, $arg) = @_;
	
}
	

1;
