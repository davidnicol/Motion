

use TipJar::Motion::codeloader;
my $nothing_code = codeload <<'ENDCODE';

package TipJar::Motion::null;
use parent TipJar::Motion::Mote;
use strict;
use TipJar::Motion::type 'NOTHING';
sub yield_returnable { undef }

ENDCODE

sub TipJar::Motion::null::freezecode { $nothing_code }

=pod

A class that provides an object that does
not appear in returnables

=head1 instance data 
none
=head1 yield_returnable
empty string

=cut

1;
