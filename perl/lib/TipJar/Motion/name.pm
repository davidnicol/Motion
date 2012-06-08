package TipJar::Motion::name;
use strict;
=head1

this package is an OP that takes two arguments, the first
a STRING and the second is ANYTHING.

The ANYTHING gets stored in the parser's lexicon under the name.

=cut

use parent 'TipJar::Motion::Mote';
use TipJar::Motion::type 'NAME';
use TipJar::Motion::string;
use TipJar::Motion::anything;
use TipJar::Motion::null;

sub argtypelistref{ [STRING, ANYTHING] };

sub process { my ($op, $parser, $name, $thing) = @_;
  my $lex = $parser->lexicon;
  my $namestring = uc $name->string;
  warn "adding thing $thing to lex $lex as name $namestring";
  $lex->AddTerms($namestring, $thing);
  retnull
}

package TipJar::Motion::remember;
use TipJar::Motion::type 'REMEMBER';
use parent 'TipJar::Motion::name';
use TipJar::Motion::null;
sub process { my ($op, $parser, $name, $thing) = @_;
  $parser->lexicon->outer->AddTerms($name->string, $thing);
  retnull
}


1;

