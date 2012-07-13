
=head1  Keywords implemented in this file

=head2 base_failure

the base type for all failure objects. a base_failure has 
a string literal "unspecified failure" associated with it.

=head2 fail OP1

throw an exception. OP1 must be a failure object. The selected handler, if
found, will have its sequence performed with OP1's associated mote as operand.

=head2 ignore OP1

consume an operand mote and do nothing with it. This is defined here because
it can be used to do nothing with a placeholder in a handling sequence. It can also
be used to implement inline comments, or discard the results of operations performed
for their side effects.

=head2 handle OP1 OP2

Register the failure type provided as OP1 in the current workspace and associate the
sequence taking one operand, provided as OP2, with that failure type.


=head2 failure OP1 OP2

create a new failure type, descended from the failure type in OP1, associated with
the mote in OP2.

=cut
package TipJar::Motion::fail;
use Exporter import;
our @EXPORT = qw/Mthrow/;

sub Mthrow{ Carp::confess $_[0] };  # in the future we want a Motion 'FAILURE' object



package TipJar::Motion::base_failure;
use TipJar::Motion::type 'BASE_FAILURE';
sub UNIVERSAL::is_failure{0}
sub is_failure{1}
sub accept{  $_[1]->is_failure  } # $_[0] got us here

package TipJar::Motion::failOP;


package TipJar::Motion::ignoreOP;


package TipJar::Motion::handleOP;


package TipJar::Motion::failureOP;



1;