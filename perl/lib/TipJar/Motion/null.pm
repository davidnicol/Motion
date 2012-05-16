
package TipJar::Motion::null;
use parent TipJar::Motion::Mote;
use strict;
sub type { 'NULL' };
=pod

A class that provides an object that does
not appear in returnables

=head1 instance data 
none
=head1 yield_returnable
empty string

=cut

sub yield_returnable { undef }
1;
