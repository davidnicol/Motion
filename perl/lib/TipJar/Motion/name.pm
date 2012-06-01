package TipJar::Motion::name;
=head1

this package is an OP that takes two arguments, the first
a STRING and the second is ANYTHING.

The ANYTHING gets stored in the parser's lexicon under the name.

=cut

use parent TipJar::Motion::Mote;
use TipJar::Motion::type 'NAME';
use TipJar::Motion::string;
use TipJar::Motion::anything;

sub argtypelistref{ [STRING, ANYTHING] };

sub process { my ($op, $parser, $name, $thing) = @_;
  $parser->lexicon->AddTerms($name->string, $thing);
  $name
}

package TipJar::Motion::remember;
use TipJar::Motion::type 'REMEMBER';
use parent TipJar::Motion::name;
sub process { my ($op, $parser, $name, $thing) = @_;
  $parser->lexicon->outer->AddTerms($name->string, $thing);
  $name
}


1;

