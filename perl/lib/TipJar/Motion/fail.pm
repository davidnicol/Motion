
package TipJar::Motion::fail;
use Exporter import;
our @EXPORT = qw/Mthrow/;

sub Mthrow{ Carp::confess $_[0] };  # in the future we want a Motion 'FAILURE' object