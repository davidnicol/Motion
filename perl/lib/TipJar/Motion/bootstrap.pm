
package TipJar::Motion::bootstrap;
use strict;
=head1 local configuration

use configuration, which sets up persistence abstractions,
then use core packages.

=cut

use TipJar::Motion::configuration;
use TipJar::Motion::type ();
use TipJar::Motion::Mote;
use TipJar::Motion::AA;
use TipJar::Motion::lexicon;
use TipJar::Motion::null;
use TipJar::Motion::string;
use TipJar::Motion::anything;
use TipJar::Motion::name;
use TipJar::Motion::remember;
use TipJar::Motion::workspace;
use TipJar::Motion::sequence;
1;
