
package TipJar::Motion::VMid;
use TipJar::Motion::configuration;

=head1 virtual machine identifier portion of a mote identifier

Towards Motion becoming an interoperability tool, a way to route
motes to the organizations that will be able to process them
is needed. This provided in the form of the virtual machine
identifier.


Mote identifiers are composed of three concatenated
Crockford-encoded twenty bit numbers with checksums,
making them fifteen characters long.

The first is the virtual machine identifier, the second and third are used
to uniquely identify motes within a VM.

machine number 867130 is reserved for testing; contact the author of
this module for a machine number of your own, or use your PEN
number if you have one. http://www.oid-info.com/get/1.3.6.1.4.1.37414
is mine. Left-pad with zeroes when less than 32768.

Non-PEN enterprise VMids will either start at ZZZZ and count down, or
get assigned randomly or whimsically.

We'll use PEN numbers mod 2**20 and increment by one until finding
a free slot, and rethink mote-IDs when there are more than a half million
interoperating Motion nodes.

=cut

sub import {
   my $caller = caller();
   *{$caller.'::VMid'} = \&TipJar::Motion::configuration::VMid
}

1;
